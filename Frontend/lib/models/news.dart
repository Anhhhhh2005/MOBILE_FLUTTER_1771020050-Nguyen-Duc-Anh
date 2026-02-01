import 'enums.dart';

class News {
  final int id;
  final String title;
  final String content;
  final bool isPinned;
  final String? imageUrl;
  final DateTime createdDate;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.isPinned,
    this.imageUrl,
    required this.createdDate,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      isPinned: json['isPinned'] as bool,
      imageUrl: json['imageUrl'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }
}

class AppNotification {
  final int id;
  final String message;
  final NotificationType type;
  final String? linkUrl;
  final bool isRead;
  final DateTime createdDate;

  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    this.linkUrl,
    required this.isRead,
    required this.createdDate,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      message: json['message'] as String,
      type: NotificationType.values[json['type'] as int],
      linkUrl: json['linkUrl'] as String?,
      isRead: json['isRead'] as bool,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }
}
