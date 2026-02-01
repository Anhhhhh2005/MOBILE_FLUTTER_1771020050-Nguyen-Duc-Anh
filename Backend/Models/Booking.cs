using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    /// <summary>
    /// Bảng đặt sân - Tên bảng: [xxx]_Bookings
    /// </summary>
    [Table("734_Bookings")]
    public class Booking
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CourtId { get; set; }

        [ForeignKey("CourtId")]
        public virtual Court? Court { get; set; }

        [Required]
        public int MemberId { get; set; }

        [ForeignKey("MemberId")]
        public virtual Member? Member { get; set; }

        /// <summary>
        /// Thời gian bắt đầu
        /// </summary>
        [Required]
        public DateTime StartTime { get; set; }

        /// <summary>
        /// Thời gian kết thúc
        /// </summary>
        [Required]
        public DateTime EndTime { get; set; }

        /// <summary>
        /// Tổng tiền thanh toán
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPrice { get; set; }

        /// <summary>
        /// Liên kết với giao dịch trừ tiền trong ví
        /// </summary>
        public int? TransactionId { get; set; }

        [ForeignKey("TransactionId")]
        public virtual WalletTransaction? Transaction { get; set; }

        /// <summary>
        /// Đánh dấu là đặt lịch lặp
        /// </summary>
        public bool IsRecurring { get; set; } = false;

        /// <summary>
        /// Quy tắc lặp (VD: "Weekly;Tue,Thu")
        /// </summary>
        [MaxLength(200)]
        public string? RecurrenceRule { get; set; }

        /// <summary>
        /// Nếu đây là booking con sinh ra từ lịch lặp
        /// </summary>
        public int? ParentBookingId { get; set; }

        [ForeignKey("ParentBookingId")]
        public virtual Booking? ParentBooking { get; set; }

        /// <summary>
        /// Trạng thái: PendingPayment, Confirmed, Cancelled, Completed
        /// </summary>
        public BookingStatus Status { get; set; } = BookingStatus.PendingPayment;

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual ICollection<Booking> ChildBookings { get; set; } = new List<Booking>();
    }
}
