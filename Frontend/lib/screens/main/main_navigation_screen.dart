import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../home/home_screen.dart';
import 'booking_screen.dart';
import 'tournaments_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BookingScreen(),
    TournamentsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // CHỐT LỖI: init/load provider sau frame đầu để tránh notifyListeners đúng lúc build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      context.read<NotificationProvider>()
        ..init()
        ..loadUnreadCount();

      context.read<WalletProvider>().loadBalance();
      context.read<BookingProvider>().loadCourts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: _BottomNavGlass(
            currentIndex: _currentIndex,
            onChanged: (i) => setState(() => _currentIndex = i),
          ),
        ),
      ),
    );
  }
}

class _BottomNavGlass extends StatelessWidget {
  const _BottomNavGlass({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.82),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  label: 'Trang chủ',
                  isActive: currentIndex == 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  badgeCount: unread > 0 ? unread : null,
                  onTap: () => onChanged(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Đặt sân',
                  isActive: currentIndex == 1,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  onTap: () => onChanged(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Giải đấu',
                  isActive: currentIndex == 2,
                  icon: Icons.emoji_events_outlined,
                  activeIcon: Icons.emoji_events_rounded,
                  onTap: () => onChanged(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Ví',
                  isActive: currentIndex == 3,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  onTap: () => onChanged(3),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Cá nhân',
                  isActive: currentIndex == 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  onTap: () => onChanged(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.isActive,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
    this.badgeCount,
  });

  final String label;
  final bool isActive;
  final IconData icon;
  final IconData activeIcon;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    // Không phụ thuộc ThemeProvider để tránh import sai
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isActive ? activeColor.withOpacity(0.14) : Colors.transparent,
          border: isActive
              ? Border.all(color: activeColor.withOpacity(0.25))
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: isActive ? 24 : 22,
                  color: isActive ? activeColor : inactiveColor,
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        badgeCount! > 99 ? '99+' : '${badgeCount!}',
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
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
