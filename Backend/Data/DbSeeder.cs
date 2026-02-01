using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Models;

namespace PcmBackend.Data
{
    public static class DbSeeder
    {
        public static async Task SeedAsync(ApplicationDbContext context, UserManager<IdentityUser> userManager, RoleManager<IdentityRole> roleManager)
        {
            // Seed Roles
            await SeedRolesAsync(roleManager);

            // Seed Admin, Treasurer, Referee
            await SeedAdminUsersAsync(context, userManager);

            // Seed Courts
            await SeedCourtsAsync(context);

            // Seed Members
            await SeedMembersAsync(context, userManager);

            // Seed Tournaments
            await SeedTournamentsAsync(context);

            // Seed Transaction Categories
            await SeedTransactionCategoriesAsync(context);

            // Seed News
            await SeedNewsAsync(context);

            await context.SaveChangesAsync();
        }

        private static async Task SeedRolesAsync(RoleManager<IdentityRole> roleManager)
        {
            string[] roles = { "Admin", "Treasurer", "Referee", "Member" };

            foreach (var role in roles)
            {
                if (!await roleManager.RoleExistsAsync(role))
                {
                    await roleManager.CreateAsync(new IdentityRole(role));
                }
            }
        }

        private static async Task SeedAdminUsersAsync(ApplicationDbContext context, UserManager<IdentityUser> userManager)
        {
            // Admin
            await CreateUserWithMemberAsync(context, userManager, 
                "admin@pcm.com", "Admin@123", "Admin", 
                "Chao Mung Duc Anh", MemberTier.Diamond, 8.0, 10000000, new[] { "Admin" });

            // Treasurer
            await CreateUserWithMemberAsync(context, userManager, 
                "treasurer@pcm.com", "Treasurer@123", "Treasurer", 
                "Trần Thủ Quỹ", MemberTier.Gold, 6.5, 8000000, new[] { "Treasurer", "Member" });

            // Referee
            await CreateUserWithMemberAsync(context, userManager, 
                "referee@pcm.com", "Referee@123", "Referee", 
                "Lê Trọng Tài", MemberTier.Gold, 7.0, 5000000, new[] { "Referee", "Member" });
        }

        private static async Task SeedMembersAsync(ApplicationDbContext context, UserManager<IdentityUser> userManager)
        {
            if (await context.Members.CountAsync() >= 10)
                return;

            var members = new[]
            {
                ("member1@pcm.com", "Member@123", "Phạm Văn An", MemberTier.Standard, 3.5, 5000000m),
                ("member2@pcm.com", "Member@123", "Hoàng Thị Bình", MemberTier.Silver, 4.2, 6000000m),
                ("member3@pcm.com", "Member@123", "Vũ Minh Cường", MemberTier.Standard, 3.8, 4000000m),
                ("member4@pcm.com", "Member@123", "Đặng Thu Dung", MemberTier.Gold, 5.5, 8000000m),
                ("member5@pcm.com", "Member@123", "Ngô Quốc Em", MemberTier.Standard, 3.2, 3000000m),
                ("member6@pcm.com", "Member@123", "Bùi Hoàng Phong", MemberTier.Silver, 4.5, 7000000m),
                ("member7@pcm.com", "Member@123", "Trịnh Lan Giang", MemberTier.Standard, 3.0, 2500000m),
                ("member8@pcm.com", "Member@123", "Lý Quang Hải", MemberTier.Diamond, 6.8, 10000000m),
                ("member9@pcm.com", "Member@123", "Đinh Thùy Linh", MemberTier.Silver, 4.0, 5500000m),
                ("member10@pcm.com", "Member@123", "Cao Minh Khoa", MemberTier.Standard, 3.3, 4500000m),
                ("member11@pcm.com", "Member@123", "Phan Thanh Long", MemberTier.Gold, 5.2, 7500000m),
                ("member12@pcm.com", "Member@123", "Đỗ Ngọc Mai", MemberTier.Standard, 2.8, 3500000m),
                ("member13@pcm.com", "Member@123", "Hồ Anh Ngọc", MemberTier.Silver, 4.8, 6500000m),
                ("member14@pcm.com", "Member@123", "Tô Văn Phúc", MemberTier.Standard, 3.6, 4000000m),
                ("member15@pcm.com", "Member@123", "Lương Thị Quỳnh", MemberTier.Gold, 5.8, 9000000m),
                ("member16@pcm.com", "Member@123", "Mai Đức Sơn", MemberTier.Standard, 3.4, 3800000m),
                ("member17@pcm.com", "Member@123", "Võ Thị Trang", MemberTier.Silver, 4.3, 5200000m),
            };

            foreach (var (email, password, name, tier, rank, balance) in members)
            {
                await CreateUserWithMemberAsync(context, userManager, 
                    email, password, "Member", name, tier, rank, balance, new[] { "Member" });
            }
        }

        private static async Task CreateUserWithMemberAsync(
            ApplicationDbContext context,
            UserManager<IdentityUser> userManager,
            string email,
            string password,
            string role,
            string fullName,
            MemberTier tier,
            double rankLevel,
            decimal walletBalance,
            string[] roles)
        {
            var existingUser = await userManager.FindByEmailAsync(email);
            if (existingUser != null)
                return;

            var user = new IdentityUser
            {
                UserName = email,
                Email = email,
                EmailConfirmed = true
            };

            var result = await userManager.CreateAsync(user, password);
            if (result.Succeeded)
            {
                await userManager.AddToRolesAsync(user, roles);

                var member = new Member
                {
                    UserId = user.Id,
                    FullName = fullName,
                    JoinDate = DateTime.UtcNow.AddMonths(-new Random().Next(1, 24)),
                    RankLevel = rankLevel,
                    WalletBalance = walletBalance,
                    Tier = tier,
                    TotalSpent = tier switch
                    {
                        MemberTier.Diamond => 25000000,
                        MemberTier.Gold => 15000000,
                        MemberTier.Silver => 7500000,
                        _ => 2500000
                    },
                    IsActive = true
                };

                context.Members.Add(member);
            }
        }

