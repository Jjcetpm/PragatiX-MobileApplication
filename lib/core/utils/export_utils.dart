import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pragatix/core/services/loading_service.dart';

class ExportUtils {
  /// Downloads a report from [url] with Bearer [token] and prompts user to save/open it.
  /// Uses Android Storage Access Framework (SAF) via system picker so no storage permissions are needed.
  static Future<void> downloadAndOpenExcel(
      BuildContext context, String url, String token) async {
    try {
      LoadingService.show(message: 'Downloading report...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      LoadingService.hide();

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
            successMessage: 'Report saved successfully!',
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
      LoadingService.hide();
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

  /// Saves raw [bytes] using the system file save picker (SAF / ACTION_CREATE_DOCUMENT)
  /// and allows the user to open the file. No broad storage permissions required.
  static Future<void> saveBytesAndOpen(
    BuildContext context,
    List<int> bytes,
    String defaultFilename, {
    String successMessage = 'File saved successfully!',
  }) async {
    try {
      LoadingService.hide();

      String filename = defaultFilename.split('/').last.split('\\').last.trim();
      if (filename.isEmpty || filename.contains('..')) {
        filename = 'Download.xlsx';
      }

      final uint8Bytes = Uint8List.fromList(bytes);

      // Open system file save picker (Storage Access Framework: ACTION_CREATE_DOCUMENT)
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        bytes: uint8Bytes,
      );

      // User cancelled save dialog
      if (outputPath == null) {
        return;
      }

      // Also create a cached copy in app temporary directory for seamless opening with OpenFilex
      String openablePath = outputPath;
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = '${tempDir.path}/$filename';
        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(bytes);
        openablePath = tempFilePath;
      } catch (e) {
        debugPrint('Cache file write notice: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              backgroundColor: const Color(0xFF4F46E5),
              onPressed: () {
                OpenFilex.open(openablePath);
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
