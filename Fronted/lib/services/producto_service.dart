import 'dart:typed_data';
import '../core/network/api_client.dart';
import '../models/foto_producto.dart';
import '../models/producto.dart';

class ProductoService {
  Future<List<Producto>> obtenerProductos() async {
    final data = await ApiClient.get('/catalogo/productos');
    if (data is! List) throw Exception('La API devolvió un catálogo con formato inesperado.');
    return data.whereType<Map<String, dynamic>>().map(Producto.fromJson).where((p) => p.activo).toList();
  }
  Future<List<Producto>> obtenerProductosArtesano(int idArtesano) async {
    final data = await ApiClient.get('/artesanos/$idArtesano/productos');
    if (data is! List) throw Exception('La API devolvió una lista de productos inválida.');
    return data.whereType<Map<String, dynamic>>().map(Producto.fromJson).toList();
  }
  Future<List<FotoProducto>> obtenerFotos(int idProducto) async {
    final data = await ApiClient.get('/productos/$idProducto/fotos');
    if (data is! List) throw Exception('La API devolvió una galería inválida.');
    return data.whereType<Map<String, dynamic>>().map(FotoProducto.fromJson).toList()..sort((a,b) => a.orden.compareTo(b.orden));
  }
  Future<dynamic> crearProducto(Map<String, dynamic> body) => ApiClient.post('/productos', body: body);
  Future<dynamic> subirImagen(int idProducto, Uint8List bytes, String nombreArchivo) =>
      ApiClient.uploadFile('/productos/$idProducto/imagen', bytes: bytes, filename: nombreArchivo, fieldName: 'archivo');
  Future<void> actualizarProducto(int id, Map<String, dynamic> body) async => ApiClient.patch('/productos/$id', body: body);
  Future<void> cambiarEstadoProducto(int id, bool activo) async =>
      ApiClient.patch('/productos/$id/estado', body: {'activo': activo});

  Future<void> desactivarProducto(int id) async =>
      cambiarEstadoProducto(id, false);

  Future<void> activarProducto(int id) async =>
      cambiarEstadoProducto(id, true);
}
