using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    /// <summary>
    /// Bảng người tham gia giải đấu - Tên bảng: [xxx]_TournamentParticipants
    /// </summary>
    [Table("734_TournamentParticipants")]
    public class TournamentParticipant
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int TournamentId { get; set; }

        [ForeignKey("TournamentId")]
        public virtual Tournament? Tournament { get; set; }

        [Required]
        public int MemberId { get; set; }

        [ForeignKey("MemberId")]
        public virtual Member? Member { get; set; }

        /// <summary>
        /// Tên đội (nếu đánh đôi)
        /// </summary>
        [MaxLength(100)]
        public string? TeamName { get; set; }

        /// <summary>
        /// ID đồng đội (nếu đánh đôi)
        /// </summary>
        public int? PartnerId { get; set; }

        [ForeignKey("PartnerId")]
        public virtual Member? Partner { get; set; }

        /// <summary>
        /// Đã trừ EntryFee chưa
        /// </summary>
        public bool PaymentStatus { get; set; } = false;

        /// <summary>
        /// Hạt giống (Seed) - để xếp cặp đấu
        /// </summary>
        public int? Seed { get; set; }

        public DateTime RegisteredDate { get; set; } = DateTime.UtcNow;
    }
}
