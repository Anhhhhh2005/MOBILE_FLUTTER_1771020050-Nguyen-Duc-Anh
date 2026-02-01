using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AdminController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public AdminController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Lấy tổng quỹ CLB (tổng số dư của tất cả members)
    /// </summary>
    [HttpGet("club-balance")]
    [Authorize(Roles = "Admin,Treasurer")]
    public async Task<IActionResult> GetClubBalance()
    {
        try
        {
            // Fetch balances locally to avoid SQL translation issues with SumAsync on decimal
            var balances = await _context.Members
                .Select(m => m.WalletBalance)
                .ToListAsync();
                
            var totalBalance = balances.Sum();
            var memberCount = balances.Count;
            
            var result = new
            {
                totalBalance,
                isNegative = totalBalance < 0,
                warning = totalBalance < 0 ? "⚠️ Quỹ CLB đang âm!" : null,
                memberCount,
                timestamp = DateTime.UtcNow
            };

            return Ok(new { success = true, data = result });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new 
            { 
                success = false, 
                message = "Internal Server Error in GetClubBalance", 
                error = ex.Message,
                stackTrace = ex.StackTrace 
            });
        }
    }

    /// <summary>
    /// Lấy lịch sử thu/chi CLB (tất cả transactions)
    /// </summary>
    [HttpGet("club-transactions")]
    [Authorize(Roles = "Admin,Treasurer")]
    public async Task<IActionResult> GetClubTransactions(
        [FromQuery] TransactionType? type,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        var query = _context.WalletTransactions
            .Include(wt => wt.Member)
            .OrderByDescending(wt => wt.CreatedDate)
            .AsQueryable();

        if (type.HasValue)
        {
            query = query.Where(wt => wt.Type == type.Value);
        }

        var total = await query.CountAsync();
        var transactions = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(wt => new
            {
                wt.Id,
                wt.Amount,
                wt.Type,
                wt.Status,
                wt.Description,
                wt.CreatedDate,
                member = new
                {
                    wt.Member!.Id,
                    wt.Member.FullName
                }
            })
            .ToListAsync();

        // Calculate totals - fetch to memory first to avoid SQL translation issues
        var completedTransactions = await _context.WalletTransactions
            .Where(wt => wt.Status == TransactionStatus.Completed)
            .Select(wt => new { wt.Amount, wt.Type })
            .ToListAsync();

        var totalIncome = completedTransactions
            .Where(wt => wt.Type == TransactionType.Deposit || wt.Type == TransactionType.Reward)
            .Sum(wt => wt.Amount);

        var totalExpense = completedTransactions
            .Where(wt => wt.Type == TransactionType.Payment || wt.Type == TransactionType.Withdraw)
            .Sum(wt => Math.Abs(wt.Amount));

        return Ok(new
        {
            success = true,
            data = new
            {
                transactions,
                pagination = new
                {
                    page,
                    pageSize,
                    total,
                    totalPages = (int)Math.Ceiling(total / (double)pageSize)
                },
                summary = new
                {
                    totalIncome,
                    totalExpense,
                    netBalance = totalIncome - totalExpense
                }
            }
        });
    }

    /// <summary>
    /// Dashboard stats cho Admin
    /// </summary>
    [HttpGet("dashboard/stats")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetDashboardStats()
    {
        try
        {
            var now = DateTime.UtcNow;
            var thisMonth = new DateTime(now.Year, now.Month, 1);

            // Fetch Data
            var members = await _context.Members.Select(m => new { m.Tier, m.WalletBalance }).ToListAsync();
            var bookings = await _context.Bookings.Select(b => new { b.CreatedDate, b.Status, b.StartTime }).ToListAsync();
            var tournaments = await _context.Tournaments.Select(t => new { t.Status }).ToListAsync();
            var transactions = await _context.WalletTransactions
                .Where(wt => wt.CreatedDate >= thisMonth)
                .Select(wt => new { wt.Status, wt.Type, wt.Amount })
                .ToListAsync();

            var stats = new
            {
                members = new
                {
                    total = members.Count,
                    byTier = members
                        .GroupBy(m => m.Tier)
                        .Select(g => new { tier = g.Key.ToString(), count = g.Count() })
                        .ToList()
                },
                bookings = new
                {
                    total = bookings.Count,
                    thisMonth = bookings.Count(b => b.CreatedDate >= thisMonth),
                    active = bookings.Count(b => b.Status == BookingStatus.Confirmed && b.StartTime > now)
                },
                tournaments = new
                {
                    total = tournaments.Count,
                    open = tournaments.Count(t => t.Status == TournamentStatus.Open || t.Status == TournamentStatus.Registering),
                    ongoing = tournaments.Count(t => t.Status == TournamentStatus.Ongoing)
                },
                finance = new
                {
                    clubBalance = members.Sum(m => m.WalletBalance),
                    thisMonthRevenue = transactions
                        .Where(wt => wt.Status == TransactionStatus.Completed &&
                                    (wt.Type == TransactionType.Payment || wt.Type == TransactionType.Deposit)) // Revenue usually includes payments received
                        .Sum(wt => Math.Abs(wt.Amount)),
                    pendingDeposits = transactions
                        .Count(wt => wt.Type == TransactionType.Deposit && wt.Status == TransactionStatus.Pending)
                }
            };

            return Ok(new { success = true, data = stats });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    /// <summary>
    /// Biểu đồ doanh thu theo tháng (12 tháng gần nhất)
    /// </summary>
    [HttpGet("dashboard/revenue")]
    [Authorize(Roles = "Admin,Treasurer")]
    public async Task<IActionResult> GetRevenueChart()
    {
        try 
        {
            var now = DateTime.UtcNow;
            var twelveMonthsAgo = now.AddMonths(-12);

            // Fetch data first
            var revenueData = await _context.WalletTransactions
                .Where(wt => wt.CreatedDate >= twelveMonthsAgo && 
                            wt.Status == TransactionStatus.Completed)
                .Select(wt => new { wt.CreatedDate, wt.Amount, wt.Type })
                .ToListAsync();

            var chartData = revenueData
                .GroupBy(wt => new { wt.CreatedDate.Year, wt.CreatedDate.Month })
                .Select(g => new
                {
                    year = g.Key.Year,
                    month = g.Key.Month,
                    income = g.Where(wt => wt.Type == TransactionType.Deposit || wt.Type == TransactionType.Reward)
                            .Sum(wt => wt.Amount),
                    expense = g.Where(wt => wt.Type == TransactionType.Payment || wt.Type == TransactionType.Withdraw)
                            .Sum(wt => Math.Abs(wt.Amount))
                })
                .OrderBy(x => x.year).ThenBy(x => x.month)
                .Select(r => new
                {
                    month = $"{r.year}-{r.month:D2}",
                    income = r.income,
                    expense = r.expense,
                    net = r.income - r.expense
                })
                .ToList();

            return Ok(new { success = true, data = chartData });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    /// <summary>
    /// Biểu đồ bookings theo tháng
    /// </summary>
    [HttpGet("dashboard/bookings-chart")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetBookingsChart()
    {
        var now = DateTime.UtcNow;
        var sixMonthsAgo = now.AddMonths(-6);

        var bookingData = await _context.Bookings
            .Where(b => b.CreatedDate >= sixMonthsAgo)
            .GroupBy(b => new { b.CreatedDate.Year, b.CreatedDate.Month })
            .Select(g => new
            {
                year = g.Key.Year,
                month = g.Key.Month,
                count = g.Count(),
                revenue = g.Sum(b => b.TotalPrice)
            })
            .OrderBy(x => x.year).ThenBy(x => x.month)
            .ToListAsync();

        var chartData = bookingData.Select(b => new
        {
            month = $"{b.year}-{b.month:D2}",
            bookings = b.count,
            revenue = b.revenue
        }).ToList();

        return Ok(new { success = true, data = chartData });
    }
}
