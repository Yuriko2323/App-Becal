import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// URL central de FastAPI. Sobrescribir con --dart-define=API_BASE_URL=...
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.trim().isNotEmpty) {
      return _override.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.33.59:8000'; // Emulador Android Studio
    }
    return 'http://localhost:8000'; // Escritorio/iOS Simulator
  }
}
