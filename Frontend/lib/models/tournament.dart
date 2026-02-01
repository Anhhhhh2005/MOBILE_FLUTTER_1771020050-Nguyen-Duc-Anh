import 'enums.dart';
import 'member.dart';

class Tournament {
  final int id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentFormat format;
  final double entryFee;
  final double prizePool;
  final TournamentStatus status;
  final int maxParticipants;
  final int currentParticipants;

  Tournament({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    required this.maxParticipants,
    required this.currentParticipants,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      format: TournamentFormat.values[json['format'] as int],
      entryFee: (json['entryFee'] as num).toDouble(),
      prizePool: (json['prizePool'] as num).toDouble(),
      status: TournamentStatus.values[json['status'] as int],
      maxParticipants: json['maxParticipants'] as int,
      currentParticipants: json['currentParticipants'] as int,
    );
  }

  bool get canRegister =>
      status == TournamentStatus.open || status == TournamentStatus.registering;

  bool get isFull => currentParticipants >= maxParticipants;

  String get participantDisplay => '$currentParticipants / $maxParticipants';
}

class TournamentDetail extends Tournament {
  final List<Participant> participants;
  final List<Match> matches;

  TournamentDetail({
    required super.id,
    required super.name,
    super.description,
    required super.startDate,
    required super.endDate,
    required super.format,
    required super.entryFee,
    required super.prizePool,
    required super.status,
    required super.maxParticipants,
    required super.currentParticipants,
    required this.participants,
    required this.matches,
  });

  factory TournamentDetail.fromJson(Map<String, dynamic> json) {
    return TournamentDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      format: TournamentFormat.values[json['format'] as int],
      entryFee: (json['entryFee'] as num).toDouble(),
      prizePool: (json['prizePool'] as num).toDouble(),
      status: TournamentStatus.values[json['status'] as int],
      maxParticipants: json['maxParticipants'] as int,
      currentParticipants: json['currentParticipants'] as int,
      participants:
          (json['participants'] as List?)
              ?.map((e) => Participant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      matches:
          (json['matches'] as List?)
              ?.map((e) => Match.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Participant {
  final int id;
  final int memberId;
  final String memberName;
  final String? teamName;
  final int? partnerId;
  final String? partnerName;
  final int? seed;
  final bool paymentStatus;

  Participant({
    required this.id,
    required this.memberId,
    required this.memberName,
    this.teamName,
    this.partnerId,
    this.partnerName,
    this.seed,
    required this.paymentStatus,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as int,
      memberId: json['memberId'] as int,
      memberName: json['memberName'] as String,
      teamName: json['teamName'] as String?,
      partnerId: json['partnerId'] as int?,
      partnerName: json['partnerName'] as String?,
      seed: json['seed'] as int?,
      paymentStatus: json['paymentStatus'] as bool,
    );
  }

  String get displayName => teamName ?? memberName;
}
