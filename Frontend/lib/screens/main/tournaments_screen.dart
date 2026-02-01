import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<TournamentProvider>().loadTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải đấu'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _PillTabBar(controller: _tabController),
          ),
        ),
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.tournaments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final openList = provider.tournaments
              .where((t) =>
                  t.status == TournamentStatus.open ||
                  t.status == TournamentStatus.registering)
              .toList();

          final ongoingList = provider.tournaments
              .where((t) =>
                  t.status == TournamentStatus.ongoing ||
                  t.status == TournamentStatus.drawCompleted)
              .toList();

          final finishedList = provider.tournaments
              .where((t) => t.status == TournamentStatus.finished)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTournamentList(openList, header: 'Mở đăng ký'),
              _buildTournamentList(ongoingList, header: 'Đang diễn ra'),
              _buildTournamentList(finishedList, header: 'Đã kết thúc'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTournamentList(List<Tournament> tournaments,
      {required String header}) {
    if (tournaments.isEmpty) {
      return const EmptyState(
        message: 'Không có giải đấu nào',
        icon: Icons.emoji_events_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<TournamentProvider>().loadTournaments(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: tournaments.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SectionHeader(
              title: header,
              subtitle: 'Tổng ${tournaments.length} giải',
            );
          }
          final tournament = tournaments[index - 1];
          return _buildTournamentCard(tournament);
        },
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showTournamentDetail(tournament),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Icon + title + status chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TournamentIcon(status: tournament.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusChip(
                              label: tournament.status.displayName,
                              color: _getStatusColor(tournament.status),
                            ),
                            _InfoPill(
                              icon: Icons.people,
                              text: tournament.participantDisplay,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Info lines
              _buildInfoRow(
                Icons.calendar_today,
                '${DateFormat('dd/MM').format(tournament.startDate)} - ${DateFormat('dd/MM/yyyy').format(tournament.endDate)}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.sports_tennis,
                _getFormatName(tournament.format),
              ),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.08),
              ),
              const SizedBox(height: 12),

              // Fee & Prize
              Row(
                children: [
                  Expanded(
                    child: _MoneyBlock(
                      label: 'Phí tham gia',
                      value: formatter.format(tournament.entryFee),
                      valueColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MoneyBlock(
                      label: 'Tổng giải thưởng',
                      value: formatter.format(tournament.prizePool),
                      valueColor: ThemeProvider.accentColor,
                    ),
                  ),
                ],
              ),

              // CTA section
              if (tournament.canRegister && !tournament.isFull) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Đăng ký tham gia',
                    icon: Icons.add,
                    onPressed: () => _joinTournament(tournament),
                  ),
                ),
              ],

              if (tournament.isFull && tournament.canRegister) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: const Text(
                    'Đã đủ số lượng người tham gia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.78),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.open:
      case TournamentStatus.registering:
        return Colors.green;
      case TournamentStatus.drawCompleted:
        return Colors.blue;
      case TournamentStatus.ongoing:
        return ThemeProvider.accentColor;
      case TournamentStatus.finished:
        return Colors.grey;
    }
  }

  String _getFormatName(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.knockout:
        return 'Loại trực tiếp';
      case TournamentFormat.roundRobin:
        return 'Vòng tròn';
      case TournamentFormat.hybrid:
        return 'Kết hợp';
    }
  }

  Future<void> _showTournamentDetail(Tournament tournament) async {
    await context.read<TournamentProvider>().loadTournamentDetail(
          tournament.id,
        );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TournamentDetailSheet(tournament: tournament),
    );
  }

  Future<void> _joinTournament(Tournament tournament) async {
    final teamNameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng ký giải đấu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phí tham gia: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tournament.entryFee)}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: teamNameController,
              decoration: const InputDecoration(
                labelText: 'Tên đội (tùy chọn)',
                hintText: 'Nhập tên đội của bạn',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<TournamentProvider>().joinTournament(
            tournament.id,
            teamName: teamNameController.text.isNotEmpty
                ? teamNameController.text
                : null,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.read<WalletProvider>().loadBalance();
          context.read<AuthProvider>().refreshUser();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<TournamentProvider>().errorMessage ??
                    'Đăng ký thất bại',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _PillTabBar extends StatelessWidget {
  const _PillTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.onSurface.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: ThemeProvider.primaryColor,
          borderRadius: BorderRadius.circular(999),
        ),
        labelColor: Colors.white,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
        tabs: const [
          Tab(text: 'Mở đăng ký'),
          Tab(text: 'Đang diễn ra'),
          Tab(text: 'Đã kết thúc'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentIcon extends StatelessWidget {
  const _TournamentIcon({required this.status});
  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.72)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.emoji_events, color: Colors.white, size: 26),
    );
  }

  Color _statusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.open:
      case TournamentStatus.registering:
        return Colors.green;
      case TournamentStatus.drawCompleted:
        return Colors.blue;
      case TournamentStatus.ongoing:
        return ThemeProvider.accentColor;
      case TournamentStatus.finished:
        return Colors.grey;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface.withOpacity(0.72);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}

class _MoneyBlock extends StatelessWidget {
  const _MoneyBlock({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentDetailSheet extends StatelessWidget {
  final Tournament tournament;

  const _TournamentDetailSheet({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Consumer<TournamentProvider>(
            builder: (context, provider, _) {
              final detail = provider.selectedTournament;

              if (provider.isLoading || detail == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            detail.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (detail.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              detail.description!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.75),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Participants header
                          const Text(
                            'Người tham gia',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  if (detail.participants.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final participant = detail.participants[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: ThemeProvider.primaryColor,
                            child: Text(
                              participant.displayName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            participant.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: participant.partnerName != null
                              ? Text('cùng ${participant.partnerName}')
                              : null,
                          trailing: participant.seed != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ThemeProvider.accentColor
                                        .withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: ThemeProvider.accentColor
                                          .withOpacity(0.22),
                                    ),
                                  ),
                                  child: Text(
                                    '#${participant.seed}',
                                    style: TextStyle(
                                      color: ThemeProvider.accentColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                              : null,
                        );
                      }, childCount: detail.participants.length),
                    ),

                  if (detail.matches.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: const Text(
                          'Lịch thi đấu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final match = detail.matches[index];
                        return GlassCard(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Column(
                            children: [
                              if (match.roundName != null)
                                Text(
                                  match.roundName!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      match.team1Display,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: match.winningSide ==
                                                WinningSide.team1
                                            ? FontWeight.w900
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: match.status == MatchStatus.finished
                                          ? ThemeProvider.primaryColor
                                              .withOpacity(0.16)
                                          : Colors.grey.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      match.status == MatchStatus.finished
                                          ? match.scoreDisplay
                                          : DateFormat.Hm().format(match.startTime),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: match.status == MatchStatus.finished
                                            ? ThemeProvider.primaryColor
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      match.team2Display,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: match.winningSide ==
                                                WinningSide.team2
                                            ? FontWeight.w900
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }, childCount: detail.matches.length),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
