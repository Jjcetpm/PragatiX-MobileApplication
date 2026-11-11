import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pragatix/core/config/app_version_config.dart';
import 'package:pragatix/core/services/app_version_service.dart';

/// Full-screen blocking gate displayed when the student's app version is outdated.
///
/// Features:
/// 1. Non-dismissible via PopScope(canPop: false) to prevent bypassing.
/// 2. Clear version comparison (Current vs Latest).
/// 3. One-tap "Update Now" button launching Google Play Store / APK download.
/// 4. "Check Again" button to re-evaluate version status after updating.
class ForceUpdatePage extends StatefulWidget {
  const ForceUpdatePage({super.key});

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage> {
  bool _isChecking = false;

  Future<void> _handleUpdate(String? storeUrl, String? directUrl) async {
    final url = (storeUrl != null && storeUrl.isNotEmpty)
        ? storeUrl
        : (directUrl != null && directUrl.isNotEmpty
            ? directUrl
            : AppVersionConfig.defaultPlayStoreUrl);

    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && directUrl != null && directUrl.isNotEmpty) {
          final directUri = Uri.tryParse(directUrl);
          if (directUri != null) {
            await launchUrl(directUri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        debugPrint('[ForceUpdatePage] Failed to launch update URL: $e');
      }
    }
  }

  Future<void> _handleRecheck() async {
    setState(() => _isChecking = true);
    final isStillRequired = await AppVersionService.instance.checkAppVersion();
    if (mounted) {
      setState(() => _isChecking = false);
      if (isStillRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'App update still required. Please complete the upgrade.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: AppVersionService.instance.updateInfo,
            builder: (context, info, _) {
              final rawTitle = info?.title;
              final title = (rawTitle != null && rawTitle.isNotEmpty && rawTitle != 'Update Required')
                  ? rawTitle
                  : 'Update to the latest version';
              final message = info?.message ??
                  'A new update of PragatiX is available. You must upgrade to the latest version to continue using the app.';
              final latestVer = info?.latestVersion ?? 'Latest';
              final latestBuild = info?.latestBuildNumber ?? 25;
              final releaseNotes = info?.releaseNotes ??
                  '• Important stability & security updates\n• Bug fixes and speed improvements\n• Student headline & bio features';

              return Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // College / Brand Logo
                      Image.asset(
                        'assets/images/logo.png',
                        height: 52,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 28),

                      // Update Icon with Outer Glowing Rings
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEEF2FF),
                          border: Border.all(color: const Color(0xFFC7D2FE), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.system_update_rounded,
                            size: 46,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle / Description
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Version Comparison Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Column(
                              children: [
                                Text(
                                  'Your Version',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'v${AppVersionConfig.currentVersion} (${AppVersionConfig.currentBuildNumber})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Required Version',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'v$latestVer ($latestBuild)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Release Highlights (if present)
                      if (releaseNotes.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.new_releases_rounded, size: 16, color: Color(0xFF4F46E5)),
                                  SizedBox(width: 6),
                                  Text(
                                    "What's New in this Update",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                releaseNotes,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF475569),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ] else ...[
                        const SizedBox(height: 12),
                      ],

                      // Action Button: Update Now
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleUpdate(
                            info?.playStoreUrl,
                            info?.directApkUrl,
                          ),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.white),
                          label: const Text(
                            'Update Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Button: Check Again / Refresh
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _isChecking ? null : _handleRecheck,
                          icon: _isChecking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF64748B),
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF64748B)),
                          label: Text(
                            _isChecking ? 'Verifying update...' : 'I Have Already Updated',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      // Direct APK Link Fallback
                      if (info?.directApkUrl != null && info!.directApkUrl!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => _handleUpdate(null, info.directApkUrl),
                          child: const Text(
                            'Trouble updating from Play Store? Download Direct APK',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
