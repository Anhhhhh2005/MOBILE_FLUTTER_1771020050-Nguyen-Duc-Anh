using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace PcmBackend.Models
{
    /// <summary>
    /// Bảng thành viên CLB - Tên bảng: [xxx]_Members (thay xxx bằng 3 số cuối MSSV)
    /// </summary>
    [Table("734_Members")]
    public class Member
    {
        [Key]
        public int Id { get; set; }

        /// <summary>
        /// Liên kết với Identity User
        /// </summary>
        [Required]
        public string UserId { get; set; } = string.Empty;

        [ForeignKey("UserId")]
        public virtual IdentityUser? User { get; set; }

        [Required]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        public DateTime JoinDate { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Điểm xếp hạng DUPR (0.0 - 8.0)
        /// </summary>
        [Range(0, 8)]
        public double RankLevel { get; set; } = 3.0;

        /// <summary>
        /// Số dư ví điện tử
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal WalletBalance { get; set; } = 0;

        /// <summary>
        /// Hạng thành viên (Standard, Silver, Gold, Diamond)
        /// </summary>
        public MemberTier Tier { get; set; } = MemberTier.Standard;

        /// <summary>
        /// Tổng tiền đã chi tiêu (để xét nâng hạng)
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalSpent { get; set; } = 0;

        /// <summary>
        /// Đường dẫn ảnh đại diện
        /// </summary>
        [MaxLength(500)]
        public string? AvatarUrl { get; set; }

        public bool IsActive { get; set; } = true;

        // Navigation properties
        public virtual ICollection<WalletTransaction> WalletTransactions { get; set; } = new List<WalletTransaction>();
        public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();
        public virtual ICollection<TournamentParticipant> TournamentParticipants { get; set; } = new List<TournamentParticipant>();
        public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    }
}
