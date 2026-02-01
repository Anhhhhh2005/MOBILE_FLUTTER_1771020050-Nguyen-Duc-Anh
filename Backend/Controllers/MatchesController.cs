using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.DTOs;
using PcmBackend.Hubs;
using PcmBackend.Models;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class MatchesController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public MatchesController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        /// <summary>
        /// Lấy chi tiết trận đấu
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<ApiResponse<MatchDto>>> GetMatch(int id)
        {
            var match = await _context.Matches
                .Include(m => m.Tournament)
                .Include(m => m.Team1_Player1)
                .Include(m => m.Team1_Player2)
                .Include(m => m.Team2_Player1)
                .Include(m => m.Team2_Player2)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (match == null)
                return NotFound(ApiResponse<MatchDto>.Fail("Không tìm thấy trận đấu"));

            var result = new MatchDto
            {
                Id = match.Id,
                TournamentId = match.TournamentId,
                TournamentName = match.Tournament?.Name,
                RoundName = match.RoundName,
                Date = match.Date,
                StartTime = match.StartTime,
                Team1_Player1Id = match.Team1_Player1Id,
                Team1_Player1Name = match.Team1_Player1?.FullName,
                Team1_Player2Id = match.Team1_Player2Id,
                Team1_Player2Name = match.Team1_Player2?.FullName,
                Team2_Player1Id = match.Team2_Player1Id,
                Team2_Player1Name = match.Team2_Player1?.FullName,
                Team2_Player2Id = match.Team2_Player2Id,
                Team2_Player2Name = match.Team2_Player2?.FullName,
                Score1 = match.Score1,
                Score2 = match.Score2,
                Details = match.Details,
                WinningSide = match.WinningSide,
                Status = match.Status
            };

            return Ok(ApiResponse<MatchDto>.Ok(result));
        }

        /// <summary>
        /// Lấy danh sách trận đấu sắp tới
        /// </summary>
        [HttpGet("upcoming")]
        public async Task<ActionResult<ApiResponse<List<MatchDto>>>> GetUpcomingMatches()
        {
            var memberId = GetCurrentMemberId();

            var matches = await _context.Matches
                .Include(m => m.Tournament)
                .Include(m => m.Team1_Player1)
                .Include(m => m.Team2_Player1)
                .Where(m => m.Status == MatchStatus.Scheduled)
                .Where(m => m.Date >= DateTime.UtcNow.Date)
                .Where(m => m.Team1_Player1Id == memberId || m.Team1_Player2Id == memberId ||
                           m.Team2_Player1Id == memberId || m.Team2_Player2Id == memberId)
                .OrderBy(m => m.Date)
                .Take(10)
                .Select(m => new MatchDto
                {
                    Id = m.Id,
                    TournamentId = m.TournamentId,
                    TournamentName = m.Tournament != null ? m.Tournament.Name : null,
                    RoundName = m.RoundName,
                    Date = m.Date,
                    StartTime = m.StartTime,
                    Team1_Player1Id = m.Team1_Player1Id,
                    Team1_Player1Name = m.Team1_Player1 != null ? m.Team1_Player1.FullName : null,
                    Team2_Player1Id = m.Team2_Player1Id,
                    Team2_Player1Name = m.Team2_Player1 != null ? m.Team2_Player1.FullName : null,
                    Status = m.Status
                })
                .ToListAsync();

            return Ok(ApiResponse<List<MatchDto>>.Ok(matches));
        }

        /// <summary>
        /// Cập nhật kết quả trận đấu (Referee/Admin)
        /// </summary>
        [HttpPost("{id}/result")]
        [Authorize(Roles = "Admin,Referee")]
        public async Task<ActionResult<ApiResponse<MatchDto>>> UpdateResult(int id, [FromBody] UpdateMatchResultDto model)
        {
            var match = await _context.Matches
                .Include(m => m.Tournament)
                .Include(m => m.Team1_Player1)
                .Include(m => m.Team1_Player2)
                .Include(m => m.Team2_Player1)
                .Include(m => m.Team2_Player2)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (match == null)
                return NotFound(ApiResponse<MatchDto>.Fail("Không tìm thấy trận đấu"));

            if (match.Status == MatchStatus.Finished)
                return BadRequest(ApiResponse<MatchDto>.Fail("Trận đấu đã kết thúc"));

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                match.Score1 = model.Score1;
                match.Score2 = model.Score2;
                match.Details = model.Details;
                match.WinningSide = model.WinningSide;
                match.Status = MatchStatus.Finished;

                // Update DUPR ranks if ranked match
                if (match.IsRanked)
                {
                    await UpdatePlayerRanks(match, model.WinningSide);
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Broadcast match result via SignalR
                await _hubContext.Clients.All.SendAsync("UpdateMatchScore", match.Id, match.Score1, match.Score2);

                // Notify players
                var playerIds = new[] { match.Team1_Player1Id, match.Team1_Player2Id, match.Team2_Player1Id, match.Team2_Player2Id }
                    .Where(id => id.HasValue)
                    .Select(id => id!.Value)
                    .ToList();

                foreach (var playerId in playerIds)
                {
                    var player = await _context.Members.FindAsync(playerId);
                    if (player != null)
                    {
                        var isWinner = (model.WinningSide == WinningSide.Team1 && (playerId == match.Team1_Player1Id || playerId == match.Team1_Player2Id)) ||
                                      (model.WinningSide == WinningSide.Team2 && (playerId == match.Team2_Player1Id || playerId == match.Team2_Player2Id));

                        var notification = new Notification
                        {
                            ReceiverId = playerId,
                            Message = isWinner 
                                ? $"Chúc mừng! Bạn đã thắng trận đấu {match.Score1}-{match.Score2}"
                                : $"Trận đấu kết thúc: {match.Score1}-{match.Score2}",
                            Type = isWinner ? NotificationType.Success : NotificationType.Info,
                            LinkUrl = $"/matches/{match.Id}",
                            CreatedDate = DateTime.UtcNow
                        };
                        _context.Notifications.Add(notification);
                    }
                }
                await _context.SaveChangesAsync();

                var result = new MatchDto
                {
                    Id = match.Id,
                    TournamentId = match.TournamentId,
                    TournamentName = match.Tournament?.Name,
                    RoundName = match.RoundName,
                    Date = match.Date,
                    StartTime = match.StartTime,
                    Team1_Player1Id = match.Team1_Player1Id,
                    Team1_Player1Name = match.Team1_Player1?.FullName,
                    Team2_Player1Id = match.Team2_Player1Id,
                    Team2_Player1Name = match.Team2_Player1?.FullName,
                    Score1 = match.Score1,
                    Score2 = match.Score2,
                    Details = match.Details,
                    WinningSide = match.WinningSide,
                    Status = match.Status
                };

                return Ok(ApiResponse<MatchDto>.Ok(result, "Đã cập nhật kết quả trận đấu"));
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ApiResponse<MatchDto>.Fail($"Lỗi: {ex.Message}"));
            }
        }

        private async Task UpdatePlayerRanks(Match match, WinningSide winningSide)
        {
            // Simple DUPR-like rating adjustment
            var winners = new List<int?>();
            var losers = new List<int?>();

            if (winningSide == WinningSide.Team1)
            {
                winners.AddRange(new[] { match.Team1_Player1Id, match.Team1_Player2Id });
                losers.AddRange(new[] { match.Team2_Player1Id, match.Team2_Player2Id });
            }
            else
            {
                winners.AddRange(new[] { match.Team2_Player1Id, match.Team2_Player2Id });
                losers.AddRange(new[] { match.Team1_Player1Id, match.Team1_Player2Id });
            }

            foreach (var winnerId in winners.Where(id => id.HasValue))
            {
                var winner = await _context.Members.FindAsync(winnerId!.Value);
                if (winner != null)
                {
                    winner.RankLevel = Math.Min(8.0, winner.RankLevel + 0.05);
                }
            }

            foreach (var loserId in losers.Where(id => id.HasValue))
            {
                var loser = await _context.Members.FindAsync(loserId!.Value);
                if (loser != null)
                {
                    loser.RankLevel = Math.Max(2.0, loser.RankLevel - 0.03);
                }
            }
        }

        private int GetCurrentMemberId()
        {
            var memberIdClaim = User.FindFirst("MemberId")?.Value;
            return int.TryParse(memberIdClaim, out var id) ? id : 0;
        }
    }
}
