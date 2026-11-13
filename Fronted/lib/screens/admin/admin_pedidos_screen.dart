import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

/// Los pedidos de clientes son solicitudes; no son necesariamente ventas cobradas.
class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});
  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  late Future<List<Map<String, dynamic>>> _future = _fetch();

  Future<List<Map<String, dynamic>>> _fetch() async {
    final data = await ApiClient.get('/admin/pedidos-detallados?skip=0&limit=200');
    if (data is! List) throw Exception('La API no devolvió una lista de pedidos válida.');
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _refresh() async {
    final next = _fetch();
    setState(() => _future = next);
    try { await next; } catch (_) {}
  }

  int _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  double _num(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  String _text(dynamic value, [String fallback = 'No disponible']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
  String _money(dynamic value) => '\$${_num(value).toStringAsFixed(2)}';
  bool _cancelado(Map<String, dynamic> row) => _text(row['estado'], '').toLowerCase().contains('cancel');
  bool _pendiente(Map<String, dynamic> row) => _text(row['estado'], '').toLowerCase().contains('pendiente');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pedidos de clientes'),
      actions: [IconButton(onPressed: _refresh, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 10),
            Text('No se pudieron consultar los pedidos.\n${snapshot.error}', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ])));
        }
        final orders = snapshot.data ?? <Map<String, dynamic>>[];
        final pending = orders.where(_pendiente).length;
        final cancelled = orders.where(_cancelado).length;
        final total = orders.fold<double>(0, (sum, item) => sum + _num(item['total']));
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
            const Text('Solicitudes realizadas desde la app', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _stat('Pedidos', '${orders.length}', Icons.receipt_long),
              _stat('Pendientes', '$pending', Icons.hourglass_top),
              _stat('Cancelados', '$cancelled', Icons.cancel_outlined),
              _stat('Importe solicitado', _money(total), Icons.payments_outlined),
            ]),
            const SizedBox(height: 18),
            if (orders.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Column(children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Todavía no hay pedidos registrados.', textAlign: TextAlign.center),
              SizedBox(height: 4),
              Text('Cuando un cliente compre desde el catálogo, aparecerá aquí.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ])),
            ...orders.map((order) {
              final items = order['items'] is List ? (order['items'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
              final status = _text(order['estado'], 'Sin estado');
              final statusColor = _cancelado(order) ? Colors.red : _pendiente(order) ? Colors.orange.shade800 : Colors.green.shade700;
              return Card(margin: const EdgeInsets.only(bottom: 12), child: ExpansionTile(
                leading: CircleAvatar(backgroundColor: statusColor.withValues(alpha: .12), child: Icon(Icons.shopping_bag_outlined, color: statusColor)),
                title: Text('Pedido #${_int(order['id_pedido'])} · ${_money(order['total'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${_text(order['fecha_solicitud'], 'Sin fecha')}\n${_text(order['cliente'], 'Cliente sin nombre')}'),
                trailing: Chip(label: Text(status), visualDensity: VisualDensity.compact),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _detail('Correo cliente', _text(order['cliente_correo'])),
                  _detail('Teléfono cliente', _text(order['cliente_telefono'])),
                  _detail('Artesano', _text(order['artesano'])),
                  _detail('Teléfono artesano', _text(order['artesano_telefono'])),
                  _detail('Puesto', '${_text(order['puesto'])} · ${_text(order['puesto_numero'], 'sin número')}'),
                  const Divider(height: 20),
                  const Align(alignment: Alignment.centerLeft, child: Text('Productos del pedido', style: TextStyle(fontWeight: FontWeight.bold))),
                  if (items.isEmpty) const ListTile(dense: true, title: Text('Este pedido no tiene partidas registradas.')),
                  ...items.map((item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${_int(item['cantidad'])} × ${_text(item['producto'], 'Producto')}'),
                    subtitle: Text('${_money(item['precio_unitario'])} por unidad'),
                    trailing: Text(_money(item['subtotal']), style: const TextStyle(fontWeight: FontWeight.w600)),
                  )),
                  _detail('Anticipo', _money(order['anticipo'])),
                  if (_text(order['observaciones'], '').isNotEmpty) _detail('Observaciones / pago', _text(order['observaciones'], '')),
                  const SizedBox(height: 4),
                  const Text('Un pedido se muestra aquí; solo aparece en Ventas y Reportes cuando se registra una venta en caja.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ));
            }),
          ]),
        );
      },
    ),
  );

  Widget _stat(String title, String value, IconData icon) => SizedBox(width: 155, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(fontSize: 12))]))));
  Widget _detail(String label, String value) => Padding(padding: const EdgeInsets.only(top: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 130, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value))]));
}
