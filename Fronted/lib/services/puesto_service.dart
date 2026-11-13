import '../core/network/api_client.dart';

class PuestoService {
  Future<List<dynamic>> getPuestos() async {
    final data = await ApiClient.get('/puestos');
    if (data is! List) throw Exception('La API devolvió una lista de puestos inválida.');
    return data;
  }
  Future<void> crearPuesto(Map<String, dynamic> datos) async { await ApiClient.post('/puestos', body: datos); }
  Future<void> actualizarPuesto(int id, Map<String, dynamic> datos) async { await ApiClient.put('/puestos/$id', body: datos); }
  Future<void> eliminarPuesto(int id) async { await ApiClient.delete('/puestos/$id'); }
}
