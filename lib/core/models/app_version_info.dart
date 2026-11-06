class AppVersionInfo {
  final String platform;
  final String minVersion;
  final int minBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final bool forceUpdate;
  final bool updateRequired;
  final String title;
  final String message;
  final String? releaseNotes;
  final String? playStoreUrl;
  final String? appStoreUrl;
  final String? directApkUrl;

  AppVersionInfo({
    required this.platform,
    required this.minVersion,
    required this.minBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.forceUpdate,
    required this.updateRequired,
    required this.title,
    required this.message,
    this.releaseNotes,
    this.playStoreUrl,
    this.appStoreUrl,
    this.directApkUrl,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      platform: json['platform'] ?? 'ANDROID',
      minVersion: json['minVersion'] ?? '1.0.0',
      minBuildNumber: json['minBuildNumber'] ?? 0,
      latestVersion: json['latestVersion'] ?? '1.0.0',
      latestBuildNumber: json['latestBuildNumber'] ?? 0,
      forceUpdate: json['forceUpdate'] ?? true,
      updateRequired: json['updateRequired'] ?? false,
      title: json['title'] ?? 'Update Required',
      message: json['message'] ??
          'A new update is available. Please update the app to continue.',
      releaseNotes: json['releaseNotes'],
      playStoreUrl: json['playStoreUrl'],
      appStoreUrl: json['appStoreUrl'],
      directApkUrl: json['directApkUrl'],
    );
  }
}

