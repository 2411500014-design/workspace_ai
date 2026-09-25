import 'package:flutter/foundation.dart';

/// Where the Purnara API lives.
///
/// Priority: the address saved in Settings, then `--dart-define=API_BASE_URL=...`,
/// then a sensible default per platform. The Android emulator reaches the host
/// computer through 10.0.2.2; a real phone needs the computer's LAN address,
/// entered in Settings.
class AppConfig {
  static const String version = '0.1.0';
  static const String _defined = String.fromEnvironment('API_BASE_URL');

  static String get defaultApiBaseUrl {
    if (_defined.isNotEmpty) return _trim(_defined);
    if (kIsWeb) {
      final base = Uri.base;
      if (base.scheme == 'http' || base.scheme == 'https') {
        // A release build is served by the backend itself, on whatever address the
        // browser used (localhost, or the laptop's LAN address from a phone).
        if (kReleaseMode || base.port == 8000) return base.origin;
        // `flutter run` serves the app on its own port; the API is on 8000 of the same host.
        return '${base.scheme}://${base.host}:8000';
      }
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static String normalize(String url) => _trim(url.trim());

  static String _trim(String url) => url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
