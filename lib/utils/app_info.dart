class AppInfo {
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String appName = 'Stika Rider';
  
  static String get displayVersion => 'v$version ($buildNumber)';
  
  static Map<String, dynamic> get info => {
    'version': version,
    'build': buildNumber,
    'name': appName,
  };
}