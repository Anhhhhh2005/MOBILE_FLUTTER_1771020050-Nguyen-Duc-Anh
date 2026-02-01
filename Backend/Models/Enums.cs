namespace PcmBackend.Models
{
    // Hạng thành viên
    public enum MemberTier
    {
        Standard = 0,
        Silver = 1,
        Gold = 2,
        Diamond = 3
    }

    // Loại giao dịch ví
    public enum TransactionType
    {
        Deposit = 0,      // Nạp tiền
        Withdraw = 1,     // Rút tiền
        Payment = 2,      // Thanh toán phí
        Refund = 3,       // Hoàn tiền
        Reward = 4        // Thưởng giải
    }

    // Trạng thái giao dịch
    public enum TransactionStatus
    {
        Pending = 0,      // Chờ duyệt
        Completed = 1,    // Hoàn thành
        Rejected = 2,     // Từ chối
        Failed = 3        // Thất bại
    }

    // Trạng thái booking
    public enum BookingStatus
    {
        PendingPayment = 0,  // Chờ thanh toán
        Confirmed = 1,       // Đã xác nhận
        Cancelled = 2,       // Đã hủy
        Completed = 3, 
        Holding = 4       // Hoàn thành
    }

    // Thể thức giải đấu
    public enum TournamentFormat
    {
        RoundRobin = 0,   // Vòng tròn
        Knockout = 1,     // Loại trực tiếp
        Hybrid = 2        // Kết hợp
    }

    // Trạng thái giải đấu
    public enum TournamentStatus
    {
        Open = 0,            // Mở đăng ký
        Registering = 1,     // Đang đăng ký
        DrawCompleted = 2,   // Đã bốc thăm
        Ongoing = 3,         // Đang diễn ra
        Finished = 4         // Kết thúc
    }

    // Trạng thái trận đấu
    public enum MatchStatus
    {
        Scheduled = 0,    // Đã lên lịch
        InProgress = 1,   // Đang diễn ra
        Finished = 2      // Kết thúc
    }

    // Đội thắng
    public enum WinningSide
    {
        Team1 = 1,
        Team2 = 2
    }

    // Loại thông báo
    public enum NotificationType
    {
        Info = 0,
        Success = 1,
        Warning = 2,
        Error = 3
    }

    // Loại danh mục giao dịch (thu/chi)
    public enum TransactionCategoryType
    {
        Income = 0,    // Thu
        Expense = 1    // Chi
    }
}
