import '../core/network/api_client.dart';
import '../models/usuario.dart';

class AuthService {
  Future<Usuario> login(String correo, String contrasena) async {
    final data = await ApiClient.post('/login', body: {
      'correo': correo.trim(),
      'contrasena': contrasena,
    });
    if (data is! Map<String, dynamic>) {
      throw Exception('La API devolvió una respuesta de inicio de sesión inesperada.');
    }
    return Usuario.fromJson(data);
  }

  Future<bool> registrarCliente({
    required String correo,
    required String contrasena,
    required String tipoCliente,
    String nombre = 'Usuario',
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
    String? nacionalidad,
    String? idiomaPreferido,
  }) async {
    await ApiClient.post('/registro/cliente', body: {
      'nombre': nombre.trim(),
      'correo': correo.trim(),
      'contrasena': contrasena,
      'tipo_cliente': tipoCliente,
      if (apellidoPaterno != null && apellidoPaterno.trim().isNotEmpty) 'apellido_p': apellidoPaterno.trim(),
      if (apellidoMaterno != null && apellidoMaterno.trim().isNotEmpty) 'apellido_m': apellidoMaterno.trim(),
      if (telefono != null && telefono.trim().isNotEmpty) 'telefono': telefono.trim(),
      if (nacionalidad != null && nacionalidad.trim().isNotEmpty) 'nacionalidad': nacionalidad.trim(),
      if (idiomaPreferido != null && idiomaPreferido.trim().isNotEmpty) 'idioma_preferido': idiomaPreferido.trim(),
    });
    return true;
  }
}
