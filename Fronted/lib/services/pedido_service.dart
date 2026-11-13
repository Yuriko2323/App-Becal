import '../core/network/api_client.dart';
import '../models/pedido.dart';

class PedidoService {
  Future<int> obtenerIdEstadoInicial() async {
    final data = await ApiClient.get('/estados-pedido');
    if (data is! List) throw Exception('No se pudo consultar el catálogo de estados de pedido.');
    final estados = data.whereType<Map<String, dynamic>>().toList();
    if (estados.isEmpty) throw Exception('No hay estados de pedido registrados en la base de datos.');
    final pendiente = estados.where((e) => (e['nombre_estado'] ?? '').toString().toLowerCase().contains('pendiente')).toList();
    if (pendiente.isEmpty) {
      throw Exception('No existe un estado "Pendiente" en el catálogo. El administrador debe registrarlo antes de recibir pedidos.');
    }
    final elegido = pendiente.first;
    final id = elegido['id_estado_pedido'];
    if (id is int) return id;
    final parsed = int.tryParse('$id');
    if (parsed == null) throw Exception('El catálogo de estados no contiene un identificador válido.');
    return parsed;
  }

  Future<Map<String, dynamic>> crearPedido({required int idCliente, required int idProducto, int cantidad = 1, required int idEstadoPedido, String metodoPago = 'Efectivo', String? observaciones}) async {
    final data = await ApiClient.post('/clientes/$idCliente/crear-pedido', body: {
      'id_producto': idProducto, 'cantidad': cantidad, 'id_estado_pedido': idEstadoPedido,
      'metodo_pago': metodoPago, if (observaciones != null && observaciones.trim().isNotEmpty) 'observaciones': observaciones.trim(),
    });
    if (data is! Map<String, dynamic>) throw Exception('La API no devolvió el pedido creado.');
    return data;
  }
  Future<List<Pedido>> obtenerPedidosCliente(int idCliente) async => _lista('/clientes/$idCliente/pedidos-detallados');
  Future<List<Pedido>> obtenerPedidosArtesano(int idArtesano) async => _lista('/artesanos/$idArtesano/pedidos-detallados');
  Future<List<Pedido>> _lista(String path) async {
    final data = await ApiClient.get(path);
    if (data is! List) throw Exception('La API devolvió una lista de pedidos inválida.');
    return data.whereType<Map<String, dynamic>>().map(Pedido.fromJson).where((p) => p.idPedido > 0).toList();
  }
  Future<PedidoDetalle> obtenerDetallePedido(int idCliente, int idPedido) async {
    final data = await ApiClient.get('/clientes/$idCliente/pedidos-detallados/$idPedido');
    if (data is! Map<String, dynamic>) throw Exception('La API devolvió un detalle de pedido inválido.');
    return PedidoDetalle.fromJson(data);
  }
  Future<PedidoDetalle> obtenerDetallePedidoArtesano(int idArtesano, int idPedido) async {
    final data = await ApiClient.get('/artesanos/$idArtesano/pedidos-detallados/$idPedido');
    if (data is! Map<String, dynamic>) throw Exception('La API devolvió un detalle de pedido inválido.');
    return PedidoDetalle.fromJson(data);
  }
  Future<bool> cancelarPedido({required int idCliente, required int idPedido}) async {
    final data = await ApiClient.patch(
      '/clientes/$idCliente/pedidos/$idPedido/cancelar',
      body: <String, dynamic>{},
    );
    if (data is Map && data['cancelado'] == true) return true;
    throw Exception('La API no confirmó la cancelación del pedido.');
  }
}
