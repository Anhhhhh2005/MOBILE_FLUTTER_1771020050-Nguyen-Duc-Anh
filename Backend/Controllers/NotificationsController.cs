using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.DTOs;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public NotificationsController(ApplicationDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Lấy danh sách thông báo của tôi
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ApiResponse<List<NotificationDto>>>> GetNotifications()
        {
            var memberId = GetCurrentMemberId();

            var notifications = await _context.Notifications
                .Where(n => n.ReceiverId == memberId)
                .OrderByDescending(n => n.CreatedDate)
                .Take(50)
                .Select(n => new NotificationDto
                {
                    Id = n.Id,
                    Message = n.Message,
                    Type = n.Type,
                    LinkUrl = n.LinkUrl,
                    IsRead = n.IsRead,
                    CreatedDate = n.CreatedDate
                })
                .ToListAsync();

            return Ok(ApiResponse<List<NotificationDto>>.Ok(notifications));
        }

        /// <summary>
        /// Đếm số thông báo chưa đọc
        /// </summary>
        [HttpGet("unread-count")]
        public async Task<ActionResult<ApiResponse<int>>> GetUnreadCount()
        {
            var memberId = GetCurrentMemberId();

            var count = await _context.Notifications
                .Where(n => n.ReceiverId == memberId && !n.IsRead)
                .CountAsync();

            return Ok(ApiResponse<int>.Ok(count));
        }

        /// <summary>
        /// Đánh dấu thông báo đã đọc
        /// </summary>
        [HttpPut("{id}/read")]
        public async Task<ActionResult<ApiResponse<bool>>> MarkAsRead(int id)
        {
            var memberId = GetCurrentMemberId();

            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == id && n.ReceiverId == memberId);

            if (notification == null)
                return NotFound(ApiResponse<bool>.Fail("Không tìm thấy thông báo"));

            notification.IsRead = true;
            await _context.SaveChangesAsync();

            return Ok(ApiResponse<bool>.Ok(true, "Đã đánh dấu đã đọc"));
        }

        /// <summary>
        /// Đánh dấu tất cả thông báo đã đọc
        /// </summary>
        [HttpPut("read-all")]
        public async Task<ActionResult<ApiResponse<int>>> MarkAllAsRead()
        {
            var memberId = GetCurrentMemberId();

            var unreadNotifications = await _context.Notifications
                .Where(n => n.ReceiverId == memberId && !n.IsRead)
                .ToListAsync();

            foreach (var notification in unreadNotifications)
            {
                notification.IsRead = true;
            }

            await _context.SaveChangesAsync();

            return Ok(ApiResponse<int>.Ok(unreadNotifications.Count, $"Đã đánh dấu {unreadNotifications.Count} thông báo đã đọc"));
        }

        private int GetCurrentMemberId()
        {
            var memberIdClaim = User.FindFirst("MemberId")?.Value;
            return int.TryParse(memberIdClaim, out var id) ? id : 0;
        }
    }
}
