import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<WalletProvider>();
    provider.loadBalance();
    provider.loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        actions: [
          IconButton(
            tooltip: 'Nạp tiền',
            onPressed: _showDepositDialog,
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () async {
              final wallet = context.read<WalletProvider>();
              await wallet.loadBalance();
              await wallet.loadTransactions();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await wallet.loadBalance();
              await wallet.loadTransactions();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBalanceCard(wallet.balance, wallet.isLoading),
                        const SizedBox(height: 14),
                        _buildActionButtons(),
                        const SizedBox(height: 18),
                        _buildTransactionHeader(wallet),
                      ],
                    ),
                  ),
                ),

                if (wallet.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (wallet.transactions.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      message: 'Chưa có giao dịch nào',
                      icon: Icons.receipt_long_outlined,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 18),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final transaction = wallet.transactions[index];
                        return _buildTransactionItem(transaction);
                      }, childCount: wallet.transactions.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance, bool isLoading) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ThemeProvider.primaryColor, ThemeProvider.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ThemeProvider.primaryColor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Số dư khả dụng',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLoading ? Icons.sync : Icons.verified,
                      size: 14,
                      color: Colors.white.withOpacity(0.95),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLoading ? 'Đang cập nhật' : 'Cập nhật',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Tổng số dư',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatter.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add,
            title: 'Nạp tiền',
            subtitle: 'Gửi yêu cầu nạp',
            color: ThemeProvider.primaryColor,
            onTap: _showDepositDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.receipt_long,
            title: 'Lịch sử',
            subtitle: 'Xem giao dịch',
            color: ThemeProvider.secondaryColor,
            onTap: () => context.read<WalletProvider>().loadTransactions(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHeader(WalletProvider wallet) {
    final formatter = NumberFormat.compact(locale: 'vi');
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Lịch sử giao dịch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07),
            ),
          ),
          child: Text(
            '${formatter.format(wallet.transactions.length)} mục',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: () {
            // UI only (filter in future)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng lọc sẽ bổ sung sau')),
            );
          },
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Lọc'),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final isPositive = transaction.isPositive;
    final mainColor = isPositive ? Colors.green : Colors.red;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // icon bubble
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: mainColor.withOpacity(0.18)),
              ),
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: mainColor,
              ),
            ),
            const SizedBox(width: 12),

            // content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.type.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusChip(
                        text: _getStatusText(transaction.status),
                        color: _getStatusColor(transaction.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (transaction.description != null)
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdDate),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? '+' : '-'}${formatter.format(transaction.amount.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: mainColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Icons.arrow_downward;
      case TransactionType.withdraw:
        return Icons.arrow_upward;
      case TransactionType.payment:
        return Icons.shopping_cart;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.reward:
        return Icons.emoji_events;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.rejected:
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'Thành công';
      case TransactionStatus.pending:
        return 'Chờ duyệt';
      case TransactionStatus.rejected:
        return 'Từ chối';
      case TransactionStatus.failed:
        return 'Thất bại';
    }
  }

  void _showDepositDialog() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nạp tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                hintText: 'Nhập số tiền cần nạp',
                prefixText: '₫ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'VD: Nạp qua chuyển khoản',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeProvider.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ThemeProvider.accentColor.withOpacity(0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ThemeProvider.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yêu cầu nạp tiền sẽ được Admin duyệt trong vòng 24h',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeProvider.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          Consumer<WalletProvider>(
            builder: (context, wallet, _) {
              return ElevatedButton(
                onPressed: wallet.isLoading
                    ? null
                    : () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập số tiền hợp lệ'),
                            ),
                          );
                          return;
                        }

                        final success = await wallet.deposit(
                          amount,
                          description: descriptionController.text.isNotEmpty
                              ? descriptionController.text
                              : null,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Yêu cầu nạp tiền đã được gửi!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            wallet.loadTransactions();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(wallet.errorMessage ?? 'Có lỗi xảy ra'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: wallet.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gửi yêu cầu'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
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
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
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
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
