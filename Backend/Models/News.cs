using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    /// <summary>
    /// Bảng tin tức - Tên bảng: [xxx]_News
    /// </summary>
    [Table("734_News")]
    public class News
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string Content { get; set; } = string.Empty;

        /// <summary>
        /// Tin được ghim lên đầu
        /// </summary>
        public bool IsPinned { get; set; } = false;

        /// <summary>
        /// Đường dẫn ảnh minh họa
        /// </summary>
        [MaxLength(500)]
        public string? ImageUrl { get; set; }

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Người tạo tin (Admin/Staff ID)
        /// </summary>
        public int? CreatedByMemberId { get; set; }

        [ForeignKey("CreatedByMemberId")]
        public virtual Member? CreatedBy { get; set; }
    }
}
