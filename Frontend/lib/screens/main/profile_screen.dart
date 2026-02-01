import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../services/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  MemberProfile? _profile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await apiService.getMemberProfile(auth.user!.memberId);
      if (!mounted) return;
      setState(() {
        _profile = MemberProfile.fromJson(response);
      });
    } catch (e) {
      // Ignore
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(theme),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileHeader(user),
                  const SizedBox(height: 14),
                  _buildQuickStatsRow(),
                  const SizedBox(height: 14),
                  _buildTierCard(user),
                  const SizedBox(height: 14),
                  _buildMenuItems(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeProvider theme) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      title: const Text('Cá nhân'),
      actions: [
        IconButton(
          icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => theme.toggleTheme(),
          tooltip: 'Đổi giao diện',
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _showLogoutDialog,
          tooltip: 'Đăng xuất',
        ),
      ],
    );
  }

  // =========================
  // HEADER
  // =========================
  Widget _buildProfileHeader(UserInfo? user) {
    if (user == null) return const SizedBox();

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Cover
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeProvider.primaryColor,
                  ThemeProvider.secondaryColor,
                ],
              ),
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _RolePills(user: user),
              ),
            ),
          ),

          // Avatar + Info
          Transform.translate(
            offset: const Offset(0, -38),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      _AvatarCircle(user: user),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () {
                            // giữ nguyên logic: hiện bạn chưa có màn edit
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ThemeProvider.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _ChipPill(
                        text: '${user.tier.icon}  ${user.tier.displayName}',
                        bg: ThemeProvider.accentColor.withOpacity(0.16),
                        fg: ThemeProvider.accentColor,
                      ),
                      _ChipPill(
                        text: 'DUPR ${user.rankLevel.toStringAsFixed(1)}',
                        bg: ThemeProvider.primaryColor.withOpacity(0.16),
                        fg: ThemeProvider.primaryColor,
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: -18),
        ],
      ),
    );
  }

  // =========================
  // STATS
  // =========================
  Widget _buildQuickStatsRow() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final p = _profile;
    final totalMatches = p?.totalMatches ?? 0;
    final totalWins = p?.totalWins ?? 0;
    final winRate = (p != null && p.totalMatches > 0) ? p.winRate : 0;

    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            title: 'Trận đấu',
            value: '$totalMatches',
            icon: Icons.sports_tennis,
            color: ThemeProvider.primaryColor,
            subtitle: 'Tổng số trận',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            title: 'Chiến thắng',
            value: '$totalWins',
            icon: Icons.emoji_events,
            color: ThemeProvider.accentColor,
            subtitle: totalMatches > 0
                ? '${winRate.toStringAsFixed(0)}% win rate'
                : 'Chưa có dữ liệu',
          ),
        ),
      ],
    );
  }

  // =========================
  // TIER CARD (giữ nguyên tính toán)
  // =========================
  Widget _buildTierCard(UserInfo? user) {
    if (user == null) return const SizedBox();

    final tierColors = {
      MemberTier.standard: Colors.grey,
      MemberTier.silver: Colors.blueGrey,
      MemberTier.gold: ThemeProvider.accentColor,
      MemberTier.diamond: Colors.cyan,
    };

    final tierThresholds = {
      MemberTier.silver: 5000000.0,
      MemberTier.gold: 20000000.0,
      MemberTier.diamond: 100000000.0,
    };

    final currentSpent = _profile?.totalSpent ?? 0;
    MemberTier nextTier;
    double targetAmount = 0;

    switch (user.tier) {
      case MemberTier.standard:
        nextTier = MemberTier.silver;
        targetAmount = tierThresholds[MemberTier.silver]!;
      case MemberTier.silver:
        nextTier = MemberTier.gold;
        targetAmount = tierThresholds[MemberTier.gold]!;
      case MemberTier.gold:
        nextTier = MemberTier.diamond;
        targetAmount = tierThresholds[MemberTier.diamond]!;
      case MemberTier.diamond:
        nextTier = MemberTier.diamond;
        targetAmount = currentSpent;
    }

    final progress =
        targetAmount > 0 ? (currentSpent / targetAmount).clamp(0, 1) : 1.0;

    final moneyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (tierColors[user.tier] ?? Colors.grey).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.card_membership,
                  color: tierColors[user.tier],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Hạng thành viên',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              if (user.tier != MemberTier.diamond)
                _ChipPill(
                  text: 'Next: ${nextTier.displayName}',
                  bg: ThemeProvider.secondaryColor.withOpacity(0.14),
                  fg: ThemeProvider.secondaryColor,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.tier.displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: tierColors[user.tier],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tổng chi tiêu: ${moneyFmt.format(currentSpent)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Text(user.tier.icon, style: const TextStyle(fontSize: 42)),
            ],
          ),
          if (user.tier != MemberTier.diamond) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: Colors.grey.withOpacity(0.22),
                valueColor: AlwaysStoppedAnimation(tierColors[nextTier]),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Còn ${moneyFmt.format((targetAmount - currentSpent).clamp(0, double.infinity))} để lên ${nextTier.displayName}',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================
  // MENU
  // =========================
  Widget _buildMenuItems() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.person_outline,
            title: 'Chỉnh sửa hồ sơ',
            subtitle: 'Cập nhật tên, ảnh đại diện',
            onTap: () {},
          ),
          _buildDivider(),
          _MenuTile(
            icon: Icons.history,
            title: 'Lịch sử thi đấu',
            subtitle: 'Kết quả & thống kê cá nhân',
            onTap: () {},
          ),
          _buildDivider(),
          _MenuTile(
            icon: Icons.notifications_outlined,
            title: 'Cài đặt thông báo',
            subtitle: 'Nhắc lịch, booking, giải đấu',
            onTap: () {},
          ),
          _buildDivider(),
          _MenuTile(
            icon: Icons.help_outline,
            title: 'Trợ giúp & Phản hồi',
            subtitle: 'Gửi góp ý hoặc báo lỗi',
            onTap: () {},
          ),
          _buildDivider(),
          _MenuTile(
            icon: Icons.info_outline,
            title: 'Về ứng dụng',
            subtitle: 'Thông tin phiên bản & tác giả',
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 16,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
    );
  }

  // =========================
  // DIALOGS (FIX CONTEXT)
  // =========================
  void _showLogoutDialog() {
    final rootContext = context;

    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              rootContext.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final rootContext = context;

    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vợt Thủ Phố Núi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeProvider.primaryColor,
                    ThemeProvider.secondaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.sports_tennis,
                size: 42,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pickleball Club Management',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Phiên bản 1.0.0'),
            const SizedBox(height: 10),
            Text(
              'Made by Duc Anh',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ThemeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '© 2026',
              style: TextStyle(
                color: Theme.of(rootContext)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.65),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

// =========================
// SMALL WIDGETS
// =========================

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.user});
  final UserInfo user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [ThemeProvider.primaryColor, ThemeProvider.secondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeProvider.primaryColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: user.avatarUrl != null
              ? Image.network(user.avatarUrl!, fit: BoxFit.cover)
              : Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _RolePills extends StatelessWidget {
  const _RolePills({required this.user});
  final UserInfo user;

  @override
  Widget build(BuildContext context) {
    final roles = user.roles.where((r) => r != 'Member').toList();
    if (roles.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 8,
      children: roles.map((r) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Text(
            r,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.text,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ThemeProvider.primaryColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: ThemeProvider.primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w900, color: fg),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: fg.withOpacity(0.6)),
      ),
      trailing: Icon(Icons.chevron_right, color: fg.withOpacity(0.35)),
    );
  }
}
