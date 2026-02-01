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
    public class TournamentsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public TournamentsController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        /// <summary>
        /// Lấy danh sách giải đấu
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ApiResponse<List<TournamentDto>>>> GetTournaments(
            [FromQuery] TournamentStatus? status = null)
        {
            var query = _context.Tournaments.AsQueryable();

            if (status.HasValue)
                query = query.Where(t => t.Status == status.Value);

            var tournaments = await query
                .OrderByDescending(t => t.StartDate)
                .Select(t => new TournamentDto
                {
                    Id = t.Id,
                    Name = t.Name,
                    Description = t.Description,
                    StartDate = t.StartDate,
                    EndDate = t.EndDate,
                    Format = t.Format,
                    EntryFee = t.EntryFee,
                    PrizePool = t.PrizePool,
                    Status = t.Status,
                    Settings = t.Settings,
                    MaxParticipants = t.GetMaxParticipants(),
                    CurrentParticipants = t.Participants.Count
                })
                .ToListAsync();

            return Ok(ApiResponse<List<TournamentDto>>.Ok(tournaments));
        }

        /// <summary>
        /// Lấy chi tiết giải đấu
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<ApiResponse<TournamentDetailDto>>> GetTournament(int id)
        {
            var tournament = await _context.Tournaments
                .Include(t => t.Participants)
                    .ThenInclude(p => p.Member)
                .Include(t => t.Participants)
                    .ThenInclude(p => p.Partner)
                .Include(t => t.Matches)
                    .ThenInclude(m => m.Team1_Player1)
                .Include(t => t.Matches)
                    .ThenInclude(m => m.Team2_Player1)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tournament == null)
                return NotFound(ApiResponse<TournamentDetailDto>.Fail("Không tìm thấy giải đấu"));

            var result = new TournamentDetailDto
            {
                Id = tournament.Id,
                Name = tournament.Name,
                Description = tournament.Description,
                StartDate = tournament.StartDate,
                EndDate = tournament.EndDate,
                Format = tournament.Format,
                EntryFee = tournament.EntryFee,
                PrizePool = tournament.PrizePool,
                Status = tournament.Status,
                Settings = tournament.Settings,
                MaxParticipants = tournament.GetMaxParticipants(),
                CurrentParticipants = tournament.Participants.Count,
                Participants = tournament.Participants.Select(p => new ParticipantDto
                {
                    Id = p.Id,
                    MemberId = p.MemberId,
                    MemberName = p.Member?.FullName ?? "",
                    TeamName = p.TeamName,
                    PartnerId = p.PartnerId,
                    PartnerName = p.Partner?.FullName,
                    Seed = p.Seed,
                    PaymentStatus = p.PaymentStatus
                }).ToList(),
                Matches = tournament.Matches
                    .OrderBy(m => m.RoundName)
                    .ThenBy(m => m.Date)
                    .Select(m => new MatchDto
                    {
                        Id = m.Id,
                        TournamentId = m.TournamentId,
                        RoundName = m.RoundName,
                        Date = m.Date,
                        StartTime = m.StartTime,
                        Team1_Player1Id = m.Team1_Player1Id,
                        Team1_Player1Name = m.Team1_Player1?.FullName,
                        Team2_Player1Id = m.Team2_Player1Id,
                        Team2_Player1Name = m.Team2_Player1?.FullName,
                        Score1 = m.Score1,
                        Score2 = m.Score2,
                        Details = m.Details,
                        WinningSide = m.WinningSide,
                        Status = m.Status
                    }).ToList()
            };

            return Ok(ApiResponse<TournamentDetailDto>.Ok(result));
        }

        /// <summary>
        /// Tạo giải đấu mới (Admin only)
        /// </summary>
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<ApiResponse<TournamentDto>>> CreateTournament([FromBody] CreateTournamentDto model)
        {
            var tournament = new Tournament
            {
                Name = model.Name,
                Description = model.Description,
                StartDate = model.StartDate,
                EndDate = model.EndDate,
                Format = model.Format,
                EntryFee = model.EntryFee,
                PrizePool = model.PrizePool,
                Settings = model.Settings ?? $"{{\"maxParticipants\":{model.MaxParticipants}}}",
                Status = TournamentStatus.Open,
                CreatedDate = DateTime.UtcNow
            };

            _context.Tournaments.Add(tournament);
            await _context.SaveChangesAsync();

            var result = new TournamentDto
            {
                Id = tournament.Id,
                Name = tournament.Name,
                Description = tournament.Description,
                StartDate = tournament.StartDate,
                EndDate = tournament.EndDate,
                Format = tournament.Format,
                EntryFee = tournament.EntryFee,
                PrizePool = tournament.PrizePool,
                Status = tournament.Status,
                Settings = tournament.Settings,
                MaxParticipants = tournament.GetMaxParticipants(),
                CurrentParticipants = 0
            };

            return Ok(ApiResponse<TournamentDto>.Ok(result, "Tạo giải đấu thành công"));
        }

        /// <summary>
        /// Đăng ký tham gia giải đấu
        /// </summary>
        [HttpPost("{id}/join")]
        public async Task<ActionResult<ApiResponse<ParticipantDto>>> JoinTournament(int id, [FromBody] JoinTournamentDto? model = null)
        {
            var memberId = GetCurrentMemberId();
            var member = await _context.Members.FindAsync(memberId);

            if (member == null)
                return NotFound(ApiResponse<ParticipantDto>.Fail("Không tìm thấy thành viên"));

            var tournament = await _context.Tournaments
                .Include(t => t.Participants)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tournament == null)
                return NotFound(ApiResponse<ParticipantDto>.Fail("Không tìm thấy giải đấu"));

            if (tournament.Status != TournamentStatus.Open && tournament.Status != TournamentStatus.Registering)
                return BadRequest(ApiResponse<ParticipantDto>.Fail("Giải đấu không còn mở đăng ký"));

            if (tournament.Participants.Count >= tournament.GetMaxParticipants())
                return BadRequest(ApiResponse<ParticipantDto>.Fail("Giải đấu đã đủ số lượng tham gia"));

            if (tournament.Participants.Any(p => p.MemberId == memberId))
                return BadRequest(ApiResponse<ParticipantDto>.Fail("Bạn đã đăng ký giải đấu này rồi"));

            // Check wallet balance
            if (member.WalletBalance < tournament.EntryFee)
                return BadRequest(ApiResponse<ParticipantDto>.Fail($"Số dư ví không đủ. Cần: {tournament.EntryFee:N0} VND"));

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Create participant
                var participant = new TournamentParticipant
                {
                    TournamentId = id,
                    MemberId = memberId,
                    TeamName = model?.TeamName,
                    PartnerId = model?.PartnerId,
                    PaymentStatus = true,
                    RegisteredDate = DateTime.UtcNow
                };

                _context.TournamentParticipants.Add(participant);

                // Deduct entry fee
                member.WalletBalance -= tournament.EntryFee;
                member.TotalSpent += tournament.EntryFee;

                // Create wallet transaction
                var walletTransaction = new WalletTransaction
                {
                    MemberId = memberId,
                    Amount = -tournament.EntryFee,
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    RelatedId = $"Tournament:{id}",
                    Description = $"Phí tham gia giải {tournament.Name}",
                    CreatedDate = DateTime.UtcNow
                };
                _context.WalletTransactions.Add(walletTransaction);

                // Update tournament status if needed
                if (tournament.Status == TournamentStatus.Open)
                    tournament.Status = TournamentStatus.Registering;

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                var result = new ParticipantDto
                {
                    Id = participant.Id,
                    MemberId = participant.MemberId,
                    MemberName = member.FullName,
                    TeamName = participant.TeamName,
                    PartnerId = participant.PartnerId,
                    PaymentStatus = participant.PaymentStatus
                };

                return Ok(ApiResponse<ParticipantDto>.Ok(result, $"Đăng ký thành công! Số dư còn lại: {member.WalletBalance:N0} VND"));
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ApiResponse<ParticipantDto>.Fail($"Lỗi: {ex.Message}"));
            }
        }

        /// <summary>
        /// Tự động sinh lịch thi đấu (Admin only)
        /// </summary>
        [HttpPost("{id}/generate-schedule")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<ApiResponse<List<MatchDto>>>> GenerateSchedule(int id)
        {
            var tournament = await _context.Tournaments
                .Include(t => t.Participants)
                    .ThenInclude(p => p.Member)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tournament == null)
                return NotFound(ApiResponse<List<MatchDto>>.Fail("Không tìm thấy giải đấu"));

            if (tournament.Participants.Count < 2)
                return BadRequest(ApiResponse<List<MatchDto>>.Fail("Cần ít nhất 2 người tham gia"));

            // Clear existing matches
            var existingMatches = await _context.Matches.Where(m => m.TournamentId == id).ToListAsync();
            _context.Matches.RemoveRange(existingMatches);

            var participants = tournament.Participants.OrderBy(p => p.Seed ?? int.MaxValue).ToList();
            var matches = new List<Match>();

            if (tournament.Format == TournamentFormat.Knockout)
            {
                matches = GenerateKnockoutBracket(tournament, participants);
            }
            else if (tournament.Format == TournamentFormat.RoundRobin)
            {
                matches = GenerateRoundRobinSchedule(tournament, participants);
            }

            _context.Matches.AddRange(matches);
            tournament.Status = TournamentStatus.DrawCompleted;

            await _context.SaveChangesAsync();

            var result = matches.Select(m => new MatchDto
            {
                Id = m.Id,
                TournamentId = m.TournamentId,
                RoundName = m.RoundName,
                Date = m.Date,
                StartTime = m.StartTime,
                Team1_Player1Id = m.Team1_Player1Id,
                Team1_Player1Name = participants.FirstOrDefault(p => p.MemberId == m.Team1_Player1Id)?.Member?.FullName,
                Team2_Player1Id = m.Team2_Player1Id,
                Team2_Player1Name = participants.FirstOrDefault(p => p.MemberId == m.Team2_Player1Id)?.Member?.FullName,
                Score1 = m.Score1,
                Score2 = m.Score2,
                Status = m.Status
            }).ToList();

            return Ok(ApiResponse<List<MatchDto>>.Ok(result, "Đã sinh lịch thi đấu thành công"));
        }

        private List<Match> GenerateKnockoutBracket(Tournament tournament, List<TournamentParticipant> participants)
        {
            var matches = new List<Match>();
            var playerIds = participants.Select(p => p.MemberId).ToList();
            
            // Pad to power of 2
            var bracketSize = 1;
            while (bracketSize < playerIds.Count) bracketSize *= 2;

            var rounds = (int)Math.Log2(bracketSize);
            var roundNames = new[] { "Final", "Semi Final", "Quarter Final", "Round of 16", "Round of 32" };

            var currentDate = tournament.StartDate;
            var matchIndex = 0;

            // First round
            for (int i = 0; i < bracketSize / 2; i++)
            {
                var player1Id = i < playerIds.Count ? playerIds[i] : (int?)null;
                var player2Id = (bracketSize - 1 - i) < playerIds.Count ? playerIds[bracketSize - 1 - i] : (int?)null;

                if (player1Id == null && player2Id == null) continue;

                var match = new Match
                {
                    TournamentId = tournament.Id,
                    RoundName = rounds > 4 ? $"Round {rounds}" : roundNames[Math.Min(rounds - 1, roundNames.Length - 1)],
                    Date = currentDate,
                    StartTime = currentDate.AddHours(9 + (matchIndex % 4) * 2),
                    Team1_Player1Id = player1Id,
                    Team2_Player1Id = player2Id,
                    Status = MatchStatus.Scheduled,
                    IsRanked = true
                };

                matches.Add(match);
                matchIndex++;
            }

            return matches;
        }

        private List<Match> GenerateRoundRobinSchedule(Tournament tournament, List<TournamentParticipant> participants)
        {
            var matches = new List<Match>();
            var playerIds = participants.Select(p => p.MemberId).ToList();
            var currentDate = tournament.StartDate;
            var matchIndex = 0;

            for (int i = 0; i < playerIds.Count; i++)
            {
                for (int j = i + 1; j < playerIds.Count; j++)
                {
                    var match = new Match
                    {
                        TournamentId = tournament.Id,
                        RoundName = "Group Stage",
                        Date = currentDate.AddDays(matchIndex / 4),
                        StartTime = currentDate.AddDays(matchIndex / 4).AddHours(9 + (matchIndex % 4) * 2),
                        Team1_Player1Id = playerIds[i],
                        Team2_Player1Id = playerIds[j],
                        Status = MatchStatus.Scheduled,
                        IsRanked = true
                    };

                    matches.Add(match);
                    matchIndex++;
                }
            }

            return matches;
        }

        private int GetCurrentMemberId()
        {
            var memberIdClaim = User.FindFirst("MemberId")?.Value;
            return int.TryParse(memberIdClaim, out var id) ? id : 0;
        }
    }
}
