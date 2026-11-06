import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pragatix/features/announcements/models/in_app_notification_model.dart';

class AnnouncementDetailsPage extends StatelessWidget {
  final String title;
  final String subject;
  final String message;
  final String? createdAt;
  final List<NotificationAttachmentModel>? attachments;

  const AnnouncementDetailsPage({
    super.key,
    required this.title,
    required this.subject,
    required this.message,
    this.createdAt,
    this.attachments,
  });

  void _openAttachment(BuildContext context, NotificationAttachmentModel att) async {
    if (att.downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download URL is not available')),
      );
      return;
    }
    try {
      final uri = Uri.parse(att.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }

  void _showImageDialog(BuildContext context, NotificationAttachmentModel img) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    img.downloadUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'Failed to load full image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocIcon(NotificationAttachmentModel att) {
    if (att.isPdf) return Icons.picture_as_pdf_rounded;
    if (att.isSpreadsheet) return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getDocColor(NotificationAttachmentModel att) {
    if (att.isPdf) return Colors.red.shade700;
    if (att.isSpreadsheet) return Colors.green.shade700;
    return Colors.blue.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attList = attachments ?? [];
    final imageAttachments = attList.where((a) => a.isImage).toList();
    final documentAttachments = attList.where((a) => !a.isImage).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Announcement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Tag Chip
            if (subject.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

            // Announcement Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            // Date / Time if available
            if (createdAt != null && createdAt!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      createdAt!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 12),

            // Message Body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),

            // ── Attached Images Section ──
            if (imageAttachments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.image_outlined, size: 18, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  Text(
                    'Attached Images (${imageAttachments.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: imageAttachments.map((img) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () => _showImageDialog(context, img),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image.network(
                                img.downloadUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 180,
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 120,
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                                        SizedBox(height: 6),
                                        Text('Image could not be loaded', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('Tap to expand', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // ── Attached Documents Section ──
            if (documentAttachments.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  Text(
                    'Attached Documents (${documentAttachments.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                children: documentAttachments.map((doc) {
                  final docColor = _getDocColor(doc);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: docColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getDocIcon(doc), color: docColor, size: 22),
                      ),
                      title: Text(
                        doc.filename,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${doc.fileType} ${doc.formattedSize.isNotEmpty ? '• ${doc.formattedSize}' : ''}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download_rounded, color: Color(0xFF4F46E5)),
                        onPressed: () => _openAttachment(context, doc),
                        tooltip: 'Open / Download',
                      ),
                      onTap: () => _openAttachment(context, doc),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Acknowledge & Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
