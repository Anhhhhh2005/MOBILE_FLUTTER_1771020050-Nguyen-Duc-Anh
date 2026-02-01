using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.DTOs;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class CourtsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public CourtsController(ApplicationDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Lấy danh sách sân
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ApiResponse<List<CourtDto>>>> GetCourts()
        {
            var courts = await _context.Courts
                .Where(c => c.IsActive)
                .Select(c => new CourtDto
                {
                    Id = c.Id,
                    Name = c.Name,
                    Description = c.Description,
                    PricePerHour = c.PricePerHour,
                    IsActive = c.IsActive
                })
                .ToListAsync();

            return Ok(ApiResponse<List<CourtDto>>.Ok(courts));
        }

        /// <summary>
        /// Lấy chi tiết sân
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<ApiResponse<CourtDto>>> GetCourt(int id)
        {
            var court = await _context.Courts.FindAsync(id);
            
            if (court == null)
                return NotFound(ApiResponse<CourtDto>.Fail("Không tìm thấy sân"));

            var result = new CourtDto
            {
                Id = court.Id,
                Name = court.Name,
                Description = court.Description,
                PricePerHour = court.PricePerHour,
                IsActive = court.IsActive
            };

            return Ok(ApiResponse<CourtDto>.Ok(result));
        }
    }
}