        private static async Task SeedCourtsAsync(ApplicationDbContext context)
        {
            if (await context.Courts.AnyAsync())
                return;

            var courts = new[]
            {
                new Court { Name = "Sân 1 - Indoor", Description = "Sân trong nhà, có máy lạnh", PricePerHour = 150000, IsActive = true },
                new Court { Name = "Sân 2 - Indoor", Description = "Sân trong nhà, có máy lạnh", PricePerHour = 150000, IsActive = true },
                new Court { Name = "Sân 3 - Outdoor", Description = "Sân ngoài trời, có mái che", PricePerHour = 100000, IsActive = true },
                new Court { Name = "Sân 4 - Outdoor", Description = "Sân ngoài trời, có mái che", PricePerHour = 100000, IsActive = true },
                new Court { Name = "Sân VIP", Description = "Sân VIP, có phòng đợi riêng", PricePerHour = 250000, IsActive = true },
            };

            context.Courts.AddRange(courts);
        }

        private static async Task SeedTournamentsAsync(ApplicationDbContext context)
        {
            if (await context.Tournaments.AnyAsync())
                return;

            var tournaments = new[]
            {
                new Tournament
                {
                    Name = "Summer Open 2026",
                    Description = "Giải đấu mùa hè 2026 - Đã kết thúc",
                    StartDate = new DateTime(2026, 6, 1),
                    EndDate = new DateTime(2026, 6, 15),
                    Format = TournamentFormat.Knockout,
                    EntryFee = 200000,
                    PrizePool = 5000000,
                    Status = TournamentStatus.Finished,
                    Settings = "{\"maxParticipants\":16,\"numberOfGroups\":0}"
                },
                new Tournament
                {
                    Name = "Winter Cup 2026",
                    Description = "Giải đấu mùa đông 2026 - Đang mở đăng ký",
                    StartDate = new DateTime(2026, 12, 1),
                    EndDate = new DateTime(2026, 12, 15),
                    Format = TournamentFormat.Knockout,
                    EntryFee = 300000,
                    PrizePool = 10000000,
                    Status = TournamentStatus.Registering,
                    Settings = "{\"maxParticipants\":32,\"numberOfGroups\":0}"
                },
                new Tournament
                {
                    Name = "Spring League 2027",
                    Description = "Giải vòng tròn tính điểm mùa xuân 2027",
                    StartDate = new DateTime(2027, 3, 1),
                    EndDate = new DateTime(2027, 3, 30),
                    Format = TournamentFormat.RoundRobin,
                    EntryFee = 150000,
                    PrizePool = 3000000,
                    Status = TournamentStatus.Open,
                    Settings = "{\"maxParticipants\":8,\"numberOfGroups\":2}"
                }
            };

            context.Tournaments.AddRange(tournaments);
        }

        private static async Task SeedNewsAsync(ApplicationDbContext context)
        {
            if (await context.News.AnyAsync())
                return;

            var news = new[]
            {
                new News
                {
                    Title = "Chào mừng đến với CLB Vợt Thủ Phố Núi!",
                    Content = "Chào mừng các thành viên mới! CLB hoạt động dựa trên tinh thần 'Vui - Khỏe - Có Thưởng'. Hãy tham gia các giải đấu và hoạt động của CLB nhé!",
                    IsPinned = true,
                    CreatedDate = DateTime.UtcNow.AddDays(-30)
                },
                new News
                {
                    Title = "Kết quả Summer Open 2026",
                    Content = "Chúc mừng các vận động viên đã hoàn thành giải Summer Open 2026. Xin chúc mừng nhà vô địch!",
                    IsPinned = false,
                    CreatedDate = DateTime.UtcNow.AddDays(-15)
                },
                new News
                {
                    Title = "Winter Cup 2026 - Mở đăng ký!",
                    Content = "Giải Winter Cup 2026 chính thức mở đăng ký! Phí tham gia: 300,000 VND. Tổng giải thưởng: 10,000,000 VND. Đăng ký ngay!",
                    IsPinned = true,
                    CreatedDate = DateTime.UtcNow.AddDays(-5)
                }
            };

            context.News.AddRange(news);
        }

        private static async Task SeedTransactionCategoriesAsync(ApplicationDbContext context)
        {
            if (await context.TransactionCategories.AnyAsync())
                return;

            var categories = new[]
            {
                new TransactionCategory
                {
                    Name = "Phí đặt sân",
                    Type = TransactionCategoryType.Income,
                    Description = "Thu từ đặt sân",
                    IsActive = true
                },
                new TransactionCategory
                {
                    Name = "Phí tham gia giải đấu",
                    Type = TransactionCategoryType.Income,
                    Description = "Entry fee từ giải đấu",
                    IsActive = true
                },
                new TransactionCategory
                {
                    Name = "Nạp tiền vào ví",
                    Type = TransactionCategoryType.Income,
                    Description = "Thành viên nạp tiền",
                    IsActive = true
                },
                new TransactionCategory
                {
                    Name = "Giải thưởng",
                    Type = TransactionCategoryType.Expense,
                    Description = "Chi trả giải thưởng",
                    IsActive = true
                },
                new TransactionCategory
                {
                    Name = "Hoàn tiền",
                    Type = TransactionCategoryType.Expense,
                    Description = "Hoàn tiền hủy booking",
                    IsActive = true
                }
            };

            context.TransactionCategories.AddRange(categories);
        }
    }
}
