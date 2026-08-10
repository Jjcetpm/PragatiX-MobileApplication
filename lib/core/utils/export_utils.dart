import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportUtils {
  static Future<void> downloadAndOpenExcel(
      BuildContext context, String url, String token) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading report...')),
      );

      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

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
            filename = match.group(1)!;
          } else {
             final regex2 = RegExp('filename=([^;]+)');
             final match2 = regex2.firstMatch(contentDisposition);
             if (match2 != null && match2.groupCount >= 1) {
               filename = match2.group(1)!;
             }
          }
        }

        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
          directory ??= await getApplicationDocumentsDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        final filePath = '${directory.path}/$filename';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance report exported successfully:\n$filePath'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  OpenFilex.open(filePath);
                },
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed. Server returned: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }
}
