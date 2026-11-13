import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class AdminVentasScreen extends StatefulWidget {
  const AdminVentasScreen({super.key});
  @override
  State<AdminVentasScreen> createState() => _AdminVentasScreenState();
}

class _AdminVentasScreenState extends State<AdminVentasScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _ventas = [];
  double _totalGeneral = 0;
  int _cantidadVentas = 0;
  int _totalPiezas = 0;

  @override
  void initState() { super.initState(); _load(); }

  int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
  double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final responses = await Future.wait([
        ApiClient.get('/ventas?skip=0&limit=200'),
        ApiClient.get('/detalle-ventas?skip=0&limit=200'),
        ApiClient.get('/clientes?skip=0&limit=200'),
        ApiClient.get('/vendedores?skip=0&limit=200'),
        ApiClient.get('/puestos?skip=0&limit=200'),
      ]);
      for (final response in responses) { if (response is! List) throw Exception('Una ruta de ventas devolvió una respuesta no válida.'); }
      final ventas = (responses[0] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final detalles = (responses[1] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final clientes = (responses[2] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final vendedores = (responses[3] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final puestos = (responses[4] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final clienteMap = {for (final x in clientes) _int(x['id_cliente']): x};
      final vendedorMap = {for (final x in vendedores) _int(x['id_vendedor']): x};
      final puestoMap = {for (final x in puestos) _int(x['id_puesto']): x};
      final detallePorVenta = <int, List<Map<String, dynamic>>>{};
      for (final d in detalles) {
        final idVenta = _int(d['id_venta']);
        if (idVenta != null) (detallePorVenta[idVenta] ??= []).add(d);
      }
      for (final venta in ventas) {
        final id = _int(venta['id_venta']);
        final items = detallePorVenta[id] ?? [];
        final total = items.fold<double>(0, (sum, d) => sum + (_num(d['cantidad']) * _num(d['precio_unitario'])));
        final piezas = items.fold<int>(0, (sum, d) => sum + (_int(d['cantidad']) ?? 0));
        final cliente = clienteMap[_int(venta['id_cliente'])];
        final vendedor = vendedorMap[_int(venta['id_vendedor'])];
        final puesto = puestoMap[_int(venta['id_puesto'])];
        venta['_total_calculado'] = total;
        venta['_piezas'] = piezas;
        venta['_cliente_nombre'] = '${cliente?['nombre'] ?? ''} ${cliente?['apellido_p'] ?? ''}'.trim();
        venta['_vendedor_nombre'] = '${vendedor?['nombre'] ?? ''} ${vendedor?['apellido_paterno'] ?? ''}'.trim();
        venta['_puesto_nombre'] = puesto?['nombre_puesto'] ?? 'Puesto #${venta['id_puesto'] ?? '?'}';
      }
      ventas.sort((a, b) => (_int(b['id_venta']) ?? 0).compareTo(_int(a['id_venta']) ?? 0));
      if (!mounted) return;
      setState(() {
        _ventas = ventas;
        _totalGeneral = ventas.fold<double>(0, (sum, v) => sum + _num(v['_total_calculado']));
        _cantidadVentas = ventas.length;
        _totalPiezas = ventas.fold<int>(0, (sum, v) => sum + (_int(v['_piezas']) ?? 0));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ventas y reportes'), backgroundColor: Colors.brown.shade700, foregroundColor: Colors.white, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Actualizar')]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('No se pudieron cargar las ventas.\n$_error', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Reintentar'))])))
      : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 10, runSpacing: 10, children: [
            _stat('Ventas registradas', '$_cantidadVentas', Icons.receipt_long),
            _stat('Importe calculado', _money(_totalGeneral), Icons.payments),
            _stat('Piezas vendidas', '$_totalPiezas', Icons.inventory_2),
          ]),
          const SizedBox(height: 18),
          const Text('Historial de ventas', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_ventas.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Todavía no hay ventas registradas.', textAlign: TextAlign.center)),
          ..._ventas.map((v) => Card(child: ExpansionTile(
            leading: CircleAvatar(backgroundColor: Colors.brown.shade100, child: const Icon(Icons.point_of_sale, color: Colors.brown)),
            title: Text('Venta #${v['id_venta']} · ${_money(_num(v['_total_calculado']))}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${v['fecha_hora'] ?? 'Fecha no disponible'}\n${v['_cliente_nombre'].toString().isEmpty ? 'Cliente sin nombre' : v['_cliente_nombre']}'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _detail('Vendedor', v['_vendedor_nombre'].toString().isEmpty ? 'Sin nombre' : v['_vendedor_nombre'].toString()),
              _detail('Puesto', v['_puesto_nombre'].toString()),
              _detail('Método de pago', (v['metodo_pago'] ?? 'No especificado').toString()),
              _detail('Piezas', '${v['_piezas']}'),
              _detail('Total', _money(_num(v['_total_calculado']))),
            ],
          ))),
          const SizedBox(height: 12),
          const Text('El total se calcula sumando cantidad × precio_unitario de los detalles de cada venta; no se inventa un importe si no hay detalles.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ])),
  );

  Widget _stat(String title, String value, IconData icon) => SizedBox(width: 155, child: Card(color: Colors.brown.shade50, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Colors.brown.shade700), const SizedBox(height: 10), Text(title, style: const TextStyle(fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]))));
  Widget _detail(String label, String value) => Padding(padding: const EdgeInsets.only(top: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value))]));
}
