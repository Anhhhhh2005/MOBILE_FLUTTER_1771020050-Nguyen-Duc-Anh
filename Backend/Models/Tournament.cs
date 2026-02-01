using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    /// <summary>
    /// Bảng giải đấu - Tên bảng: [xxx]_Tournaments
    /// </summary>
    [Table("734_Tournaments")]
    public class Tournament
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Description { get; set; }

        /// <summary>
        /// Ngày bắt đầu giải đấu
        /// </summary>
        [Required]
        public DateTime StartDate { get; set; }

        /// <summary>
        /// Ngày kết thúc giải đấu
        /// </summary>
        [Required]
        public DateTime EndDate { get; set; }

        /// <summary>
        /// Thể thức: RoundRobin, Knockout, Hybrid
        /// </summary>
        public TournamentFormat Format { get; set; } = TournamentFormat.Knockout;

        /// <summary>
        /// Phí tham gia (VND)
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal EntryFee { get; set; } = 0;

        /// <summary>
        /// Tổng giải thưởng (VND)
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal PrizePool { get; set; } = 0;

        /// <summary>
        /// Trạng thái: Open, Registering, DrawCompleted, Ongoing, Finished
        /// </summary>
        public TournamentStatus Status { get; set; } = TournamentStatus.Open;

        /// <summary>
        /// Cấu hình nâng cao (JSON): số bảng, số đội vào vòng trong...
        /// Cấu hình nâng cao (JSON): Số bảng, số đội vào vòng trong, v.v.
        /// </summary>
        public string? Settings { get; set; }

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        // Helper methods
        public int GetMaxParticipants()
        {
            if (string.IsNullOrEmpty(Settings))
                return 16; // Default

            try
            {
                var json = System.Text.Json.JsonDocument.Parse(Settings);
                if (json.RootElement.TryGetProperty("maxParticipants", out var maxProp))
                {
                    return maxProp.GetInt32();
                }
            }
            catch { }

            return 16;
        }

        // Navigation properties
        public virtual ICollection<TournamentParticipant> Participants { get; set; } = new List<TournamentParticipant>();
        public virtual ICollection<Match> Matches { get; set; } = new List<Match>();
    }
}
