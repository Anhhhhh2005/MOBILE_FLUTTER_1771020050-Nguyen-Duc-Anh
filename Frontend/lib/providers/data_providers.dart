import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/services.dart';

class WalletProvider extends ChangeNotifier {
  double _balance = 0;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  double get balance => _balance;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _disposed = false;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadBalance() async {
    try {
      _balance = await apiService.getWalletBalance();
      _safeNotify();
    } catch (_) {
      // Ignore
    }
  }

  Future<void> loadTransactions({int? type}) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await apiService.getWalletTransactions(type: type);
      final items = (response['items'] as List? ?? const []);
      _transactions =
          items.map((e) => WalletTransaction.fromJson(e)).toList();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Không thể tải lịch sử giao dịch';
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<bool> deposit(double amount, {String? description}) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await apiService.deposit(amount, description: description);

      // Nên refresh lại số dư + lịch sử để UI đúng ngay khi nạp xong
      await loadBalance();
      await loadTransactions();

      _isLoading = false;
      _safeNotify();
      return true;
    } catch (_) {
      _errorMessage = 'Không thể gửi yêu cầu nạp tiền';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }
}

class BookingProvider extends ChangeNotifier {
  List<Court> _courts = [];
  List<CalendarSlot> _calendarSlots = [];
  List<Booking> _myBookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Court> get courts => _courts;
  List<CalendarSlot> get calendarSlots => _calendarSlots;
  List<Booking> get myBookings => _myBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _disposed = false;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadCourts() async {
    try {
      final response = await apiService.getCourts();
      _courts = response.map((e) => Court.fromJson(e)).toList();
      _safeNotify();
    } catch (_) {
      // Ignore
    }
  }

  Future<void> loadCalendar(DateTime from, DateTime to) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await apiService.getCalendar(from, to);
      _calendarSlots = response.map((e) => CalendarSlot.fromJson(e)).toList();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Không thể tải lịch đặt sân';
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadMyBookings({BookingStatus? status}) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await apiService.getMyBookings(status: status?.index);
      _myBookings = response.map((e) => Booking.fromJson(e)).toList();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Không thể tải danh sách booking';
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<bool> createBooking(
    int courtId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await apiService.createBooking(courtId, startTime, endTime);

      // loadMyBookings đã tự set loading/notify rồi, nên ở đây chỉ cần await
      await loadMyBookings();

      _isLoading = false;
      _safeNotify();
      return true;
    } catch (_) {
      _errorMessage = 'Không thể đặt sân';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<bool> cancelBooking(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await apiService.cancelBooking(id);
      await loadMyBookings();
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (_) {
      _errorMessage = 'Không thể hủy booking';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }
}

class TournamentProvider extends ChangeNotifier {
  List<Tournament> _tournaments = [];
  TournamentDetail? _selectedTournament;
  bool _isLoading = false;
  String? _errorMessage;

  List<Tournament> get tournaments => _tournaments;
  TournamentDetail? get selectedTournament => _selectedTournament;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _disposed = false;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadTournaments({TournamentStatus? status}) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await apiService.getTournaments(status: status?.index);
      _tournaments = response.map((e) => Tournament.fromJson(e)).toList();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Không thể tải danh sách giải đấu';
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadTournamentDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await apiService.getTournament(id);
      _selectedTournament = TournamentDetail.fromJson(response);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Không thể tải chi tiết giải đấu';
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<bool> joinTournament(
    int id, {
    String? teamName,
    int? partnerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await apiService.joinTournament(
        id,
        teamName: teamName,
        partnerId: partnerId,
      );
      await loadTournamentDetail(id);

      _isLoading = false;
      _safeNotify();
      return true;
    } catch (_) {
      _errorMessage = 'Không thể đăng ký giải đấu';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  StreamSubscription? _sub;
  bool _inited = false;
  bool _disposed = false;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  void init() {
    if (_inited) return;
    _inited = true;

    _sub = signalRService.notifications.listen((event) {
      // Nếu provider đã dispose mà stream vẫn bắn, bỏ qua
      if (_disposed) return;

      _unreadCount++;
      _safeNotify();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _safeNotify();

    try {
      final response = await apiService.getNotifications();
      _notifications =
          response.map((e) => AppNotification.fromJson(e)).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (_) {
      // Ignore
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await apiService.getUnreadNotificationCount();
      _safeNotify();
    } catch (_) {
      // Ignore
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await apiService.markNotificationAsRead(id);

      // Update local nhanh (tránh UI lag)
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }

      await loadNotifications();
    } catch (_) {
      // Ignore
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await apiService.markAllNotificationsAsRead();
      _unreadCount = 0;
      await loadNotifications();
    } catch (_) {
      // Ignore
    }
  }
}
