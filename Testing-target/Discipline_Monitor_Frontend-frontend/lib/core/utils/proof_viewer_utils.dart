import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/widgets/full_screen_image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';

class ProofViewerUtils {
  static const Set<String> _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  /// Opens proof content based on type (Image, PDF, External URL, Local file).
  static Future<void> openProof(
    BuildContext context,
    String? rawUrl, {
    String? title,
  }) async {
    // URL Validation
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      _showError(context, 'Unable to open proof.');
      return;
    }

    final trimmed = rawUrl.trim();

    // Check if it is a local file path
    final isLocalFile = trimmed.startsWith('file://') ||
        trimmed.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(trimmed);

    if (isLocalFile) {
      await _handleLocalFile(context, trimmed, title: title);
      return;
    }

    // Remote URL / Web link handling
    await _handleRemoteUrl(context, trimmed, title: title);
  }

  static Future<void> _handleLocalFile(
    BuildContext context,
    String path, {
    String? title,
  }) async {
    String cleanPath = path;
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }

    final file = File(cleanPath);
    if (!file.existsSync()) {
      _showError(context, 'Proof file not found.');
      return;
    }

    final ext = _extractExtension(cleanPath);
    if (_imageExtensions.contains(ext)) {
      // Case 1: Local Image -> In-app viewer
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imageUrl: cleanPath,
              isNetwork: false,
              title: title ?? 'Proof Image',
            ),
          ),
        );
      }
      return;
    }

    // Case 2/Other: Local PDF / Document -> Open with OpenFilex
    try {
      final result = await OpenFilex.open(cleanPath);
      if (result.type != ResultType.done && context.mounted) {
        _showError(context, 'Unable to open proof.');
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Unable to open proof.');
      }
    }
  }

  static Future<void> _handleRemoteUrl(
    BuildContext context,
    String url, {
    String? title,
  }) async {
    String formattedUrl = url;

    // Check if relative backend URL (e.g., /uploads/...)
    if (formattedUrl.startsWith('/')) {
      formattedUrl = '${ApiConfig.baseUrl}$formattedUrl';
    } else if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    final uri = Uri.tryParse(formattedUrl);
    if (uri == null || uri.host.isEmpty) {
      _showError(context, 'Unable to open proof.');
      return;
    }

    final pathWithoutQuery = uri.path.toLowerCase();
    final ext = _extractExtension(pathWithoutQuery);

    // Case 1: Remote Image -> Open inside the app with full-screen image viewer
    if (_imageExtensions.contains(ext) || _isImageUrl(formattedUrl)) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imageUrl: formattedUrl,
              isNetwork: true,
              title: title ?? 'Proof Image',
            ),
          ),
        );
      }
      return;
    }

    // Case 2 & 3: PDF or External URL -> Launch in external browser / app
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final launchedDefault = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (!launchedDefault && context.mounted) {
          _showError(context, 'Unable to open proof.');
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Unable to open proof.');
      }
    }
  }

  static String _extractExtension(String path) {
    final idx = path.lastIndexOf('.');
    if (idx != -1 && idx < path.length - 1) {
      final ext = path.substring(idx).toLowerCase();
      // Only keep alphanumeric extension
      final cleanExt = ext.split(RegExp(r'[?#&/]')).first;
      return cleanExt;
    }
    return '';
  }

  static bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg?') ||
        lower.contains('.jpeg?') ||
        lower.contains('.png?') ||
        lower.contains('.webp?');
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
