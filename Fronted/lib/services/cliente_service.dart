import '../core/network/api_client.dart';
import '../models/cliente.dart';

class ClienteService {
  Future<Cliente> obtenerCliente(int idCliente) async {
    final data = await ApiClient.get('/clientes/$idCliente');
    if (data is! Map<String, dynamic>) throw Exception('Respuesta de perfil inválida.');
    return Cliente.fromJson(data);
  }

  Future<String> obtenerNombreCliente(int idCliente) async {
    try { return (await obtenerCliente(idCliente)).nombreCompleto; }
    catch (_) { return 'Cliente'; }
  }

  Future<bool> actualizarPerfil({
    required int idCliente, required String nombre, required String apellidoPaterno,
    required String apellidoMaterno, required String telefono, required String nacionalidad,
    required String idiomaPreferido, String? fotoPerfilBase64,
  }) async {
    final body = <String, dynamic>{
      'nombre': nombre.trim(), 'apellido_p': apellidoPaterno.trim(),
      'apellido_m': apellidoMaterno.trim(), 'telefono': telefono.trim(),
      'nacionalidad': nacionalidad.trim(), 'idioma_preferido': idiomaPreferido.trim(),
    };
    if (fotoPerfilBase64 != null && fotoPerfilBase64.isNotEmpty) body['foto_perfil'] = fotoPerfilBase64;
    await ApiClient.patch('/clientes/$idCliente', body: body);
    return true;
  }
}
