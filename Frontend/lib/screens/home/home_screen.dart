import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../services/services.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<News> _news = [];
  List<Match> _upcomingMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final newsResponse = await apiService.getNews();
      _news = newsResponse.map((e) => News.fromJson(e)).take(5).toList();

      final matchesResponse = await apiService.getUpcomingMatches();
      _upcomingMatches =
          matchesResponse.map((e) => Match.fromJson(e)).take(3).toList();
    } catch (e) {
      // Ignore errors
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(user),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeCard(user),
                  const SizedBox(height: 16),

                  // Admin Dashboard Button
                  if (user != null &&
                      (user.roles.contains('Admin') ||
                          user.roles.contains('Treasurer')))
                    _buildAdminDashboardButton(),

                  const SizedBox(height: 20),
                  _buildStatsRow(user),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Trận đấu sắp tới'),
                  const SizedBox(height: 12),
                  _buildUpcomingMatches(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Tin tức CLB'),
                  const SizedBox(height: 12),
                  _buildNewsList(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // UI: AppBar (brand by Duc Anh)
  // =========================
  Widget _buildAppBar(UserInfo? user) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PCM Mobile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              user?.fullName != null && user!.fullName.isNotEmpty
                  ? 'Xin chào, ${user.fullName}'
                  : 'Pickleball Club',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ThemeProvider.primaryColor,
                ThemeProvider.secondaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sports_tennis, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'by Duc Anh',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notif, _) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Navigate to notifications
                  },
                ),
                if (notif.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        '${notif.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // =========================
  // UI: Welcome Card (thêm chip số dư)
  // =========================
  Widget _buildWelcomeCard(UserInfo? user) {
    if (user == null) return const SizedBox();

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: ThemeProvider.primaryColor,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'D',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Xin chào,',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ThemeProvider.primaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 14,
                            color: ThemeProvider.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatter.format(user.walletBalance),
                            style: TextStyle(
                              color: ThemeProvider.primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ThemeProvider.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(user.tier.icon,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            user.tier.displayName,
                            style: TextStyle(
                              color: ThemeProvider.accentColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'DUPR ${user.rankLevel.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // UI: Admin Dashboard Button
  // =========================
  Widget _buildAdminDashboardButton() {
    return GlassCard(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ThemeProvider.primaryColor.withOpacity(0.10),
                ThemeProvider.secondaryColor.withOpacity(0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Quản lý tài chính & thống kê CLB',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // UI: Stats Row
  // =========================
  Widget _buildStatsRow(UserInfo? user) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Số dư ví',
            value: formatter.format(user?.walletBalance ?? 0),
            icon: Icons.account_balance_wallet,
            color: ThemeProvider.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Hạng điểm DUPR',
            value: user?.rankLevel.toStringAsFixed(1) ?? '0.0',
            icon: Icons.trending_up,
            color: ThemeProvider.accentColor,
          ),
        ),
      ],
    );
  }

  // =========================
  // UI: Section Title (pill button)
  // =========================
  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        TextButton(
          onPressed: () {
            // Navigate to see all
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: ThemeProvider.primaryColor.withOpacity(0.10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text(
            'Xem tất cả',
            style: TextStyle(
              color: ThemeProvider.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // UI: Upcoming Matches
  // =========================
  Widget _buildUpcomingMatches() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upcomingMatches.isEmpty) {
      return GlassCard(
        child: EmptyState(
          message: 'Không có trận đấu sắp tới',
          icon: Icons.sports_tennis,
        ),
      );
    }

    return Column(
      children:
          _upcomingMatches.map((match) => _buildMatchCard(match)).toList(),
    );
  }

  Widget _buildMatchCard(Match match) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (match.tournamentName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ThemeProvider.secondaryColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                match.tournamentName!,
                style: TextStyle(
                  color: ThemeProvider.secondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.team1Display,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ThemeProvider.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Text(
                  match.team2Display,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(match.startTime),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // UI: News List
  // =========================
  Widget _buildNewsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_news.isEmpty) {
      return GlassCard(
        child: EmptyState(
          message: 'Không có tin tức',
          icon: Icons.article_outlined,
        ),
      );
    }

    return Column(children: _news.map((news) => _buildNewsCard(news)).toList());
  }

  Widget _buildNewsCard(News news) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (news.isPinned)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeProvider.accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.push_pin, size: 12, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Ghim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            news.content,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd/MM/yyyy').format(news.createdDate),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
