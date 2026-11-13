import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class AdminVendedorDetalleScreen extends StatefulWidget {
  final int idVendedor;
  const AdminVendedorDetalleScreen({super.key, required this.idVendedor});

  @override
  State<AdminVendedorDetalleScreen> createState() => _AdminVendedorDetalleScreenState();
}

class _AdminVendedorDetalleScreenState extends State<AdminVendedorDetalleScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiClient.get('/admin/vendedores/${widget.idVendedor}');
      if (result is! Map) throw Exception('La API devolvió un detalle con formato inesperado.');
      if (!mounted) return;
      setState(() { _data = Map<String, dynamic>.from(result); _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _value(String key, [String fallback = 'No registrado']) {
    final value = _data?[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: Colors.brown.shade700), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)))]),
      const Divider(height: 24),
      ...children,
    ])),
  );

  Widget _field(String label, String value, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (icon != null) ...[Icon(icon, size: 19, color: Colors.grey.shade700), const SizedBox(width: 10)],
      SizedBox(width: icon == null ? 136 : 126, child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
      Expanded(child: SelectableText(value.isEmpty ? 'No registrado' : value)),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Vendedor #${widget.idVendedor}'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Actualizar')]),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('No se pudo cargar la ficha del vendedor.\n$_error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Reintentar')),
              ])))
            : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
                Center(child: CircleAvatar(radius: 38, backgroundColor: Colors.purple.shade100, child: Icon(Icons.badge_outlined, size: 42, color: Colors.purple.shade700))),
                const SizedBox(height: 12),
                Center(child: Text('${_value('nombre', '')} ${_value('apellido_paterno', '')} ${_value('apellido_materno', '')}'.trim(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                const SizedBox(height: 4),
                Center(child: Chip(label: Text(_data?['activo'] == true && _data?['usuario_activo'] != false ? 'Cuenta activa' : 'Cuenta inactiva'))),
                const SizedBox(height: 12),
                _section('Datos de acceso', Icons.key_outlined, [
                  _field('ID de usuario', _value('id_usuario'), icon: Icons.numbers),
                  _field('Correo', _value('correo'), icon: Icons.email_outlined),
                  _field('Acceso del usuario', _data?['usuario_activo'] == true ? 'Activo' : 'Inactivo', icon: Icons.verified_user_outlined),
                ]),
                _section('Información personal y laboral', Icons.person_outline, [
                  _field('ID de vendedor', _value('id_vendedor')),
                  _field('Nombre', _value('nombre')),
                  _field('Apellido paterno', _value('apellido_paterno')),
                  _field('Apellido materno', _value('apellido_materno')),
                  _field('Teléfono', _value('telefono'), icon: Icons.phone_outlined),
                  _field('Rol', _value('rol')),
                  _field('Estado del perfil', _data?['vendedor_activo'] == true ? 'Activo' : 'Inactivo'),
                ]),
                _section('Asignaciones de puesto', Icons.storefront_outlined, _asignaciones()),
              ])),
  );

  List<Widget> _asignaciones() {
    final raw = _data?['asignaciones'];
    if (raw is! List || raw.isEmpty) {
      return [const Text('No hay asignaciones de puesto registradas.')];
    }
    return raw.whereType<Map>().map((item) {
      final a = Map<String, dynamic>.from(item);
      final title = a['nombre_puesto']?.toString().trim().isNotEmpty == true
          ? a['nombre_puesto'].toString()
          : 'Puesto #${a['id_puesto'] ?? '—'}';
      final subtitle = [
        'Estado: ${a['estado'] ?? 'No especificado'}',
        'Turno: ${a['turno'] ?? 'No especificado'}',
        'Inicio: ${a['fecha_inicio'] ?? 'No registrada'}',
        'Fin: ${a['fecha_fin'] ?? 'Vigente'}',
      ].join('\n');
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.store_outlined),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
      );
    }).toList();
  }
}
