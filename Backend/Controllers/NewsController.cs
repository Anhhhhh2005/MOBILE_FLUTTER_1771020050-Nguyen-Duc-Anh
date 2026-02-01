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
    public class NewsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public NewsController(ApplicationDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Lấy danh sách tin tức
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ApiResponse<List<NewsDto>>>> GetNews()
        {
            var news = await _context.News
                .OrderByDescending(n => n.IsPinned)
                .ThenByDescending(n => n.CreatedDate)
                .Select(n => new NewsDto
                {
                    Id = n.Id,
                    Title = n.Title,
                    Content = n.Content,
                    IsPinned = n.IsPinned,
                    ImageUrl = n.ImageUrl,
                    CreatedDate = n.CreatedDate
                })
                .ToListAsync();

            return Ok(ApiResponse<List<NewsDto>>.Ok(news));
        }

        /// <summary>
        /// Lấy chi tiết tin tức
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<ApiResponse<NewsDto>>> GetNewsItem(int id)
        {
            var news = await _context.News.FindAsync(id);

            if (news == null)
                return NotFound(ApiResponse<NewsDto>.Fail("Không tìm thấy tin tức"));

            var result = new NewsDto
            {
                Id = news.Id,
                Title = news.Title,
                Content = news.Content,
                IsPinned = news.IsPinned,
                ImageUrl = news.ImageUrl,
                CreatedDate = news.CreatedDate
            };

            return Ok(ApiResponse<NewsDto>.Ok(result));
        }
    }
}
