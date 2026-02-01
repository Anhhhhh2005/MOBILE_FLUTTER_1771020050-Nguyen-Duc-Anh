using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    /// <summary>
    /// Bảng trận đấu - Tên bảng: [xxx]_Matches
    /// </summary>
    [Table("734_Matches")]
    public class Match
    {
        [Key]
        public int Id { get; set; }

        /// <summary>
        /// Giải đấu (nullable nếu là trận giao hữu)
        /// </summary>
        public int? TournamentId { get; set; }

        [ForeignKey("TournamentId")]
        public virtual Tournament? Tournament { get; set; }

        /// <summary>
        /// Tên vòng đấu (VD: "Group A", "Quarter Final", "Semi Final", "Final")
        /// </summary>
        [MaxLength(100)]
        public string? RoundName { get; set; }

        /// <summary>
        /// Ngày thi đấu
        /// </summary>
        [Required]
        public DateTime Date { get; set; }

        /// <summary>
        /// Giờ bắt đầu
        /// </summary>
        public DateTime StartTime { get; set; }

        // Team 1 Players
        public int? Team1_Player1Id { get; set; }

        [ForeignKey("Team1_Player1Id")]
        public virtual Member? Team1_Player1 { get; set; }

        public int? Team1_Player2Id { get; set; }

        [ForeignKey("Team1_Player2Id")]
        public virtual Member? Team1_Player2 { get; set; }

        // Team 2 Players
        public int? Team2_Player1Id { get; set; }

        [ForeignKey("Team2_Player1Id")]
        public virtual Member? Team2_Player1 { get; set; }

        public int? Team2_Player2Id { get; set; }

        [ForeignKey("Team2_Player2Id")]
        public virtual Member? Team2_Player2 { get; set; }

        // Results
        /// <summary>
        /// Tỉ số Team 1 (VD: 2 set thắng)
        /// </summary>
        public int Score1 { get; set; } = 0;

        /// <summary>
        /// Tỉ số Team 2 (VD: 1 set thắng)
        /// </summary>
        public int Score2 { get; set; } = 0;

        /// <summary>
        /// Chi tiết các set (VD: "11-9, 5-11, 11-8")
        /// </summary>
        [MaxLength(500)]
        public string? Details { get; set; }

        /// <summary>
        /// Đội thắng
        /// </summary>
        public WinningSide? WinningSide { get; set; }

        /// <summary>
        /// Có tính điểm DUPR không
        /// </summary>
        public bool IsRanked { get; set; } = true;

        /// <summary>
        /// Trạng thái: Scheduled, InProgress, Finished
        /// </summary>
        public MatchStatus Status { get; set; } = MatchStatus.Scheduled;

        /// <summary>
        /// Sân thi đấu
        /// </summary>
        public int? CourtId { get; set; }

        [ForeignKey("CourtId")]
        public virtual Court? Court { get; set; }

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    }
}
