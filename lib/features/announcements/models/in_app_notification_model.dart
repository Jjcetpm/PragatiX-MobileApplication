class InAppNotificationModel {
  final int id;
  final String title;
  final String subject;
  final String message;
  final DateTime createdAt;
  bool isRead;

  InAppNotificationModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory InAppNotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      if (json['createdAt'] != null) {
        parsedDate = DateTime.parse(json['createdAt'].toString());
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return InAppNotificationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: parsedDate,
      isRead: json['read'] == true || json['isRead'] == true,
    );
  }
}
