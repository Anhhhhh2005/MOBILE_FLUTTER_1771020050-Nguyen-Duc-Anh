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
    public class BookingsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public BookingsController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        /// <summary>
        /// Lấy lịch đặt sân theo khoảng thời gian
        /// </summary>
        [HttpGet("calendar")]
        public async Task<ActionResult<ApiResponse<List<CalendarSlotDto>>>> GetCalendar(
            [FromQuery] DateTime from,
            [FromQuery] DateTime to)
        {
            var currentMemberId = GetCurrentMemberId();

            var bookings = await _context.Bookings
                .Include(b => b.Court)
                .Include(b => b.Member)
                .Where(b => b.StartTime >= from && b.EndTime <= to)
                .Where(b => b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Holding)
                .ToListAsync();

            var courts = await _context.Courts.Where(c => c.IsActive).ToListAsync();

            var slots = new List<CalendarSlotDto>();

            foreach (var booking in bookings)
            {
                slots.Add(new CalendarSlotDto
                {
                    BookingId = booking.Id,
                    CourtId = booking.CourtId,
                    CourtName = booking.Court?.Name ?? "",
                    StartTime = booking.StartTime,
                    EndTime = booking.EndTime,
                    IsBooked = true,
                    IsMyBooking = booking.MemberId == currentMemberId,
                    BookedByName = booking.Member?.FullName
                });
            }

            return Ok(ApiResponse<List<CalendarSlotDto>>.Ok(slots));
        }
        [HttpPost("hold")]
