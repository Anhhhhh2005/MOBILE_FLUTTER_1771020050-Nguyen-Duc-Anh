import 'enums.dart';

class UserInfo {
  final int memberId;
  final String userId;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final double rankLevel;
  final MemberTier tier;
  final double walletBalance;
  final List<String> roles;

  UserInfo({
    required this.memberId,
    required this.userId,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.rankLevel,
    required this.tier,
    required this.walletBalance,
    required this.roles,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      memberId: json['memberId'] as int,
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      rankLevel: (json['rankLevel'] as num).toDouble(),
      tier: MemberTier.values[json['tier'] as int],
      walletBalance: (json['walletBalance'] as num).toDouble(),
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'userId': userId,
    'email': email,
    'fullName': fullName,
    'avatarUrl': avatarUrl,
    'rankLevel': rankLevel,
    'tier': tier.index,
    'walletBalance': walletBalance,
    'roles': roles,
  };

  bool get isAdmin => roles.contains('Admin');
  bool get isTreasurer => roles.contains('Treasurer');
  bool get isReferee => roles.contains('Referee');
}

class AuthResponse {
  final String token;
  final DateTime expiration;
  final UserInfo user;

  AuthResponse({
    required this.token,
    required this.expiration,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      expiration: DateTime.parse(json['expiration'] as String),
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
