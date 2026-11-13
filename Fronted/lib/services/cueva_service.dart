import '../core/network/api_client.dart';

class CuevaService {
  Future<List<dynamic>> getCuevas() async {
    final data = await ApiClient.get('/cuevas');
    if (data is! List) throw Exception('La API devolvió una lista de cuevas inválida.');
    return data;
  }
  Future<void> crearCueva(Map<String, dynamic> datos) async { await ApiClient.post('/cuevas', body: datos); }
  Future<void> actualizarCueva(int id, Map<String, dynamic> datos) async { await ApiClient.put('/cuevas/$id', body: datos); }
  Future<void> eliminarCueva(int id) async { await ApiClient.delete('/cuevas/$id'); }
}