public async Task<ActionResult<ApiResponse<BookingDto>>> HoldSlot([FromBody] HoldSlotDto model)
{
    var memberId = GetCurrentMemberId();

    var court = await _context.Courts.FindAsync(model.CourtId);
    if (court == null || !court.IsActive)
        return BadRequest(ApiResponse<BookingDto>.Fail("Sân không tồn tại hoặc không hoạt động"));

    // chặn trùng lịch với cả Confirmed + Holding
    var hasOverlap = await _context.Bookings
        .Where(b => b.CourtId == model.CourtId)
        .Where(b => b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Holding)
        .AnyAsync(b =>
            (model.StartTime < b.EndTime) && (model.EndTime > b.StartTime));

    if (hasOverlap)
        return BadRequest(ApiResponse<BookingDto>.Fail("Slot đã được giữ/đặt bởi người khác"));

    // Nếu user đã hold đúng slot trước đó thì trả lại booking đó (tránh spam)
    var existingHold = await _context.Bookings
        .Where(b => b.MemberId == memberId)
        .Where(b => b.CourtId == model.CourtId)
        .Where(b => b.Status == BookingStatus.Holding)
        .Where(b => b.StartTime == model.StartTime && b.EndTime == model.EndTime)
        .FirstOrDefaultAsync();

    if (existingHold != null)
    {
        return Ok(ApiResponse<BookingDto>.Ok(new BookingDto
        {
            Id = existingHold.Id,
            CourtId = existingHold.CourtId,
            CourtName = court.Name,
            MemberId = existingHold.MemberId,
            StartTime = existingHold.StartTime,
            EndTime = existingHold.EndTime,
            TotalPrice = existingHold.TotalPrice,
            Status = existingHold.Status,
            IsRecurring = existingHold.IsRecurring
        }, "Bạn đã giữ slot này"));
    }

    var hours = (model.EndTime - model.StartTime).TotalHours;
    var totalPrice = (decimal)hours * court.PricePerHour;

    var booking = new Booking
    {
        CourtId = model.CourtId,
        MemberId = memberId,
        StartTime = model.StartTime,
        EndTime = model.EndTime,
        TotalPrice = totalPrice,
        Status = BookingStatus.Holding,
        CreatedDate = DateTime.UtcNow
    };

    _context.Bookings.Add(booking);
    await _context.SaveChangesAsync();

    // real-time update calendar
    await _hubContext.Clients.All.SendAsync("UpdateCalendar", "Slot held");

    return Ok(ApiResponse<BookingDto>.Ok(new BookingDto
    {
        Id = booking.Id,
        CourtId = booking.CourtId,
        CourtName = court.Name,
        MemberId = booking.MemberId,
        StartTime = booking.StartTime,
        EndTime = booking.EndTime,
        TotalPrice = booking.TotalPrice,
        Status = booking.Status,
        IsRecurring = booking.IsRecurring
    }, "Đã giữ chỗ 5 phút"));
}
[HttpPost("confirm/{id}")]
public async Task<ActionResult<ApiResponse<BookingDto>>> ConfirmHold(int id)
{
    var memberId = GetCurrentMemberId();

    var booking = await _context.Bookings
        .Include(b => b.Court)
        .Include(b => b.Member)
        .FirstOrDefaultAsync(b => b.Id == id);

    if (booking == null)
        return NotFound(ApiResponse<BookingDto>.Fail("Không tìm thấy hold"));

    if (booking.MemberId != memberId)
        return Forbid();

    if (booking.Status != BookingStatus.Holding)
        return BadRequest(ApiResponse<BookingDto>.Fail("Booking không còn ở trạng thái giữ chỗ"));

    // hết hạn 5 phút
    if (booking.CreatedDate < DateTime.UtcNow.AddMinutes(-5))
        return BadRequest(ApiResponse<BookingDto>.Fail("Hold đã hết hạn, vui lòng chọn lại slot"));

    var member = booking.Member!;
    var court = booking.Court!;

    // check ví
    if (member.WalletBalance < booking.TotalPrice)
        return BadRequest(ApiResponse<BookingDto>.Fail("Số dư không đủ để xác nhận đặt sân"));

    using var transaction = await _context.Database.BeginTransactionAsync();
    try
    {
        // trừ ví
        member.WalletBalance -= booking.TotalPrice;
        member.TotalSpent += booking.TotalPrice;
        UpdateMemberTier(member);

        // tạo transaction
        var walletTransaction = new WalletTransaction
        {
            MemberId = memberId,
            Amount = -booking.TotalPrice,
            Type = TransactionType.Payment,
            Status = TransactionStatus.Completed,
            RelatedId = booking.Id.ToString(),
            Description = $"Xác nhận đặt sân {court.Name} ({booking.StartTime:dd/MM/yyyy HH:mm} - {booking.EndTime:HH:mm})",
            CreatedDate = DateTime.UtcNow
        };
        _context.WalletTransactions.Add(walletTransaction);
        await _context.SaveChangesAsync();

        booking.TransactionId = walletTransaction.Id;
        booking.Status = BookingStatus.Confirmed;

        await _context.SaveChangesAsync();
        await transaction.CommitAsync();

        await _hubContext.Clients.All.SendAsync("UpdateCalendar", "Hold confirmed");
        await _hubContext.Clients.All.SendAsync("ReceiveNotification", "Đặt sân thành công!", "Success");

        return Ok(ApiResponse<BookingDto>.Ok(new BookingDto
        {
            Id = booking.Id,
            CourtId = booking.CourtId,
            CourtName = court.Name,
            MemberId = booking.MemberId,
            MemberName = member.FullName,
            StartTime = booking.StartTime,
            EndTime = booking.EndTime,
            TotalPrice = booking.TotalPrice,
            Status = booking.Status,
            IsRecurring = booking.IsRecurring
        }, $"Đã xác nhận đặt sân! Số dư: {member.WalletBalance:N0} VND"));
    }
    catch (Exception ex)
    {
        await transaction.RollbackAsync();
        return StatusCode(500, ApiResponse<BookingDto>.Fail($"Lỗi: {ex.Message}"));
    }
}

        /// <summary>
        /// Đặt sân đơn lẻ
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<ApiResponse<BookingDto>>> CreateBooking([FromBody] CreateBookingDto model)
        {
            var memberId = GetCurrentMemberId();
            var member = await _context.Members.FindAsync(memberId);

            if (member == null)
                return NotFound(ApiResponse<BookingDto>.Fail("Không tìm thấy thành viên"));

            var court = await _context.Courts.FindAsync(model.CourtId);
            if (court == null || !court.IsActive)
                return BadRequest(ApiResponse<BookingDto>.Fail("Sân không tồn tại hoặc không hoạt động"));

            // Check for overlapping bookings
            var hasOverlap = await _context.Bookings
                .Where(b => b.CourtId == model.CourtId)
                .Where(b => b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Holding)
                .AnyAsync(b => 
                    (model.StartTime >= b.StartTime && model.StartTime < b.EndTime) ||
                    (model.EndTime > b.StartTime && model.EndTime <= b.EndTime) ||
                    (model.StartTime <= b.StartTime && model.EndTime >= b.EndTime));

            if (hasOverlap)
                return BadRequest(ApiResponse<BookingDto>.Fail("Khung giờ này đã được đặt"));

            // Calculate total price
            var hours = (model.EndTime - model.StartTime).TotalHours;
            var totalPrice = (decimal)hours * court.PricePerHour;

            // Check wallet balance
            if (member.WalletBalance < totalPrice)
                return BadRequest(ApiResponse<BookingDto>.Fail($"Số dư ví không đủ. Cần: {totalPrice:N0} VND, Hiện có: {member.WalletBalance:N0} VND"));

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Create booking
                var booking = new Booking
                {
                    CourtId = model.CourtId,
                    MemberId = memberId,
                    StartTime = model.StartTime,
                    EndTime = model.EndTime,
                    TotalPrice = totalPrice,
                    Status = BookingStatus.Confirmed,
                    CreatedDate = DateTime.UtcNow
                };

                _context.Bookings.Add(booking);

                // Deduct from wallet
                member.WalletBalance -= totalPrice;
                member.TotalSpent += totalPrice;

                // Update tier if needed
                UpdateMemberTier(member);

                // Create wallet transaction
                var walletTransaction = new WalletTransaction
                {
                    MemberId = memberId,
                    Amount = -totalPrice,
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    RelatedId = booking.Id.ToString(),
                    Description = $"Đặt sân {court.Name} ({model.StartTime:dd/MM/yyyy HH:mm} - {model.EndTime:HH:mm})",
                    CreatedDate = DateTime.UtcNow
                };
                _context.WalletTransactions.Add(walletTransaction);

                await _context.SaveChangesAsync();

                booking.TransactionId = walletTransaction.Id;
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();

                // Broadcast calendar update via SignalR
                await _hubContext.Clients.All.SendAsync("UpdateCalendar", "New booking created");

                var result = new BookingDto
                {
                    Id = booking.Id,
                    CourtId = booking.CourtId,
                    CourtName = court.Name,
                    MemberId = booking.MemberId,
                    MemberName = member.FullName,
                    StartTime = booking.StartTime,
                    EndTime = booking.EndTime,
                    TotalPrice = booking.TotalPrice,
                    Status = booking.Status,
                    IsRecurring = booking.IsRecurring
                };

                return Ok(ApiResponse<BookingDto>.Ok(result, $"Đặt sân thành công! Số dư còn lại: {member.WalletBalance:N0} VND"));
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ApiResponse<BookingDto>.Fail($"Lỗi: {ex.Message}"));
            }
        }

        /// <summary>
        /// Đặt sân định kỳ (VIP only)
        /// </summary>
        [HttpPost("recurring")]
        public async Task<ActionResult<ApiResponse<List<BookingDto>>>> CreateRecurringBooking([FromBody] CreateRecurringBookingDto model)
        {
            var memberId = GetCurrentMemberId();
            var member = await _context.Members.FindAsync(memberId);

            if (member == null)
                return NotFound(ApiResponse<List<BookingDto>>.Fail("Không tìm thấy thành viên"));

            // Check VIP status (Gold or Diamond)
            if (member.Tier < MemberTier.Gold)
                return BadRequest(ApiResponse<List<BookingDto>>.Fail("Chỉ hội viên Gold/Diamond mới có thể đặt lịch định kỳ"));

            var court = await _context.Courts.FindAsync(model.CourtId);
            if (court == null || !court.IsActive)
                return BadRequest(ApiResponse<List<BookingDto>>.Fail("Sân không tồn tại hoặc không hoạt động"));

            // Generate all booking dates
            var bookingDates = new List<DateTime>();
            var currentDate = model.StartDate.Date;

            while (currentDate <= model.EndDate.Date)
            {
                if (model.DaysOfWeek.Contains((int)currentDate.DayOfWeek))
                {
                    bookingDates.Add(currentDate);
                }
                currentDate = currentDate.AddDays(1);
            }

            if (!bookingDates.Any())
                return BadRequest(ApiResponse<List<BookingDto>>.Fail("Không có ngày nào phù hợp trong khoảng thời gian đã chọn"));

            // Calculate total price
            var hoursPerSession = (model.EndTime - model.StartTime).TotalHours;
            var pricePerSession = (decimal)hoursPerSession * court.PricePerHour;
            var totalPrice = pricePerSession * bookingDates.Count;

            // Check wallet balance
            if (member.WalletBalance < totalPrice)
                return BadRequest(ApiResponse<List<BookingDto>>.Fail($"Số dư ví không đủ. Cần: {totalPrice:N0} VND cho {bookingDates.Count} buổi"));

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var createdBookings = new List<BookingDto>();
                var recurrenceRule = $"Weekly;{string.Join(",", model.DaysOfWeek)}";

                // Create parent booking (first one)
                Booking? parentBooking = null;

                foreach (var date in bookingDates)
                {
                    var startTime = date.Add(model.StartTime);
                    var endTime = date.Add(model.EndTime);

                    // Check overlap
                    var hasOverlap = await _context.Bookings
                        .Where(b => b.CourtId == model.CourtId)
                        .Where(b => b.Status == BookingStatus.Confirmed)
                        .AnyAsync(b =>
                            (startTime >= b.StartTime && startTime < b.EndTime) ||
                            (endTime > b.StartTime && endTime <= b.EndTime));

                    if (hasOverlap)
                        continue; // Skip overlapping slots

                    var booking = new Booking
                    {
                        CourtId = model.CourtId,
                        MemberId = memberId,
                        StartTime = startTime,
                        EndTime = endTime,
                        TotalPrice = pricePerSession,
                        Status = BookingStatus.Confirmed,
                        IsRecurring = true,
                        RecurrenceRule = recurrenceRule,
                        ParentBookingId = parentBooking?.Id,
                        CreatedDate = DateTime.UtcNow
                    };

                    _context.Bookings.Add(booking);
                    await _context.SaveChangesAsync();

                    if (parentBooking == null)
                        parentBooking = booking;

                    createdBookings.Add(new BookingDto
                    {
                        Id = booking.Id,
                        CourtId = booking.CourtId,
                        CourtName = court.Name,
                        MemberId = booking.MemberId,
                        MemberName = member.FullName,
                        StartTime = booking.StartTime,
                        EndTime = booking.EndTime,
                        TotalPrice = booking.TotalPrice,
                        Status = booking.Status,
                        IsRecurring = true
                    });
                }

                if (!createdBookings.Any())
                    return BadRequest(ApiResponse<List<BookingDto>>.Fail("Tất cả các khung giờ đã được đặt"));

                // Deduct total from wallet
                var actualTotalPrice = pricePerSession * createdBookings.Count;
                member.WalletBalance -= actualTotalPrice;
                member.TotalSpent += actualTotalPrice;
                UpdateMemberTier(member);

                // Create wallet transaction
                var walletTransaction = new WalletTransaction
                {
                    MemberId = memberId,
                    Amount = -actualTotalPrice,
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    RelatedId = parentBooking!.Id.ToString(),
                    Description = $"Đặt sân định kỳ {court.Name} ({createdBookings.Count} buổi)",
                    CreatedDate = DateTime.UtcNow
                };
                _context.WalletTransactions.Add(walletTransaction);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Broadcast calendar update
                await _hubContext.Clients.All.SendAsync("UpdateCalendar", "Recurring bookings created");

                return Ok(ApiResponse<List<BookingDto>>.Ok(createdBookings, 
                    $"Đã đặt {createdBookings.Count} buổi thành công! Số dư còn lại: {member.WalletBalance:N0} VND"));
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ApiResponse<List<BookingDto>>.Fail($"Lỗi: {ex.Message}"));
            }
        }

        /// <summary>
        /// Hủy đặt sân
        /// </summary>
        [HttpPost("cancel/{id}")]
        public async Task<ActionResult<ApiResponse<BookingDto>>> CancelBooking(int id)
        {
            var memberId = GetCurrentMemberId();
            var booking = await _context.Bookings
                .Include(b => b.Court)
                .Include(b => b.Member)
                .FirstOrDefaultAsync(b => b.Id == id);

            if (booking == null)
                return NotFound(ApiResponse<BookingDto>.Fail("Không tìm thấy booking"));

            if (booking.MemberId != memberId && !User.IsInRole("Admin"))
                return Forbid();

            if (booking.Status == BookingStatus.Cancelled)
                return BadRequest(ApiResponse<BookingDto>.Fail("Booking đã được hủy trước đó"));

            if (booking.Status == BookingStatus.Completed)
                return BadRequest(ApiResponse<BookingDto>.Fail("Không thể hủy booking đã hoàn thành"));

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Calculate refund based on time
                var hoursUntilBooking = (booking.StartTime - DateTime.UtcNow).TotalHours;
                decimal refundPercentage = hoursUntilBooking switch
                {
                    >= 24 => 1.0m,    // 100% refund if > 24h
                    >= 12 => 0.5m,    // 50% refund if 12-24h
                    >= 6 => 0.25m,    // 25% refund if 6-12h
                    _ => 0m           // No refund if < 6h
                };

                var refundAmount = booking.TotalPrice * refundPercentage;

                booking.Status = BookingStatus.Cancelled;

                if (refundAmount > 0)
                {
                    var member = booking.Member!;
                    member.WalletBalance += refundAmount;

                    var refundTransaction = new WalletTransaction
                    {
                        MemberId = memberId,
                        Amount = refundAmount,
                        Type = TransactionType.Refund,
                        Status = TransactionStatus.Completed,
                        RelatedId = booking.Id.ToString(),
                        Description = $"Hoàn tiền hủy sân {booking.Court!.Name} ({refundPercentage * 100}%)",
                        CreatedDate = DateTime.UtcNow
                    };
                    _context.WalletTransactions.Add(refundTransaction);
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Broadcast calendar update
                await _hubContext.Clients.All.SendAsync("UpdateCalendar", "Booking cancelled");

                var result = new BookingDto
                {
                    Id = booking.Id,
                    CourtId = booking.CourtId,
                    CourtName = booking.Court!.Name,
                    MemberId = booking.MemberId,
                    MemberName = booking.Member!.FullName,
                    StartTime = booking.StartTime,
                    EndTime = booking.EndTime,
                    TotalPrice = booking.TotalPrice,
                    Status = booking.Status,
                    IsRecurring = booking.IsRecurring
                };

                var message = refundAmount > 0 
                    ? $"Đã hủy booking và hoàn {refundAmount:N0} VND ({refundPercentage * 100}%)"
                    : "Đã hủy booking (không hoàn tiền do hủy quá muộn)";

                return Ok(ApiResponse<BookingDto>.Ok(result, message));
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ApiResponse<BookingDto>.Fail($"Lỗi: {ex.Message}"));
            }
        }

        /// <summary>
        /// Lấy danh sách booking của tôi
        /// </summary>
        [HttpGet("my")]
        public async Task<ActionResult<ApiResponse<List<BookingDto>>>> GetMyBookings([FromQuery] BookingStatus? status = null)
        {
            var memberId = GetCurrentMemberId();

            var query = _context.Bookings
                .Include(b => b.Court)
                .Include(b => b.Member)
                .Where(b => b.MemberId == memberId);

            if (status.HasValue)
                query = query.Where(b => b.Status == status.Value);

            var bookings = await query
                .OrderByDescending(b => b.StartTime)
                .Select(b => new BookingDto
                {
                    Id = b.Id,
                    CourtId = b.CourtId,
                    CourtName = b.Court!.Name,
                    MemberId = b.MemberId,
                    MemberName = b.Member!.FullName,
                    StartTime = b.StartTime,
                    EndTime = b.EndTime,
                    TotalPrice = b.TotalPrice,
                    Status = b.Status,
                    IsRecurring = b.IsRecurring
                })
                .ToListAsync();

            return Ok(ApiResponse<List<BookingDto>>.Ok(bookings));
        }

        private int GetCurrentMemberId()
        {
            var memberIdClaim = User.FindFirst("MemberId")?.Value;
            return int.TryParse(memberIdClaim, out var id) ? id : 0;
        }

        private void UpdateMemberTier(Member member)
        {
            member.Tier = member.TotalSpent switch
            {
                >= 20000000 => MemberTier.Diamond,
                >= 10000000 => MemberTier.Gold,
                >= 5000000 => MemberTier.Silver,
                _ => MemberTier.Standard
            };
        }
    }
}
