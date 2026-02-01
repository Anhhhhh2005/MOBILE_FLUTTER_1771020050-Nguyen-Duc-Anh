import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // For Android Emulator: use 10.0.2.2 instead of localhost
  // For iOS Simulator/Chrome: use 127.0.0.1 or localhost
  static const String baseUrl = 'http://10.0.2.2:5050/api';

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired, clear storage
            _storage.delete(key: 'token');
            _token = null;
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> init() async {
    _token = await _storage.read(key: 'token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'token', value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'token');
  }

  bool get hasToken => _token != null;
Future<int> holdSlot({
  required int courtId,
  required DateTime startTime,
  required DateTime endTime,
}) async {
  final res = await _dio.post('/bookings/hold', data: {
    "courtId": courtId,
    "startTime": startTime.toIso8601String(),
    "endTime": endTime.toIso8601String(),
  });

  return res.data["data"]["id"] as int; // bookingId hold
}
Future<void> confirmHold(int bookingId) async {
  await _dio.post('/bookings/confirm/$bookingId');
}

  // ==================== Auth ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName,
  ) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'fullName': fullName},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return response.data['data'];
  }

  // ==================== Members ====================
  Future<Map<String, dynamic>> getMembers({
    String? search,
    int? tier,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/members',
      queryParameters: {
        if (search != null) 'search': search,
        if (tier != null) 'tier': tier,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getMemberProfile(int id) async {
    final response = await _dio.get('/members/$id/profile');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateMember(
    int id, {
    String? fullName,
    String? avatarUrl,
  }) async {
    final response = await _dio.put(
      '/members/$id',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    return response.data['data'];
  }

  // ==================== Wallet ====================
  Future<double> getWalletBalance() async {
    final response = await _dio.get('/wallet/balance');
    return (response.data['data'] as num).toDouble();
  }

  Future<Map<String, dynamic>> getWalletTransactions({
    int? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/wallet/transactions',
      queryParameters: {
        if (type != null) 'type': type,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> deposit(
    double amount, {
    String? description,
    String? proofImageUrl,
  }) async {
    final response = await _dio.post(
      '/wallet/deposit',
      data: {
        'amount': amount,
        if (description != null) 'description': description,
        if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
      },
    );
    return response.data['data'];
  }

  // ==================== Courts ====================
  Future<List<dynamic>> getCourts() async {
    final response = await _dio.get('/courts');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getCourt(int id) async {
    final response = await _dio.get('/courts/$id');
    return response.data['data'];
  }

  // ==================== Bookings ====================
  Future<List<dynamic>> getCalendar(DateTime from, DateTime to) async {
    final response = await _dio.get(
      '/bookings/calendar',
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> createBooking(
    int courtId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final response = await _dio.post(
      '/bookings',
      data: {
        'courtId': courtId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      },
    );
    return response.data['data'];
  }

  Future<List<dynamic>> createRecurringBooking(
    int courtId,
    DateTime startDate,
    DateTime endDate,
    List<int> daysOfWeek,
    Duration startTime,
    Duration endTime,
  ) async {
    final response = await _dio.post(
      '/bookings/recurring',
      data: {
        'courtId': courtId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'daysOfWeek': daysOfWeek,
        'startTime':
            '${startTime.inHours.toString().padLeft(2, '0')}:${(startTime.inMinutes % 60).toString().padLeft(2, '0')}:00',
        'endTime':
            '${endTime.inHours.toString().padLeft(2, '0')}:${(endTime.inMinutes % 60).toString().padLeft(2, '0')}:00',
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> cancelBooking(int id) async {
    final response = await _dio.post('/bookings/cancel/$id');
    return response.data['data'];
  }

  Future<List<dynamic>> getMyBookings({int? status}) async {
    final response = await _dio.get(
      '/bookings/my',
      queryParameters: {if (status != null) 'status': status},
    );
    return response.data['data'];
  }

  // ==================== Tournaments ====================
  Future<List<dynamic>> getTournaments({int? status}) async {
    final response = await _dio.get(
      '/tournaments',
      queryParameters: {if (status != null) 'status': status},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getTournament(int id) async {
    final response = await _dio.get('/tournaments/$id');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> joinTournament(
    int id, {
    String? teamName,
    int? partnerId,
  }) async {
    final response = await _dio.post(
      '/tournaments/$id/join',
      data: {
        if (teamName != null) 'teamName': teamName,
        if (partnerId != null) 'partnerId': partnerId,
      },
    );
    return response.data['data'];
  }

  // ==================== Matches ====================
  Future<Map<String, dynamic>> getMatch(int id) async {
    final response = await _dio.get('/matches/$id');
    return response.data['data'];
  }

  Future<List<dynamic>> getUpcomingMatches() async {
    final response = await _dio.get('/matches/upcoming');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateMatchResult(
    int id,
    int score1,
    int score2,
    int winningSide, {
    String? details,
  }) async {
    final response = await _dio.post(
      '/matches/$id/result',
      data: {
        'score1': score1,
        'score2': score2,
        'winningSide': winningSide,
        if (details != null) 'details': details,
      },
    );
    return response.data['data'];
  }

  // ==================== News ====================
  Future<List<dynamic>> getNews() async {
    final response = await _dio.get('/news');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getNewsItem(int id) async {
    final response = await _dio.get('/news/$id');
    return response.data['data'];
  }

  // ==================== Notifications ====================
  Future<List<dynamic>> getNotifications() async {
    final response = await _dio.get('/notifications');
    return response.data['data'];
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await _dio.get('/notifications/unread-count');
    return response.data['data'] as int;
  }

  Future<void> markNotificationAsRead(int id) async {
    await _dio.put('/notifications/$id/read');
  }

  Future<void> markAllNotificationsAsRead() async {
    await _dio.put('/notifications/read-all');
  }

  // ==================== Admin & Finance ====================
  Future<Map<String, dynamic>> getClubBalance() async {
    final response = await _dio.get('/admin/club-balance');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getClubTransactions({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '/admin/club-transactions',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _dio.get('/admin/dashboard/stats');
    return response.data['data'];
  }

  Future<List<dynamic>> getRevenueChart() async {
    final response = await _dio.get('/admin/dashboard/revenue');
    return response.data['data'];
  }

  Future<List<dynamic>> getBookingsChart() async {
    final response = await _dio.get('/admin/dashboard/bookings-chart');
    return response.data['data'];
  }

  Future<List<dynamic>> getPendingDeposits() async {
    final response = await _dio.get('/admin/wallet/pending');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> approveDeposit(int transactionId) async {
    final response = await _dio.put('/admin/wallet/approve/$transactionId');
    return response.data;
  }

  Future<Map<String, dynamic>> rejectDeposit(int transactionId) async {
    final response = await _dio.put('/admin/wallet/reject/$transactionId');
    return response.data;
  }
}

// Singleton instance
final apiService = ApiService();
