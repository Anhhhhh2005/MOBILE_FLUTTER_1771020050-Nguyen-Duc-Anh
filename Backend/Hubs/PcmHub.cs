using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace PcmBackend.Hubs
{
    /// <summary>
    /// SignalR Hub cho real-time notifications và updates
    /// </summary>
    [Authorize]
    public class PcmHub : Hub
    {
        /// <summary>
        /// Khi client kết nối
        /// </summary>
        public override async Task OnConnectedAsync()
        {
            var userId = Context.UserIdentifier;
            if (!string.IsNullOrEmpty(userId))
            {
                // User có thể join group của chính mình để nhận notifications
                await Groups.AddToGroupAsync(Context.ConnectionId, $"User_{userId}");
            }
            await base.OnConnectedAsync();
        }

        /// <summary>
        /// Khi client ngắt kết nối
        /// </summary>
        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.UserIdentifier;
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"User_{userId}");
            }
            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Join vào group xem trận đấu cụ thể
        /// </summary>
        public async Task JoinMatchGroup(int matchId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"Match_{matchId}");
        }

        /// <summary>
        /// Rời khỏi group xem trận đấu
        /// </summary>
        public async Task LeaveMatchGroup(int matchId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Match_{matchId}");
        }

        /// <summary>
        /// Join vào group xem giải đấu
        /// </summary>
        public async Task JoinTournamentGroup(int tournamentId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"Tournament_{tournamentId}");
        }

        /// <summary>
        /// Rời khỏi group xem giải đấu
        /// </summary>
        public async Task LeaveTournamentGroup(int tournamentId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Tournament_{tournamentId}");
        }
    }

    /// <summary>
    /// Extension methods để gửi notifications dễ dàng hơn
    /// </summary>
    public static class PcmHubExtensions
    {
        /// <summary>
        /// Gửi notification đến user cụ thể
        /// </summary>
        public static async Task SendNotificationToUser(this IHubContext<PcmHub> hubContext, 
            string userId, string message, string type)
        {
            await hubContext.Clients.User(userId).SendAsync("ReceiveNotification", message, type);
        }

        /// <summary>
        /// Gửi notification đến group user
        /// </summary>
        public static async Task SendNotificationToUserGroup(this IHubContext<PcmHub> hubContext,
            string userId, string message, string type)
        {
            await hubContext.Clients.Group($"User_{userId}").SendAsync("ReceiveNotification", message, type);
        }

        /// <summary>
        /// Broadcast cập nhật calendar đến tất cả clients
        /// </summary>
        public static async Task BroadcastCalendarUpdate(this IHubContext<PcmHub> hubContext, string message)
        {
            await hubContext.Clients.All.SendAsync("UpdateCalendar", message);
        }

        /// <summary>
        /// Gửi cập nhật tỉ số trận đấu đến group đang xem
        /// </summary>
        public static async Task SendMatchScoreUpdate(this IHubContext<PcmHub> hubContext,
            int matchId, int score1, int score2)
        {
            await hubContext.Clients.Group($"Match_{matchId}").SendAsync("UpdateMatchScore", matchId, score1, score2);
            // Also broadcast to all
            await hubContext.Clients.All.SendAsync("UpdateMatchScore", matchId, score1, score2);
        }

        /// <summary>
        /// Gửi cập nhật giải đấu đến group đang xem
        /// </summary>
        public static async Task SendTournamentUpdate(this IHubContext<PcmHub> hubContext,
            int tournamentId, string message)
        {
            await hubContext.Clients.Group($"Tournament_{tournamentId}").SendAsync("UpdateTournament", tournamentId, message);
        }
    }
}
