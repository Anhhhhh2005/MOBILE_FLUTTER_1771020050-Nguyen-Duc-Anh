using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    /// <summary>
    /// Bảng giao dịch ví - Tên bảng: [xxx]_WalletTransactions
    /// </summary>
    [Table("734_WalletTransactions")]
    public class WalletTransaction
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int MemberId { get; set; }

        [ForeignKey("MemberId")]
        public virtual Member? Member { get; set; }

        /// <summary>
        /// Số tiền giao dịch (+ cho nạp/thưởng, - cho thanh toán/rút)
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        /// <summary>
        /// Loại giao dịch: Deposit, Withdraw, Payment, Refund, Reward
        /// </summary>
        [Required]
        public TransactionType Type { get; set; }

        /// <summary>
        /// Trạng thái: Pending, Completed, Rejected, Failed
        /// </summary>
        [Required]
        public TransactionStatus Status { get; set; } = TransactionStatus.Pending;

        /// <summary>
        /// ID liên quan (Booking ID hoặc Tournament ID) để truy vết
        /// </summary>
        [MaxLength(100)]
        public string? RelatedId { get; set; }

        /// <summary>
        /// Mô tả giao dịch
        /// </summary>
        [MaxLength(500)]
        public string? Description { get; set; }

        /// <summary>
        /// Ngày tạo giao dịch
        /// </summary>
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Đường dẫn ảnh bằng chứng chuyển khoản (cho Deposit)
        /// </summary>
        [MaxLength(500)]
        public string? ProofImageUrl { get; set; }
    }
}
