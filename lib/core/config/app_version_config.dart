class AppVersionConfig {
  /// Current client version name matching pubspec.yaml
  static const String currentVersion = '1.0.0';

  /// Current client build number matching pubspec.yaml (1.0.0+24)
  static const int currentBuildNumber = 24;

  /// Default Play Store link for PragatiX app
  static const String defaultPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=jjcet.PragatiX';

  /// Direct fallback download link if Play Store is unavailable
  static const String defaultDirectApkUrl =
      'https://pragatix.in/downloads/pragatix-latest.apk';
}

