using System.ComponentModel.DataAnnotations;
using PcmBackend.Models;

namespace PcmBackend.DTOs
{
    // ==================== Auth DTOs ====================
    public class LoginDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }
        public class HoldSlotDto
        {
            public int CourtId { get; set; }
            public DateTime StartTime { get; set; }
            public DateTime EndTime { get; set; }
        }

    public class RegisterDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;
    }

    public class AuthResponseDto
    {
        public string Token { get; set; } = string.Empty;
        public DateTime Expiration { get; set; }
        public UserInfoDto User { get; set; } = new();
    }

    public class UserInfoDto
    {
        public int MemberId { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public double RankLevel { get; set; }
        public MemberTier Tier { get; set; }
        public decimal WalletBalance { get; set; }
        public List<string> Roles { get; set; } = new();
    }

    // ==================== Member DTOs ====================
    public class MemberDto
    {
        public int Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public DateTime JoinDate { get; set; }
        public double RankLevel { get; set; }
        public MemberTier Tier { get; set; }
        public decimal WalletBalance { get; set; }
        public string? AvatarUrl { get; set; }
        public bool IsActive { get; set; }
    }

    public class MemberProfileDto : MemberDto
    {
        public decimal TotalSpent { get; set; }
        public int TotalMatches { get; set; }
        public int TotalWins { get; set; }
        public int TotalTournaments { get; set; }
        public List<MatchDto> RecentMatches { get; set; } = new();
    }

    public class UpdateMemberDto
    {
        [MaxLength(100)]
        public string? FullName { get; set; }
        public string? AvatarUrl { get; set; }
    }

    // ==================== Wallet DTOs ====================
    public class DepositRequestDto
    {
        [Required]
        [Range(10000, 100000000)]
        public decimal Amount { get; set; }

        public string? ProofImageUrl { get; set; }
        public string? Description { get; set; }
    }

    public class WalletTransactionDto
    {
        public int Id { get; set; }
        public decimal Amount { get; set; }
        public TransactionType Type { get; set; }
        public TransactionStatus Status { get; set; }
        public string? Description { get; set; }
        public string? RelatedId { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    // ==================== Court DTOs ====================
    public class CourtDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public decimal PricePerHour { get; set; }
        public bool IsActive { get; set; }
    }

    // ==================== Booking DTOs ====================
    public class CreateBookingDto
    {
        [Required]
        public int CourtId { get; set; }

        [Required]
        public DateTime StartTime { get; set; }

        [Required]
        public DateTime EndTime { get; set; }
    }

    public class CreateRecurringBookingDto
    {
        [Required]
        public int CourtId { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        /// <summary>
        /// Danh sách ngày trong tuần (0=Sunday, 1=Monday, ... 6=Saturday)
        /// </summary>
        [Required]
        public List<int> DaysOfWeek { get; set; } = new();

        [Required]
        public TimeSpan StartTime { get; set; }

        [Required]
        public TimeSpan EndTime { get; set; }
    }

    public class BookingDto
    {
        public int Id { get; set; }
        public int CourtId { get; set; }
        public string CourtName { get; set; } = string.Empty;
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public decimal TotalPrice { get; set; }
        public BookingStatus Status { get; set; }
        public bool IsRecurring { get; set; }
    }

    public class CalendarSlotDto
    {
        public int? BookingId { get; set; }
        public int CourtId { get; set; }
        public string CourtName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public bool IsBooked { get; set; }
        public bool IsMyBooking { get; set; }
        public string? BookedByName { get; set; }
    }

    // ==================== Tournament DTOs ====================
    public class TournamentDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public TournamentFormat Format { get; set; }
        public decimal EntryFee { get; set; }
        public decimal PrizePool { get; set; }
        public TournamentStatus Status { get; set; }
        public string? Settings { get; set; }
        public int MaxParticipants { get; set; }
        public int CurrentParticipants { get; set; }
    }

    public class TournamentDetailDto : TournamentDto
    {
        public List<ParticipantDto> Participants { get; set; } = new();
        public List<MatchDto> Matches { get; set; } = new();
    }

    public class CreateTournamentDto
    {
        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        public TournamentFormat Format { get; set; } = TournamentFormat.Knockout;
        public decimal EntryFee { get; set; } = 0;
        public decimal PrizePool { get; set; } = 0;
        public string? Settings { get; set; }
        public int MaxParticipants { get; set; } = 16;
    }

    public class JoinTournamentDto
    {
        public string? TeamName { get; set; }
        public int? PartnerId { get; set; }
    }

    public class ParticipantDto
    {
        public int Id { get; set; }
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public string? TeamName { get; set; }
        public int? PartnerId { get; set; }
        public string? PartnerName { get; set; }
        public int? Seed { get; set; }
        public bool PaymentStatus { get; set; }
    }

    // ==================== Match DTOs ====================
    public class MatchDto
    {
        public int Id { get; set; }
        public int? TournamentId { get; set; }
        public string? TournamentName { get; set; }
        public string? RoundName { get; set; }
        public DateTime Date { get; set; }
        public DateTime StartTime { get; set; }

        // Team 1
        public int? Team1_Player1Id { get; set; }
        public string? Team1_Player1Name { get; set; }
        public int? Team1_Player2Id { get; set; }
        public string? Team1_Player2Name { get; set; }

        // Team 2
        public int? Team2_Player1Id { get; set; }
        public string? Team2_Player1Name { get; set; }
        public int? Team2_Player2Id { get; set; }
        public string? Team2_Player2Name { get; set; }

        // Result
        public int Score1 { get; set; }
        public int Score2 { get; set; }
        public string? Details { get; set; }
        public WinningSide? WinningSide { get; set; }
        public MatchStatus Status { get; set; }
    }

    public class UpdateMatchResultDto
    {
        [Required]
        public int Score1 { get; set; }

        [Required]
        public int Score2 { get; set; }

        public string? Details { get; set; }

        [Required]
        public WinningSide WinningSide { get; set; }
    }

    // ==================== News DTOs ====================
    public class NewsDto
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public bool IsPinned { get; set; }
        public string? ImageUrl { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    // ==================== Notification DTOs ====================
    public class NotificationDto
    {
        public int Id { get; set; }
        public string Message { get; set; } = string.Empty;
        public NotificationType Type { get; set; }
        public string? LinkUrl { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    // ==================== Common DTOs ====================
    public class PaginatedResult<T>
    {
        public List<T> Items { get; set; } = new();
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
    }

    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public T? Data { get; set; }

        public static ApiResponse<T> Ok(T data, string? message = null) => new()
        {
            Success = true,
            Data = data,
            Message = message
        };

        public static ApiResponse<T> Fail(string message) => new()
        {
            Success = false,
            Message = message
        };
    }
}
