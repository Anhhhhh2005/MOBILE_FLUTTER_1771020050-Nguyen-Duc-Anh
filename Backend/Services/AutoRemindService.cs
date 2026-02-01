using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Hubs;
using PcmBackend.Models;

namespace PcmBackend.Services
{
    /// <summary>
    /// Background service tự động gửi nhắc nhở trước các trận đấu
    /// </summary>
    public class AutoRemindService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<AutoRemindService> _logger;
        private readonly TimeSpan _checkInterval = TimeSpan.FromHours(1);

        public AutoRemindService(
            IServiceProvider serviceProvider,
            ILogger<AutoRemindService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("AutoRemindService started.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await SendReminders();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in AutoRemindService");
                }

                await Task.Delay(_checkInterval, stoppingToken);
            }

            _logger.LogInformation("AutoRemindService stopped.");
        }

        private async Task SendReminders()
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<PcmHub>>();

            var tomorrow = DateTime.UtcNow.Date.AddDays(1);
            var dayAfterTomorrow = tomorrow.AddDays(1);

            // Nhắc nhở trận đấu ngày mai
            var upcomingMatches = await context.Matches
                .Include(m => m.Tournament)
                .Where(m => m.Status == MatchStatus.Scheduled)
                .Where(m => m.Date >= tomorrow && m.Date < dayAfterTomorrow)
                .ToListAsync();

            foreach (var match in upcomingMatches)
            {
                var playerIds = new[] { match.Team1_Player1Id, match.Team1_Player2Id, match.Team2_Player1Id, match.Team2_Player2Id }
                    .Where(id => id.HasValue)
                    .Select(id => id!.Value)
                    .Distinct()
                    .ToList();

                foreach (var playerId in playerIds)
                {
                    // Kiểm tra xem đã gửi nhắc nhở chưa
                    var existingNotification = await context.Notifications
                        .AnyAsync(n => n.ReceiverId == playerId && 
                                      n.LinkUrl == $"/matches/{match.Id}" &&
                                      n.CreatedDate.Date == DateTime.UtcNow.Date);

                    if (!existingNotification)
                    {
                        var notification = new Notification
                        {
                            ReceiverId = playerId,
                            Message = $"Nhắc nhở: Bạn có trận đấu vào ngày mai ({match.Date:dd/MM/yyyy HH:mm})" +
                                     (match.Tournament != null ? $" - Giải {match.Tournament.Name}" : ""),
                            Type = NotificationType.Info,
                            LinkUrl = $"/matches/{match.Id}",
                            CreatedDate = DateTime.UtcNow
                        };

                        context.Notifications.Add(notification);

                        // Gửi notification real-time
                        var member = await context.Members.FindAsync(playerId);
                        if (member != null)
                        {
                            await hubContext.SendNotificationToUser(member.UserId, notification.Message, "Info");
                        }
                    }
                }
            }

            // Nhắc nhở booking ngày mai
            var upcomingBookings = await context.Bookings
                .Include(b => b.Court)
                .Include(b => b.Member)
                .Where(b => b.Status == BookingStatus.Confirmed)
                .Where(b => b.StartTime >= tomorrow && b.StartTime < dayAfterTomorrow)
                .ToListAsync();

            foreach (var booking in upcomingBookings)
            {
                // Kiểm tra xem đã gửi nhắc nhở chưa
                var existingNotification = await context.Notifications
                    .AnyAsync(n => n.ReceiverId == booking.MemberId &&
                                  n.LinkUrl == $"/bookings/{booking.Id}" &&
                                  n.CreatedDate.Date == DateTime.UtcNow.Date);

                if (!existingNotification)
                {
                    var notification = new Notification
                    {
                        ReceiverId = booking.MemberId,
                        Message = $"Nhắc nhở: Bạn có lịch đặt sân {booking.Court?.Name} vào ngày mai ({booking.StartTime:dd/MM/yyyy HH:mm})",
                        Type = NotificationType.Info,
                        LinkUrl = $"/bookings/{booking.Id}",
                        CreatedDate = DateTime.UtcNow
                    };

                    context.Notifications.Add(notification);

                    // Gửi notification real-time
                    if (booking.Member != null)
                    {
                        await hubContext.SendNotificationToUser(booking.Member.UserId, notification.Message, "Info");
                    }
                }
            }

            await context.SaveChangesAsync();
            _logger.LogInformation($"Sent reminders for {upcomingMatches.Count} matches and {upcomingBookings.Count} bookings");
        }
    }
}
