class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  factory AppNotification.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AppNotification(
      id: id,
      userId: map['userId'],
      title: map['title'],
      message: map['message'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as DateTime),
    );
  }
}
