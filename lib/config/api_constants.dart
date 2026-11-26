class ApiConstants {
  /// Override at build/run time for a physical device or web, e.g.
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000/api`.
  /// The default points the Android emulator at the host machine's localhost.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// Root of the server (without `/api`), where uploaded files are served.
  static String get serverRoot =>
      baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - 4)
          : baseUrl;

  /// Turns an image path returned by the backend into a loadable URL.
  /// Returns null for an empty path.
  static String? imageUrl(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$serverRoot${path.startsWith('/') ? '' : '/'}$path';
  }
}
