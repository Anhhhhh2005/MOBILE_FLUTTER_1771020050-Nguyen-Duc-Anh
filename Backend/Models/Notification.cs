using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    /// <summary>
    /// Bảng thông báo - Tên bảng: [xxx]_Notifications
    /// </summary>
    [Table("734_Notifications")]
    public class Notification
    {
        [Key]
        public int Id { get; set; }

        /// <summary>
        /// Người nhận thông báo
        /// </summary>
        [Required]
        public int ReceiverId { get; set; }

        [ForeignKey("ReceiverId")]
        public virtual Member? Receiver { get; set; }

        /// <summary>
        /// Nội dung thông báo
        /// </summary>
        [Required]
        [MaxLength(500)]
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// Loại thông báo: Info, Success, Warning
        /// </summary>
        public NotificationType Type { get; set; } = NotificationType.Info;

        /// <summary>
        /// Đường dẫn liên quan (VD: /tournaments/1, /bookings/5)
        /// </summary>
        [MaxLength(200)]
        public string? LinkUrl { get; set; }

        /// <summary>
        /// Đã đọc chưa
        /// </summary>
        public bool IsRead { get; set; } = false;

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    }
}
