using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.DTOs;
using PcmBackend.Models;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class MembersController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public MembersController(ApplicationDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Lấy danh sách thành viên
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ApiResponse<PaginatedResult<MemberDto>>>> GetMembers(
            [FromQuery] string? search = null,
            [FromQuery] MemberTier? tier = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var query = _context.Members.Where(m => m.IsActive);

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(m => m.FullName.Contains(search));
            }

            if (tier.HasValue)
            {
                query = query.Where(m => m.Tier == tier.Value);
            }

            var totalCount = await query.CountAsync();
            var items = await query
                .OrderByDescending(m => m.RankLevel)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(m => new MemberDto
                {
                    Id = m.Id,
                    FullName = m.FullName,
                    JoinDate = m.JoinDate,
                    RankLevel = m.RankLevel,
                    Tier = m.Tier,
                    WalletBalance = m.WalletBalance,
                    AvatarUrl = m.AvatarUrl,
                    IsActive = m.IsActive
                })
                .ToListAsync();

            var result = new PaginatedResult<MemberDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };

            return Ok(ApiResponse<PaginatedResult<MemberDto>>.Ok(result));
        }

        /// <summary>
        /// Lấy thông tin chi tiết thành viên
        /// </summary>
        [HttpGet("{id}/profile")]
        public async Task<ActionResult<ApiResponse<MemberProfileDto>>> GetMemberProfile(int id)
        {
            var member = await _context.Members
                .FirstOrDefaultAsync(m => m.Id == id);

            if (member == null)
                return NotFound(ApiResponse<MemberProfileDto>.Fail("Không tìm thấy thành viên"));

            // Count matches and wins
            var matches = await _context.Matches
                .Where(m => m.Team1_Player1Id == id || m.Team1_Player2Id == id ||
                           m.Team2_Player1Id == id || m.Team2_Player2Id == id)
                .ToListAsync();

            var totalWins = matches.Count(m =>
                (m.WinningSide == WinningSide.Team1 && (m.Team1_Player1Id == id || m.Team1_Player2Id == id)) ||
                (m.WinningSide == WinningSide.Team2 && (m.Team2_Player1Id == id || m.Team2_Player2Id == id)));

            var totalTournaments = await _context.TournamentParticipants
                .Where(tp => tp.MemberId == id)
                .CountAsync();

            // Get recent matches
            var recentMatches = await _context.Matches
                .Include(m => m.Tournament)
                .Include(m => m.Team1_Player1)
                .Include(m => m.Team1_Player2)
                .Include(m => m.Team2_Player1)
                .Include(m => m.Team2_Player2)
                .Where(m => m.Team1_Player1Id == id || m.Team1_Player2Id == id ||
                           m.Team2_Player1Id == id || m.Team2_Player2Id == id)
                .OrderByDescending(m => m.Date)
                .Take(5)
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
                    Team1_Player2Id = m.Team1_Player2Id,
                    Team1_Player2Name = m.Team1_Player2 != null ? m.Team1_Player2.FullName : null,
                    Team2_Player1Id = m.Team2_Player1Id,
                    Team2_Player1Name = m.Team2_Player1 != null ? m.Team2_Player1.FullName : null,
                    Team2_Player2Id = m.Team2_Player2Id,
                    Team2_Player2Name = m.Team2_Player2 != null ? m.Team2_Player2.FullName : null,
                    Score1 = m.Score1,
                    Score2 = m.Score2,
                    Details = m.Details,
                    WinningSide = m.WinningSide,
                    Status = m.Status
                })
                .ToListAsync();

            var profile = new MemberProfileDto
            {
                Id = member.Id,
                FullName = member.FullName,
                JoinDate = member.JoinDate,
                RankLevel = member.RankLevel,
                Tier = member.Tier,
                WalletBalance = member.WalletBalance,
                AvatarUrl = member.AvatarUrl,
                IsActive = member.IsActive,
                TotalSpent = member.TotalSpent,
                TotalMatches = matches.Count,
                TotalWins = totalWins,
                TotalTournaments = totalTournaments,
                RecentMatches = recentMatches
            };

            return Ok(ApiResponse<MemberProfileDto>.Ok(profile));
        }

        /// <summary>
        /// Cập nhật thông tin cá nhân
        /// </summary>
        [HttpPut("{id}")]
        public async Task<ActionResult<ApiResponse<MemberDto>>> UpdateMember(int id, [FromBody] UpdateMemberDto model)
        {
            var currentMemberId = GetCurrentMemberId();
            if (currentMemberId != id && !User.IsInRole("Admin"))
                return Forbid();

            var member = await _context.Members.FindAsync(id);
            if (member == null)
                return NotFound(ApiResponse<MemberDto>.Fail("Không tìm thấy thành viên"));

            if (!string.IsNullOrEmpty(model.FullName))
                member.FullName = model.FullName;

            if (model.AvatarUrl != null)
                member.AvatarUrl = model.AvatarUrl;

            await _context.SaveChangesAsync();

            var result = new MemberDto
            {
                Id = member.Id,
                FullName = member.FullName,
                JoinDate = member.JoinDate,
                RankLevel = member.RankLevel,
                Tier = member.Tier,
                WalletBalance = member.WalletBalance,
                AvatarUrl = member.AvatarUrl,
                IsActive = member.IsActive
            };

            return Ok(ApiResponse<MemberDto>.Ok(result, "Cập nhật thành công"));
        }

        private int GetCurrentMemberId()
        {
            var memberIdClaim = User.FindFirst("MemberId")?.Value;
            return int.TryParse(memberIdClaim, out var id) ? id : 0;
        }
    }
}
