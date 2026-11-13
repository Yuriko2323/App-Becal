import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// URL central de FastAPI conectada a Render
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.trim().isNotEmpty) {
      return _override.trim().replaceAll(RegExp(r'/+$'), '');
    }
    
    // 👇 Esta es la URL pública de tu backend en Render 👇
    return 'https://parador-becal.onrender.com';
  }
}
