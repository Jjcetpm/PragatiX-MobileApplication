import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pragatix/core/services/loading_service.dart';

class ExportUtils {
  /// Strictly checks and requests device storage permission for all Android OS versions (Android 9 to 15+).
  /// If not granted, prompts user with a dialog and system request with Allow/Deny options.
  static Future<bool> ensureStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    try {
      // 1. Check if storage permission or manageExternalStorage is already granted
      final storageGranted = await Permission.storage.isGranted;
      final manageGranted = await Permission.manageExternalStorage.isGranted;
      if (storageGranted || manageGranted) {
        return true;
      }

      // Hide any active loader overlay so the permission dialog is completely visible and clickable
      LoadingService.hide();

      // 2. Prompt user first with an explicit permission dialog
      if (context.mounted) {
        final userChoice = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.folder_shared_rounded, color: Color(0xFF4F46E5), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Storage Permission',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Storage permission is required to save and download Excel templates and Attendance reports to your device.\n\nPlease allow storage permission to proceed.',
              style: TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF334155)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Deny', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text(
                  'Allow / Continue',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (userChoice != true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Download cancelled: Storage permission was denied.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return false;
        }
      }

      // 3. Request system permissions
      // First try storage request
      final storageReq = await Permission.storage.request();
      if (storageReq.isGranted) {
        return true;
      }

      // For Android 11+ (API 30+), try manageExternalStorage request
      final manageReq = await Permission.manageExternalStorage.request();
      if (manageReq.isGranted) {
        return true;
      }

      // If permanently denied or not granted, direct user to App Settings to allow
      if (storageReq.isPermanentlyDenied || manageReq.isPermanentlyDenied || !manageReq.isGranted) {
        if (context.mounted) {
          final openSettingsChoice = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.settings_suggest_rounded, color: Color(0xFF4F46E5), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enable Permission',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Please enable Storage / Files permission for PragatiX in App Settings to allow downloading files to your device.',
                style: TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF334155)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx, true);
                    openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );

          if (openSettingsChoice == true) {
            return false;
          }
        }
      }
    } catch (e) {
      debugPrint('Storage permission check error: $e');
    }

    return false;
  }

  /// Downloads a report from [url] with Bearer [token] and opens it with OpenFilex.
  /// Strictly checks and requests device storage permission before proceeding.
  static Future<void> downloadAndOpenExcel(
      BuildContext context, String url, String token) async {
    try {
      // 1. Enforce permission verification
      final hasPermission = await ensureStoragePermission(context);
      if (!hasPermission) {
        return;
      }

      LoadingService.show(message: 'Downloading report...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        String filename = 'Attendance_Report.xlsx';
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null) {
          final regex = RegExp('filename="([^"]+)"');
          final match = regex.firstMatch(contentDisposition);
          if (match != null && match.groupCount >= 1) {
            filename = match.group(1) ?? filename;
          } else {
            final regex2 = RegExp('filename=([^;]+)');
            final match2 = regex2.firstMatch(contentDisposition);
            if (match2 != null && match2.groupCount >= 1) {
              filename = match2.group(1) ?? filename;
            }
          }
          // Sanitize the filename to prevent path traversal vulnerability
          filename = filename.split('/').last.split('\\').last.trim();
          if (filename.contains('..') || filename.isEmpty) {
            filename = 'Attendance_Report.xlsx';
          }
        }

        if (context.mounted) {
          await saveBytesAndOpen(
            context,
            response.bodyBytes,
            filename,
            successMessage: 'Report downloaded successfully to Downloads folder!',
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed. Server returned: ${response.statusCode}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Saves raw [bytes] to the best available storage location and opens it.
  /// Handles Android Scoped Storage and public Download folder seamlessly.
  static Future<void> saveBytesAndOpen(
    BuildContext context,
    List<int> bytes,
    String defaultFilename, {
    String successMessage = 'File downloaded successfully!',
  }) async {
    try {
      // 1. Enforce permission verification
      final hasPermission = await ensureStoragePermission(context);
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to save files to your device.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      String filename = defaultFilename.split('/').last.split('\\').last.trim();
      if (filename.isEmpty || filename.contains('..')) {
        filename = 'Download.xlsx';
      }

      Directory? targetDir;

      // 1. Try public Download folder on Android if possible
      if (Platform.isAndroid) {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          try {
            final testFile = File('${publicDownload.path}/.test_write_${DateTime.now().millisecondsSinceEpoch}');
            await testFile.writeAsString('test');
            await testFile.delete();
            targetDir = publicDownload;
          } catch (_) {
            targetDir = null;
          }
        }
      }

      // 2. Fallback to app external storage directory
      if (targetDir == null && Platform.isAndroid) {
        try {
          targetDir = await getExternalStorageDirectory();
        } catch (_) {}
      }

      // 3. Fallback to documents / platform downloads
      if (targetDir == null) {
        try {
          if (Platform.isIOS) {
            targetDir = await getApplicationDocumentsDirectory();
          } else if (Platform.isAndroid) {
            targetDir = await getApplicationDocumentsDirectory();
          } else {
            targetDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          }
        } catch (_) {
          targetDir = await getTemporaryDirectory();
        }
      }

      final String baseName = filename.contains('.')
          ? filename.substring(0, filename.lastIndexOf('.'))
          : filename;
      final String extension =
          filename.contains('.') ? filename.substring(filename.lastIndexOf('.')) : '';

      String finalFilename = filename;
      String filePath = '${targetDir.path}/$finalFilename';
      File file = File(filePath);

      int counter = 1;
      while (await file.exists()) {
        finalFilename = '${baseName}_($counter)$extension';
        filePath = '${targetDir.path}/$finalFilename';
        file = File(filePath);
        counter++;
      }

      try {
        await file.writeAsBytes(bytes);
      } catch (writeErr) {
        // If writing failed (e.g. PermissionDenied on public folder), write to app internal directory
        final fallbackDir = await getApplicationDocumentsDirectory();
        final fallbackPath = '${fallbackDir.path}/$finalFilename';
        final fallbackFile = File(fallbackPath);
        await fallbackFile.writeAsBytes(bytes);
        filePath = fallbackPath;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                OpenFilex.open(filePath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

