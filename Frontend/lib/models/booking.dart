import 'enums.dart';

class WalletTransaction {
  final int id;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String? description;
  final String? relatedId;
  final DateTime createdDate;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    this.relatedId,
    required this.createdDate,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values[json['type'] as int],
      status: TransactionStatus.values[json['status'] as int],
      description: json['description'] as String?,
      relatedId: json['relatedId'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }

  bool get isPositive =>
      type == TransactionType.deposit ||
      type == TransactionType.refund ||
      type == TransactionType.reward;
}

class Court {
  final int id;
  final String name;
  final String? description;
  final double pricePerHour;
  final bool isActive;

  Court({
    required this.id,
    required this.name,
    this.description,
    required this.pricePerHour,
    required this.isActive,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      isActive: json['isActive'] as bool,
    );
  }
}

class Booking {
  final int id;
  final int courtId;
  final String courtName;
  final int memberId;
  final String memberName;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final BookingStatus status;
  final bool isRecurring;

  Booking({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.memberId,
    required this.memberName,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.isRecurring,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      courtId: json['courtId'] as int,
      courtName: json['courtName'] as String,
      memberId: json['memberId'] as int,
      memberName: json['memberName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: BookingStatus.values[json['status'] as int],
      isRecurring: json['isRecurring'] as bool,
    );
  }

  Duration get duration => endTime.difference(startTime);
  String get durationDisplay =>
      '${duration.inHours}h ${duration.inMinutes % 60}m';
}

class CalendarSlot {
  final int? bookingId;
  final int courtId;
  final String courtName;
  final DateTime startTime;
  final DateTime endTime;
  final bool isBooked;
  final bool isMyBooking;
  final String? bookedByName;

  CalendarSlot({
    this.bookingId,
    required this.courtId,
    required this.courtName,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    required this.isMyBooking,
    this.bookedByName,
  });

  factory CalendarSlot.fromJson(Map<String, dynamic> json) {
    return CalendarSlot(
      bookingId: json['bookingId'] as int?,
      courtId: json['courtId'] as int,
      courtName: json['courtName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      isBooked: json['isBooked'] as bool,
      isMyBooking: json['isMyBooking'] as bool,
      bookedByName: json['bookedByName'] as String?,
    );
  }
}
