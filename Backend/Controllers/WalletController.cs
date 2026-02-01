using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.DTOs;
using PcmBackend.Hubs;
using PcmBackend.Models;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class WalletController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public WalletController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        /// <summary>
        /// Lấy số dư ví hiện tại
        /// </summary>
        [HttpGet("balance")]
        public async Task<ActionResult<ApiResponse<decimal>>> GetBalance()
        {
            var memberId = GetCurrentMemberId();
            var member = await _context.Members.FindAsync(memberId);
            
            if (member == null)
                return NotFound(ApiResponse<decimal>.Fail("Không tìm thấy thành viên"));

            return Ok(ApiResponse<decimal>.Ok(member.WalletBalance));
        }

        /// <summary>
        /// Lấy lịch sử giao dịch
        /// </summary>
        [HttpGet("transactions")]
        public async Task<ActionResult<ApiResponse<PaginatedResult<WalletTransactionDto>>>> GetTransactions(
            [FromQuery] TransactionType? type = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var memberId = GetCurrentMemberId();
            var query = _context.WalletTransactions.Where(wt => wt.MemberId == memberId);

            if (type.HasValue)
            {
                query = query.Where(wt => wt.Type == type.Value);
            }

            var totalCount = await query.CountAsync();
            var items = await query
                .OrderByDescending(wt => wt.CreatedDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(wt => new WalletTransactionDto
                {
                    Id = wt.Id,
                    Amount = wt.Amount,
                    Type = wt.Type,
                    Status = wt.Status,
                    Description = wt.Description,
                    RelatedId = wt.RelatedId,
                    CreatedDate = wt.CreatedDate
                })
                .ToListAsync();

            var result = new PaginatedResult<WalletTransactionDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };

            return Ok(ApiResponse<PaginatedResult<WalletTransactionDto>>.Ok(result));
        }

        /// <summary>
        /// Gửi yêu cầu nạp tiền
        /// </summary>
        [HttpPost("deposit")]
        public async Task<ActionResult<ApiResponse<WalletTransactionDto>>> Deposit([FromBody] DepositRequestDto model)
        {
            var memberId = GetCurrentMemberId();
            var member = await _context.Members.FindAsync(memberId);
            
            if (member == null)
                return NotFound(ApiResponse<WalletTransactionDto>.Fail("Không tìm thấy thành viên"));

            var transaction = new WalletTransaction
            {
                MemberId = memberId,
                Amount = model.Amount,
                Type = TransactionType.Deposit,
                Status = TransactionStatus.Pending,
                Description = model.Description ?? $"Nạp tiền {model.Amount:N0} VND",
                ProofImageUrl = model.ProofImageUrl,
                CreatedDate = DateTime.UtcNow
            };

            _context.WalletTransactions.Add(transaction);
            await _context.SaveChangesAsync();

            // Create notification for Admin/Treasurer
            var admins = await _context.Members
                .Include(m => m.User)
                .Where(m => m.User != null)
                .ToListAsync();

            // TODO: Filter only admins when roles are properly linked

            var result = new WalletTransactionDto
            {
                Id = transaction.Id,
                Amount = transaction.Amount,
                Type = transaction.Type,
                Status = transaction.Status,
                Description = transaction.Description,
                CreatedDate = transaction.CreatedDate
            };

            return Ok(ApiResponse<WalletTransactionDto>.Ok(result, "Yêu cầu nạp tiền đã được gửi, vui lòng chờ duyệt"));
        }

        /// <summary>
        /// Admin duyệt yêu cầu nạp tiền
        /// </summary>
        [HttpPut("~/api/admin/wallet/approve/{transactionId}")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<ActionResult<ApiResponse<WalletTransactionDto>>> ApproveDeposit(int transactionId)
        {
            var transaction = await _context.WalletTransactions
                .Include(wt => wt.Member)
                .FirstOrDefaultAsync(wt => wt.Id == transactionId);

            if (transaction == null)
                return NotFound(ApiResponse<WalletTransactionDto>.Fail("Không tìm thấy giao dịch"));

            if (transaction.Status != TransactionStatus.Pending)
                return BadRequest(ApiResponse<WalletTransactionDto>.Fail("Giao dịch đã được xử lý"));

            if (transaction.Type != TransactionType.Deposit)
                return BadRequest(ApiResponse<WalletTransactionDto>.Fail("Chỉ có thể duyệt giao dịch nạp tiền"));

            // Use transaction to ensure data integrity
            using var dbTransaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Update transaction status
                transaction.Status = TransactionStatus.Completed;

                // Add money to member's wallet
                var member = transaction.Member!;
                member.WalletBalance += transaction.Amount;

                await _context.SaveChangesAsync();

                // Create notification for member
                var notification = new Notification
                {
                    ReceiverId = member.Id,
                    Message = $"Nạp tiền {transaction.Amount:N0} VND thành công! Số dư hiện tại: {member.WalletBalance:N0} VND",
                    Type = NotificationType.Success,
                    LinkUrl = "/wallet",
                    CreatedDate = DateTime.UtcNow
                };
                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();

                await dbTransaction.CommitAsync();

                // Send real-time notification via SignalR
                await _hubContext.Clients.User(member.UserId).SendAsync("ReceiveNotification", 
                    notification.Message, 
                    notification.Type.ToString());

                var result = new WalletTransactionDto
                {
                    Id = transaction.Id,
                    Amount = transaction.Amount,
                    Type = transaction.Type,
                    Status = transaction.Status,
                    Description = transaction.Description,
                    CreatedDate = transaction.CreatedDate
                };

                return Ok(ApiResponse<WalletTransactionDto>.Ok(result, "Đã duyệt nạp tiền thành công"));
            }
            catch (Exception ex)
            {
                await dbTransaction.RollbackAsync();
                return StatusCode(500, ApiResponse<WalletTransactionDto>.Fail($"Lỗi: {ex.Message}"));
            }
        }

        /// <summary>
        /// Admin từ chối yêu cầu nạp tiền
        /// </summary>
        [HttpPut("~/api/admin/wallet/reject/{transactionId}")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<ActionResult<ApiResponse<WalletTransactionDto>>> RejectDeposit(int transactionId)
        {
            var transaction = await _context.WalletTransactions
                .Include(wt => wt.Member)
                .FirstOrDefaultAsync(wt => wt.Id == transactionId);

            if (transaction == null)
                return NotFound(ApiResponse<WalletTransactionDto>.Fail("Không tìm thấy giao dịch"));

            if (transaction.Status != TransactionStatus.Pending)
                return BadRequest(ApiResponse<WalletTransactionDto>.Fail("Giao dịch đã được xử lý"));

            transaction.Status = TransactionStatus.Rejected;
            await _context.SaveChangesAsync();

            // Create notification for member
            var notification = new Notification
            {
                ReceiverId = transaction.MemberId,
                Message = $"Yêu cầu nạp tiền {transaction.Amount:N0} VND đã bị từ chối",
                Type = NotificationType.Warning,
                LinkUrl = "/wallet",
                CreatedDate = DateTime.UtcNow
            };
            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Send real-time notification
            var member = transaction.Member!;
            await _hubContext.Clients.User(member.UserId).SendAsync("ReceiveNotification",
                notification.Message,
                notification.Type.ToString());

            var result = new WalletTransactionDto
            {
                Id = transaction.Id,
                Amount = transaction.Amount,
                Type = transaction.Type,
                Status = transaction.Status,
                Description = transaction.Description,
                CreatedDate = transaction.CreatedDate
            };

            return Ok(ApiResponse<WalletTransactionDto>.Ok(result, "Đã từ chối yêu cầu nạp tiền"));
        }

        /// <summary>
        /// Admin lấy danh sách giao dịch chờ duyệt
        /// </summary>
        [HttpGet("~/api/admin/wallet/pending")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<ActionResult<ApiResponse<List<WalletTransactionDto>>>> GetPendingTransactions()
        {
            var transactions = await _context.WalletTransactions
                .Include(wt => wt.Member)
                .Where(wt => wt.Status == TransactionStatus.Pending && wt.Type == TransactionType.Deposit)
                .OrderBy(wt => wt.CreatedDate)
                .Select(wt => new WalletTransactionDto
                {
                    Id = wt.Id,
                    Amount = wt.Amount,
                    Type = wt.Type,
                    Status = wt.Status,
                    Description = $"{wt.Member!.FullName}: {wt.Description}",
                    CreatedDate = wt.CreatedDate
                })
                .ToListAsync();

            return Ok(ApiResponse<List<WalletTransactionDto>>.Ok(transactions));
        }

        private int GetCurrentMemberId()
        {
            var memberIdClaim = User.FindFirst("MemberId")?.Value;
            return int.TryParse(memberIdClaim, out var id) ? id : 0;
        }
    }
}
