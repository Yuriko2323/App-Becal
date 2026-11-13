import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import 'admin_artesano_form_screen.dart';
import 'admin_artesano_detalle_screen.dart';

class AdminArtesanosScreen extends StatefulWidget {
  const AdminArtesanosScreen({super.key});

  @override
  State<AdminArtesanosScreen> createState() => _AdminArtesanosScreenState();
}

class _AdminArtesanosScreenState extends State<AdminArtesanosScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _artesanos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiClient.get('/admin/artesanos?skip=0&limit=200');
      if (data is! List) {
        throw Exception('La API no devolvió una lista de artesanos.');
      }
      if (!mounted) return;
      setState(() {
        _artesanos = data.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  int? _id(Map<String, dynamic> item) {
    final value = item['id_artesano'];
    return value is int ? value : int.tryParse('$value');
  }

  Future<void> _openDetail(Map<String, dynamic> artisan) async {
    final id = _id(artisan);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La API no devolvió el ID del artesano.')),
      );
      return;
    }
    await Navigator.push<void>(context, MaterialPageRoute(
      builder: (_) => AdminArtesanoDetalleScreen(idArtesano: id),
    ));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cuentas de artesanos'),
      backgroundColor: Colors.brown.shade700,
      foregroundColor: Colors.white,
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Actualizar')],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('No se pudieron cargar los artesanos.\n$_error', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Reintentar')),
                ]),
              ))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: const EdgeInsets.all(12), children: [
                  Card(
                    color: Colors.brown.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Cuentas registradas: ${_artesanos.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  if (_artesanos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Todavía no hay cuentas de artesanos. Usa “Crear cuenta” para registrar la primera.', textAlign: TextAlign.center),
                    ),
                  ..._artesanos.map((a) {
                    final active = a['activo'] != false && a['usuario_activo'] != false;
                    final name = '${a['nombre'] ?? ''} ${a['apellido_paterno'] ?? ''} ${a['apellido_materno'] ?? ''}'.trim();
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: active ? Colors.green.shade100 : Colors.grey.shade300,
                          child: Icon(Icons.person, color: active ? Colors.green.shade800 : Colors.grey.shade700),
                        ),
                        title: Text(name.isEmpty ? 'Artesano #${a['id_artesano'] ?? '—'}' : name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Correo: ${a['correo'] ?? 'No disponible'}\nID: ${a['id_artesano'] ?? '—'} · ${active ? 'Activo' : 'Inactivo'}\nExperiencia: ${a['anios_experiencia'] ?? 0} años'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDetail(a),
                      ),
                    );
                  }),
                ]),
              ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        final created = await Navigator.push<bool>(context,
            MaterialPageRoute(builder: (_) => const AdminArtesanoFormScreen()));
        if (created == true && mounted) await _load();
      },
      icon: const Icon(Icons.person_add),
      label: const Text('Crear cuenta'),
    ),
  );
}
