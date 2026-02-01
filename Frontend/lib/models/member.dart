import 'enums.dart';

class Member {
  final int id;
  final String fullName;
  final DateTime joinDate;
  final double rankLevel;
  final MemberTier tier;
  final double walletBalance;
  final String? avatarUrl;
  final bool isActive;

  Member({
    required this.id,
    required this.fullName,
    required this.joinDate,
    required this.rankLevel,
    required this.tier,
    required this.walletBalance,
    this.avatarUrl,
    required this.isActive,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      joinDate: DateTime.parse(json['joinDate'] as String),
      rankLevel: (json['rankLevel'] as num).toDouble(),
      tier: MemberTier.values[json['tier'] as int],
      walletBalance: (json['walletBalance'] as num).toDouble(),
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool,
    );
  }
}

class MemberProfile extends Member {
  final double totalSpent;
  final int totalMatches;
  final int totalWins;
  final int totalTournaments;
  final List<Match> recentMatches;

  MemberProfile({
    required super.id,
    required super.fullName,
    required super.joinDate,
    required super.rankLevel,
    required super.tier,
    required super.walletBalance,
    super.avatarUrl,
    required super.isActive,
    required this.totalSpent,
    required this.totalMatches,
    required this.totalWins,
    required this.totalTournaments,
    required this.recentMatches,
  });

  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    return MemberProfile(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      joinDate: DateTime.parse(json['joinDate'] as String),
      rankLevel: (json['rankLevel'] as num).toDouble(),
      tier: MemberTier.values[json['tier'] as int],
      walletBalance: (json['walletBalance'] as num).toDouble(),
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool,
      totalSpent: (json['totalSpent'] as num).toDouble(),
      totalMatches: json['totalMatches'] as int,
      totalWins: json['totalWins'] as int,
      totalTournaments: json['totalTournaments'] as int,
      recentMatches:
          (json['recentMatches'] as List?)
              ?.map((e) => Match.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  double get winRate => totalMatches > 0 ? (totalWins / totalMatches) * 100 : 0;
}

class Match {
  final int id;
  final int? tournamentId;
  final String? tournamentName;
  final String? roundName;
  final DateTime date;
  final DateTime startTime;
  final int? team1Player1Id;
  final String? team1Player1Name;
  final int? team1Player2Id;
  final String? team1Player2Name;
  final int? team2Player1Id;
  final String? team2Player1Name;
  final int? team2Player2Id;
  final String? team2Player2Name;
  final int score1;
  final int score2;
  final String? details;
  final WinningSide? winningSide;
  final MatchStatus status;

  Match({
    required this.id,
    this.tournamentId,
    this.tournamentName,
    this.roundName,
    required this.date,
    required this.startTime,
    this.team1Player1Id,
    this.team1Player1Name,
    this.team1Player2Id,
    this.team1Player2Name,
    this.team2Player1Id,
    this.team2Player1Name,
    this.team2Player2Id,
    this.team2Player2Name,
    required this.score1,
    required this.score2,
    this.details,
    this.winningSide,
    required this.status,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as int,
      tournamentId: json['tournamentId'] as int?,
      tournamentName: json['tournamentName'] as String?,
      roundName: json['roundName'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      team1Player1Id: json['team1_Player1Id'] as int?,
      team1Player1Name: json['team1_Player1Name'] as String?,
      team1Player2Id: json['team1_Player2Id'] as int?,
      team1Player2Name: json['team1_Player2Name'] as String?,
      team2Player1Id: json['team2_Player1Id'] as int?,
      team2Player1Name: json['team2_Player1Name'] as String?,
      team2Player2Id: json['team2_Player2Id'] as int?,
      team2Player2Name: json['team2_Player2Name'] as String?,
      score1: json['score1'] as int,
      score2: json['score2'] as int,
      details: json['details'] as String?,
      winningSide: json['winningSide'] != null
          ? WinningSide.values[json['winningSide'] as int]
          : null,
      status: MatchStatus.values[json['status'] as int],
    );
  }

  String get team1Display {
    var display = team1Player1Name ?? 'TBD';
    if (team1Player2Name != null) {
      display += ' & $team1Player2Name';
    }
    return display;
  }

  String get team2Display {
    var display = team2Player1Name ?? 'TBD';
    if (team2Player2Name != null) {
      display += ' & $team2Player2Name';
    }
    return display;
  }

  String get scoreDisplay => '$score1 - $score2';
}
