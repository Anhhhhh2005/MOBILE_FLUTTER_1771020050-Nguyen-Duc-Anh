import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  Court? _selectedCourt;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);

  static const _radius = 20.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingProvider = context.read<BookingProvider>();
    await bookingProvider.loadCourts();
    await _loadCalendar();

    if (bookingProvider.courts.isNotEmpty) {
      setState(() {
        _selectedCourt = bookingProvider.courts.first;
      });
    }
  }

  Future<void> _loadCalendar() async {
    final from = _focusedDay.subtract(const Duration(days: 7));
    final to = _focusedDay.add(const Duration(days: 14));
    await context.read<BookingProvider>().loadCalendar(from, to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<BookingProvider>(
        builder: (context, booking, _) {
          return LoadingOverlay(
            isLoading: booking.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(
                    title: 'Chọn ngày',
                    subtitle: 'Chọn ngày để xem lịch sân',
                    icon: Icons.calendar_month_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildCalendar(),
                  const SizedBox(height: 18),

                  _buildSectionHeader(
                    title: 'Chọn sân',
                    subtitle: 'Chọn sân phù hợp với bạn',
                    icon: Icons.sports_tennis_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildCourtSelector(booking.courts),
                  const SizedBox(height: 18),

                  _buildSectionHeader(
                    title: 'Chọn giờ',
                    subtitle: 'Chọn khung giờ đặt sân',
                    icon: Icons.schedule_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildTimeSelector(),
                  const SizedBox(height: 18),

                  _buildSectionHeader(
                    title: 'Tóm tắt',
                    subtitle: 'Kiểm tra trước khi đặt',
                    icon: Icons.receipt_long_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildBookingSummary(),
                  const SizedBox(height: 18),

                  _buildSectionHeader(
                    title: 'Lịch đã đặt',
                    subtitle: 'Các slot đã được đặt trong ngày',
                    icon: Icons.event_busy_rounded,
                    trailing: _selectedCourt == null
                        ? null
                        : _buildMiniPill(
                            text: _selectedCourt!.name,
                            icon: Icons.place_rounded,
                          ),
                  ),
                  const SizedBox(height: 10),
                  _buildBookingSlots(booking.calendarSlots),
                  const SizedBox(height: 22),

                  PrimaryButton(
                    text: 'Đặt sân',
                    icon: Icons.check_rounded,
                    onPressed: _createBooking,
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      titleSpacing: 16,
      centerTitle: false,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đặt sân',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          SizedBox(height: 2),
          Text(
            'Pickleball booking',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.list_alt_rounded),
          onPressed: _showMyBookings,
          tooltip: 'Booking của tôi',
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  // ===== UI helpers =====
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildMiniPill({required String text, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===== Calendar =====
  Widget _buildCalendar() {
    return GlassCard(
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 30)),
        lastDay: DateTime.now().add(const Duration(days: 90)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadCalendar();
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadCalendar();
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: ThemeProvider.primaryColor.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: ThemeProvider.primaryColor,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
          markerDecoration: BoxDecoration(
            color: ThemeProvider.accentColor,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
        ),
      ),
    );
  }

  // ===== Court selector =====
  Widget _buildCourtSelector(List<Court> courts) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danh sách sân',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (courts.isEmpty)
            Text(
              'Không có sân nào',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: courts.map((court) {
                final isSelected = _selectedCourt?.id == court.id;

                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() {
                      _selectedCourt = court;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ThemeProvider.primaryColor.withOpacity(0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? ThemeProvider.primaryColor.withOpacity(0.45)
                            : Colors.grey.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 16,
                          color: isSelected
                              ? ThemeProvider.primaryColor
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          court.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color:
                                isSelected ? ThemeProvider.primaryColor : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          if (_selectedCourt != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeProvider.secondaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeProvider.secondaryColor.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_rounded,
                      color: ThemeProvider.secondaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Giá: ${formatter.format(_selectedCourt!.pricePerHour)}/giờ',
                      style: TextStyle(
                        color: ThemeProvider.secondaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== Time selector =====
  Widget _buildTimeSelector() {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: _buildTimeButton(
              label: 'Từ',
              time: _startTime,
              icon: Icons.login_rounded,
              onChanged: (time) => setState(() => _startTime = time),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildTimeButton(
              label: 'Đến',
              time: _endTime,
              icon: Icons.logout_rounded,
              onChanged: (time) => setState(() => _endTime = time),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required Function(TimeOfDay) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time.format(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Summary =====
  Widget _buildBookingSummary() {
    if (_selectedCourt == null) return const SizedBox();

    final startDateTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _endTime.hour,
      _endTime.minute,
    );

    final hours = endDateTime.difference(startDateTime).inMinutes / 60;
    final totalPrice = hours * _selectedCourt!.pricePerHour;

    final money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
        .format(totalPrice);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(
            label: 'Ngày',
            value: DateFormat('dd/MM/yyyy').format(_selectedDay),
            icon: Icons.event_rounded,
          ),
          const SizedBox(height: 10),
          _summaryRow(
            label: 'Sân',
            value: _selectedCourt!.name,
            icon: Icons.place_rounded,
          ),
          const SizedBox(height: 10),
          _summaryRow(
            label: 'Thời gian',
            value: '${hours.toStringAsFixed(1)} giờ',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.black.withOpacity(0.06), height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tiền',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              Text(
                money,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: ThemeProvider.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: ThemeProvider.primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: ThemeProvider.primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  // ===== Slots in day =====
  Widget _buildBookingSlots(List<CalendarSlot> slots) {
    final daySlots = slots
        .where(
          (s) =>
              s.startTime.year == _selectedDay.year &&
              s.startTime.month == _selectedDay.month &&
              s.startTime.day == _selectedDay.day &&
              (_selectedCourt == null || s.courtId == _selectedCourt!.id),
        )
        .toList();

    if (daySlots.isEmpty) {
      return GlassCard(
        child: const EmptyState(
          message: 'Chưa có ai đặt trong ngày này',
          icon: Icons.event_available_rounded,
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Slot đã đặt',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...daySlots.map((slot) {
            final isMine = slot.isMyBooking;
            final bg = isMine
                ? ThemeProvider.primaryColor.withOpacity(0.12)
                : Colors.red.withOpacity(0.10);
            final border = isMine
                ? ThemeProvider.primaryColor.withOpacity(0.25)
                : Colors.red.withOpacity(0.25);
            final textColor = isMine ? ThemeProvider.primaryColor : Colors.red;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 18, color: textColor),
                  const SizedBox(width: 10),
                  Text(
                    '${DateFormat.Hm().format(slot.startTime)} - ${DateFormat.Hm().format(slot.endTime)}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: textColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      isMine ? 'Của bạn' : (slot.bookedByName ?? 'Đã đặt'),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===== Create booking (logic unchanged) =====
  Future<void> _createBooking() async {
    if (_selectedCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sân')),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu')),
      );
      return;
    }

    final success = await context.read<BookingProvider>().createBooking(
          _selectedCourt!.id,
          startDateTime,
          endDateTime,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt sân thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCalendar();
      context.read<WalletProvider>().loadBalance();
      context.read<AuthProvider>().refreshUser();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<BookingProvider>().errorMessage ?? 'Đặt sân thất bại',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===== My bookings bottom sheet =====
  void _showMyBookings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        context.read<BookingProvider>().loadMyBookings();

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.55,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.list_alt_rounded),
                        const SizedBox(width: 10),
                        const Text(
                          'Booking của tôi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Consumer<BookingProvider>(
                      builder: (context, booking, _) {
                        if (booking.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (booking.myBookings.isEmpty) {
                          return const EmptyState(
                            message: 'Bạn chưa có booking nào',
                            icon: Icons.calendar_today_outlined,
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: booking.myBookings.length,
                          itemBuilder: (context, index) {
                            final b = booking.myBookings[index];

                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          b.courtName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      _statusChip(b.status),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${DateFormat('dd/MM/yyyy HH:mm').format(b.startTime)} - ${DateFormat.Hm().format(b.endTime)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payments_rounded,
                                        size: 16,
                                        color: ThemeProvider.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'vi_VN',
                                          symbol: '₫',
                                        ).format(b.totalPrice),
                                        style: TextStyle(
                                          color: ThemeProvider.primaryColor,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (b.status == BookingStatus.confirmed) ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _cancelBooking(b.id),
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          'Hủy booking',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusChip(BookingStatus status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pendingPayment:
        return Colors.orange;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }

  Future<void> _cancelBooking(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text(
          'Bạn có chắc muốn hủy booking này? Tiền hoàn trả sẽ tùy thuộc vào thời gian hủy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hủy booking',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<BookingProvider>().cancelBooking(id);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy booking'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCalendar();
        context.read<WalletProvider>().loadBalance();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hủy booking thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
