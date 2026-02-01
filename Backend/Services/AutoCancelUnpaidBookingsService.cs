using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Services
{
    /// <summary>
    /// Background service tự động hủy booking chưa thanh toán sau 5 phút
    /// </summary>
    public class AutoCancelUnpaidBookingsService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<AutoCancelUnpaidBookingsService> _logger;
        private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(1);
        private readonly TimeSpan _holdTimeout = TimeSpan.FromMinutes(5);

        public AutoCancelUnpaidBookingsService(
            IServiceProvider serviceProvider,
            ILogger<AutoCancelUnpaidBookingsService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("AutoCancelUnpaidBookingsService started.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CancelUnpaidBookings();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in AutoCancelUnpaidBookingsService");
                }

                await Task.Delay(_checkInterval, stoppingToken);
            }

            _logger.LogInformation("AutoCancelUnpaidBookingsService stopped.");
        }

        private async Task CancelUnpaidBookings()
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var cutoffTime = DateTime.UtcNow.Subtract(_holdTimeout);

            var unpaidBookings = await context.Bookings
                .Where(b => b.Status == BookingStatus.Holding)
                .Where(b => b.CreatedDate < cutoffTime)
                .ToListAsync();

            if (unpaidBookings.Any())
            {
                foreach (var booking in unpaidBookings)
                {
                    booking.Status = BookingStatus.Cancelled;
                    _logger.LogInformation($"Auto-cancelled unpaid booking {booking.Id}");
                }

                await context.SaveChangesAsync();
                _logger.LogInformation($"Cancelled {unpaidBookings.Count} unpaid bookings");
            }
        }
    }
}
