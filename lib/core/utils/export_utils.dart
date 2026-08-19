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
        int sdkVersion = 0;
        try {
          final numbers = RegExp(r'\d+')
              .allMatches(Platform.operatingSystemVersion)
              .map((m) => int.parse(m.group(0)!))
              .toList();
          if (numbers.isNotEmpty) {
            sdkVersion = numbers.firstWhere(
              (n) => n >= 19 && n <= 100,
              orElse: () => numbers.first,
            );
          }
        } catch (_) {}

        PermissionStatus status;
        if (sdkVersion >= 33) {
          status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
          }
        } else {
          status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        }

        if (!status.isGranted) {
          if (context.mounted) {
            if (status.isPermanentlyDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Storage permission is permanently denied. Please enable it in Settings.'),
                  backgroundColor: Colors.redAccent,
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () {
                      openAppSettings();
                    },
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission is required to save the report.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
          return;
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
            filename = match.group(1) ?? filename;
          } else {
             final regex2 = RegExp('filename=([^;]+)');
             final match2 = regex2.firstMatch(contentDisposition);
             if (match2 != null && match2.groupCount >= 1) {
               filename = match2.group(1) ?? filename;
             }
          }
          // Sanitize the filename to prevent path traversal vulnerability (Arbitrary File Write)
          filename = filename.split('/').last.split('\\').last.trim();
          if (filename.contains('..') || filename.isEmpty) {
            filename = 'Attendance_Report.xlsx';
          }
        }

        Directory? directory;
        if (Platform.isAndroid) {
          // Use the public Android Downloads directory
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
            directory ??= await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        String finalFilename = filename;
        String filePath = '${directory!.path}/$finalFilename';
        File file = File(filePath);

        // Ensure unique filename to prevent overwrite errors in public directories
        int counter = 1;
        String baseName = filename.contains('.') ? filename.substring(0, filename.lastIndexOf('.')) : filename;
        String extension = filename.contains('.') ? filename.substring(filename.lastIndexOf('.')) : '';
        while (await file.exists()) {
          finalFilename = '${baseName}_($counter)$extension';
          filePath = '${directory.path}/$finalFilename';
          file = File(filePath);
          counter++;
        }

        print('================ ATTENDANCE DOWNLOAD ================');
        print('Generating report...');
        print('File name: $finalFilename');
        print('Target storage: PUBLIC DOWNLOADS');
        print('Storage mechanism: Public Downloads directory (/storage/emulated/0/Download)');
        print('Before save: Attempting to write to $filePath');

        await file.writeAsBytes(response.bodyBytes);

        print('After save: Write completed.');
        print('Returned URI/path: $filePath');
        print('File exists / URI valid: ${await file.exists()}');
        print('Open target: $filePath');
        print('=====================================================');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Attendance report downloaded successfully!'),
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
