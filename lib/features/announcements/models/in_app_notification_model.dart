import 'package:pragatix/core/config/api_config.dart';

class NotificationAttachmentModel {
  final int id;
  final String filename;
  final String fileType; // IMAGE, PDF, DOCUMENT, SPREADSHEET, CSV
  final String contentType;
  final int fileSize;
  final String downloadUrl;

  NotificationAttachmentModel({
    required this.id,
    required this.filename,
    required this.fileType,
    required this.contentType,
    required this.fileSize,
    required this.downloadUrl,
  });

  factory NotificationAttachmentModel.fromJson(Map<String, dynamic> json) {
    final String rawUrl = json['downloadUrl']?.toString() ?? '';
    final String resolvedUrl = (rawUrl.isNotEmpty && !rawUrl.startsWith('http'))
        ? (rawUrl.startsWith('/') ? '${ApiConfig.baseUrl}$rawUrl' : '${ApiConfig.baseUrl}/$rawUrl')
        : rawUrl;

    return NotificationAttachmentModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      filename: json['filename']?.toString() ?? '',
      fileType: json['fileType']?.toString().toUpperCase() ?? 'DOCUMENT',
      contentType: json['contentType']?.toString() ?? '',
      fileSize: json['fileSize'] is int
          ? json['fileSize']
          : int.tryParse(json['fileSize']?.toString() ?? '0') ?? 0,
      downloadUrl: resolvedUrl,
    );
  }

  bool get isImage {
    final ft = fileType.toUpperCase();
    final ct = contentType.toLowerCase();
    final fn = filename.toLowerCase();
    return ft == 'IMAGE' ||
        ct.startsWith('image/') ||
        fn.endsWith('.jpg') ||
        fn.endsWith('.jpeg') ||
        fn.endsWith('.png') ||
        fn.endsWith('.webp');
  }

  bool get isPdf {
    final ft = fileType.toUpperCase();
    final ct = contentType.toLowerCase();
    final fn = filename.toLowerCase();
    return ft == 'PDF' || ct.contains('pdf') || fn.endsWith('.pdf');
  }

  bool get isSpreadsheet {
    final ft = fileType.toUpperCase();
    final ct = contentType.toLowerCase();
    final fn = filename.toLowerCase();
    return ft == 'SPREADSHEET' ||
        ft == 'CSV' ||
        ct.contains('excel') ||
        ct.contains('spreadsheet') ||
        ct.contains('csv') ||
        fn.endsWith('.xls') ||
        fn.endsWith('.xlsx') ||
        fn.endsWith('.csv');
  }

  String get formattedSize {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class InAppNotificationModel {
  final int id;
  final String title;
  final String subject;
  final String message;
  final DateTime createdAt;
  bool isRead;
  final List<NotificationAttachmentModel> attachments;

  InAppNotificationModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.attachments = const [],
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

    List<NotificationAttachmentModel> parsedAttachments = [];
    if (json['attachments'] is List) {
      parsedAttachments = (json['attachments'] as List)
          .whereType<Map<String, dynamic>>()
          .map((att) => NotificationAttachmentModel.fromJson(att))
          .toList();
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
      attachments: parsedAttachments,
    );
  }

  bool get hasAttachments => attachments.isNotEmpty;
  List<NotificationAttachmentModel> get imageAttachments =>
      attachments.where((a) => a.isImage).toList();
  List<NotificationAttachmentModel> get documentAttachments =>
      attachments.where((a) => !a.isImage).toList();
}
