import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// URL central de FastAPI. Sobrescribir con --dart-define=API_BASE_URL=...
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.trim().isNotEmpty) {
      return _override.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (kIsWeb) return 'https://parador-becal.onrender.com';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://parador-becal.onrender.com'; // Emulador Android Studio
    }
    return 'https://parador-becal.onrender.com'; // Escritorio/iOS Simulator
  }
}
