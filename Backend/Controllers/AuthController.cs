using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using PcmBackend.Data;
using PcmBackend.DTOs;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<IdentityUser> _userManager;
        private readonly SignInManager<IdentityUser> _signInManager;
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(
            UserManager<IdentityUser> userManager,
            SignInManager<IdentityUser> signInManager,
            ApplicationDbContext context,
            IConfiguration configuration)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _context = context;
            _configuration = configuration;
        }

        /// <summary>
        /// Đăng nhập
        /// </summary>
        [HttpPost("login")]
        public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Login([FromBody] LoginDto model)
        {
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
                return BadRequest(ApiResponse<AuthResponseDto>.Fail("Email hoặc mật khẩu không đúng"));

            var result = await _signInManager.CheckPasswordSignInAsync(user, model.Password, false);
            if (!result.Succeeded)
                return BadRequest(ApiResponse<AuthResponseDto>.Fail("Email hoặc mật khẩu không đúng"));

            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == user.Id);
            if (member == null || !member.IsActive)
                return BadRequest(ApiResponse<AuthResponseDto>.Fail("Tài khoản không tồn tại hoặc đã bị khóa"));

            var roles = await _userManager.GetRolesAsync(user);
            var token = GenerateJwtToken(user, member, roles.ToList());

            var response = new AuthResponseDto
            {
                Token = token,
                Expiration = DateTime.UtcNow.AddMinutes(Convert.ToDouble(_configuration["Jwt:ExpireMinutes"] ?? "1440")),
                User = new UserInfoDto
                {
                    MemberId = member.Id,
                    UserId = user.Id,
                    Email = user.Email ?? "",
                    FullName = member.FullName,
                    AvatarUrl = member.AvatarUrl,
                    RankLevel = member.RankLevel,
                    Tier = member.Tier,
                    WalletBalance = member.WalletBalance,
                    Roles = roles.ToList()
                }
            };

            return Ok(ApiResponse<AuthResponseDto>.Ok(response, "Đăng nhập thành công"));
        }

        /// <summary>
        /// Đăng ký tài khoản mới
        /// </summary>
        [HttpPost("register")]
        public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Register([FromBody] RegisterDto model)
        {
            var existingUser = await _userManager.FindByEmailAsync(model.Email);
            if (existingUser != null)
                return BadRequest(ApiResponse<AuthResponseDto>.Fail("Email đã được sử dụng"));

            var user = new IdentityUser
            {
                UserName = model.Email,
                Email = model.Email,
                EmailConfirmed = true
            };

            var result = await _userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return BadRequest(ApiResponse<AuthResponseDto>.Fail(errors));
            }

            await _userManager.AddToRoleAsync(user, "Member");

            var member = new Models.Member
            {
                UserId = user.Id,
                FullName = model.FullName,
                JoinDate = DateTime.UtcNow,
                RankLevel = 3.0,
                WalletBalance = 0,
                Tier = Models.MemberTier.Standard,
                IsActive = true
            };

            _context.Members.Add(member);
            await _context.SaveChangesAsync();

            var roles = new List<string> { "Member" };
            var token = GenerateJwtToken(user, member, roles);

            var response = new AuthResponseDto
            {
                Token = token,
                Expiration = DateTime.UtcNow.AddMinutes(Convert.ToDouble(_configuration["Jwt:ExpireMinutes"] ?? "1440")),
                User = new UserInfoDto
                {
                    MemberId = member.Id,
                    UserId = user.Id,
                    Email = user.Email ?? "",
                    FullName = member.FullName,
                    AvatarUrl = member.AvatarUrl,
                    RankLevel = member.RankLevel,
                    Tier = member.Tier,
                    WalletBalance = member.WalletBalance,
                    Roles = roles
                }
            };

            return Ok(ApiResponse<AuthResponseDto>.Ok(response, "Đăng ký thành công"));
        }

        /// <summary>
        /// Lấy thông tin user hiện tại
        /// </summary>
        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult<ApiResponse<UserInfoDto>>> GetCurrentUser()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(ApiResponse<UserInfoDto>.Fail("Không tìm thấy thông tin user"));

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
                return NotFound(ApiResponse<UserInfoDto>.Fail("User không tồn tại"));

            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null)
                return NotFound(ApiResponse<UserInfoDto>.Fail("Member không tồn tại"));

            var roles = await _userManager.GetRolesAsync(user);

            var userInfo = new UserInfoDto
            {
                MemberId = member.Id,
                UserId = user.Id,
                Email = user.Email ?? "",
                FullName = member.FullName,
                AvatarUrl = member.AvatarUrl,
                RankLevel = member.RankLevel,
                Tier = member.Tier,
                WalletBalance = member.WalletBalance,
                Roles = roles.ToList()
            };

            return Ok(ApiResponse<UserInfoDto>.Ok(userInfo));
        }

        private string GenerateJwtToken(IdentityUser user, Models.Member member, List<string> roles)
        {
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id),
                new(ClaimTypes.Email, user.Email ?? ""),
                new(ClaimTypes.Name, member.FullName),
                new("MemberId", member.Id.ToString()),
            };

            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"] ?? "DefaultSecretKey123456789012345678901234"));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var expires = DateTime.UtcNow.AddMinutes(Convert.ToDouble(_configuration["Jwt:ExpireMinutes"] ?? "1440"));

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: expires,
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
