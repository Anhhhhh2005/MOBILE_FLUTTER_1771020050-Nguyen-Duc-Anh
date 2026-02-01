import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  static const String hubUrl = 'http://localhost:5050/hubs/pcm';

  HubConnection? _hubConnection;
  String? _token;

  final _notificationController =
      StreamController<NotificationEvent>.broadcast();
  final _calendarUpdateController = StreamController<String>.broadcast();
  final _matchScoreController = StreamController<MatchScoreEvent>.broadcast();

  Stream<NotificationEvent> get notifications => _notificationController.stream;
  Stream<String> get calendarUpdates => _calendarUpdateController.stream;
  Stream<MatchScoreEvent> get matchScores => _matchScoreController.stream;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> connect(String token) async {
    _token = token;

    _hubConnection = HubConnectionBuilder()
        .withUrl('$hubUrl?access_token=$token')
        .withAutomaticReconnect()
        .build();

    // Register handlers
    _hubConnection!.on('ReceiveNotification', _handleNotification);
    _hubConnection!.on('UpdateCalendar', _handleCalendarUpdate);
    _hubConnection!.on('UpdateMatchScore', _handleMatchScore);

    // Connection state handlers
    _hubConnection!.onclose(({error}) {
      debugPrint('SignalR connection closed: $error');
    });

    _hubConnection!.onreconnecting(({error}) {
      debugPrint('SignalR reconnecting: $error');
    });

    _hubConnection!.onreconnected(({connectionId}) {
      debugPrint('SignalR reconnected: $connectionId');
    });

    try {
      await _hubConnection!.start();
      debugPrint('SignalR connected successfully');
    } catch (e) {
      debugPrint('SignalR connection error: $e');
    }
  }

  void _handleNotification(List<Object?>? args) {
    if (args != null && args.length >= 2) {
      final message = args[0] as String;
      final type = args[1] as String;
      _notificationController.add(
        NotificationEvent(message: message, type: type),
      );
    }
  }

  void _handleCalendarUpdate(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final message = args[0] as String;
      _calendarUpdateController.add(message);
    }
  }

  void _handleMatchScore(List<Object?>? args) {
    if (args != null && args.length >= 3) {
      final matchId = args[0] as int;
      final score1 = args[1] as int;
      final score2 = args[2] as int;
      _matchScoreController.add(
        MatchScoreEvent(matchId: matchId, score1: score1, score2: score2),
      );
    }
  }

  Future<void> joinMatchGroup(int matchId) async {
    if (isConnected) {
      await _hubConnection!.invoke('JoinMatchGroup', args: [matchId]);
    }
  }

  Future<void> leaveMatchGroup(int matchId) async {
    if (isConnected) {
      await _hubConnection!.invoke('LeaveMatchGroup', args: [matchId]);
    }
  }

  Future<void> joinTournamentGroup(int tournamentId) async {
    if (isConnected) {
      await _hubConnection!.invoke('JoinTournamentGroup', args: [tournamentId]);
    }
  }

  Future<void> leaveTournamentGroup(int tournamentId) async {
    if (isConnected) {
      await _hubConnection!.invoke(
        'LeaveTournamentGroup',
        args: [tournamentId],
      );
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
    }
  }

  void dispose() {
    _notificationController.close();
    _calendarUpdateController.close();
    _matchScoreController.close();
    disconnect();
  }
}

class NotificationEvent {
  final String message;
  final String type;

  NotificationEvent({required this.message, required this.type});
}

class MatchScoreEvent {
  final int matchId;
  final int score1;
  final int score2;

  MatchScoreEvent({
    required this.matchId,
    required this.score1,
    required this.score2,
  });
}

// Singleton instance
final signalRService = SignalRService();
