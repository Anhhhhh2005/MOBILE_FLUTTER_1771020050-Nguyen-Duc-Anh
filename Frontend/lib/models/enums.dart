// Enums matching backend
enum MemberTier { standard, silver, gold, diamond }

enum TransactionType { deposit, withdraw, payment, refund, reward }

enum TransactionStatus { pending, completed, rejected, failed }

enum BookingStatus { pendingPayment, confirmed, cancelled, completed }

enum TournamentFormat { roundRobin, knockout, hybrid }

enum TournamentStatus { open, registering, drawCompleted, ongoing, finished }

enum MatchStatus { scheduled, inProgress, finished }

enum WinningSide { team1, team2 }

enum NotificationType { info, success, warning }

// Extension methods for enum display
extension MemberTierExt on MemberTier {
  String get displayName {
    switch (this) {
      case MemberTier.standard:
        return 'Standard';
      case MemberTier.silver:
        return 'Silver';
      case MemberTier.gold:
        return 'Gold';
      case MemberTier.diamond:
        return 'Diamond';
    }
  }

  String get icon {
    switch (this) {
      case MemberTier.standard:
        return '⭐';
      case MemberTier.silver:
        return '🥈';
      case MemberTier.gold:
        return '🥇';
      case MemberTier.diamond:
        return '💎';
    }
  }
}

extension TransactionTypeExt on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.deposit:
        return 'Nạp tiền';
      case TransactionType.withdraw:
        return 'Rút tiền';
      case TransactionType.payment:
        return 'Thanh toán';
      case TransactionType.refund:
        return 'Hoàn tiền';
      case TransactionType.reward:
        return 'Thưởng giải';
    }
  }
}

extension BookingStatusExt on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pendingPayment:
        return 'Chờ thanh toán';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.completed:
        return 'Hoàn thành';
    }
  }
}

extension TournamentStatusExt on TournamentStatus {
  String get displayName {
    switch (this) {
      case TournamentStatus.open:
        return 'Mở đăng ký';
      case TournamentStatus.registering:
        return 'Đang đăng ký';
      case TournamentStatus.drawCompleted:
        return 'Đã bốc thăm';
      case TournamentStatus.ongoing:
        return 'Đang diễn ra';
      case TournamentStatus.finished:
        return 'Kết thúc';
    }
  }
}

extension MatchStatusExt on MatchStatus {
  String get displayName {
    switch (this) {
      case MatchStatus.scheduled:
        return 'Đã lên lịch';
      case MatchStatus.inProgress:
        return 'Đang diễn ra';
      case MatchStatus.finished:
        return 'Kết thúc';
    }
  }
}
