import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../widgets/loading_widget.dart';
import 'artesano_editar_perfil_screen.dart';

/// Resumen de perfil del artesano; la edición se realiza en una pantalla aparte.
class ArtesanoPerfilScreen extends StatefulWidget {
  final int idArtesano;
  const ArtesanoPerfilScreen({super.key, required this.idArtesano});
  @override
  State<ArtesanoPerfilScreen> createState() => _ArtesanoPerfilScreenState();
}

class _ArtesanoPerfilScreenState extends State<ArtesanoPerfilScreen> {
  late Future<Map<String, dynamic>> _future = _cargarPerfil();

  Future<Map<String, dynamic>> _cargarPerfil() async {
    final result = await ApiClient.get('/artesanos/${widget.idArtesano}/perfil');
    if (result is! Map) throw Exception('La API devolvió un perfil inválido.');
    return Map<String, dynamic>.from(result);
  }

  Future<void> _recargar() async {
    final next = _cargarPerfil();
    setState(() => _future = next);
    try { await next; } catch (_) {}
  }

  Future<void> _editar(Map<String, dynamic> perfil) async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => ArtesanoEditarPerfilScreen(idArtesano: widget.idArtesano, perfil: perfil),
    ));
    if (result == true && mounted) await _recargar();
  }

  ImageProvider? _imageProvider(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return NetworkImage(raw);
    if (raw.startsWith('/')) return NetworkImage('${ApiConfig.baseUrl}$raw');
    try {
      final encoded = raw.startsWith('data:') && raw.contains(',') ? raw.substring(raw.indexOf(',') + 1) : raw;
      return MemoryImage(base64Decode(encoded.replaceAll(RegExp(r'\s+'), '')));
    } catch (_) { return null; }
  }

  String _value(dynamic value, [String fallback = 'No especificado']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingWidget();
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 44),
        const SizedBox(height: 12),
        Text('No se pudo cargar tu perfil.\n${snapshot.error}', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _recargar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
      ])));
      final p = snapshot.data!;
      final nombre = '${_value(p['nombre'], '')} ${_value(p['apellido_paterno'], '')} ${_value(p['apellido_materno'], '')}'.trim();
      final avatar = _imageProvider(p['foto_perfil']?.toString());
      final experiencia = p['anios_experiencia']?.toString() ?? '0';
      return RefreshIndicator(
        onRefresh: _recargar,
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
          Text('Mi perfil', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            CircleAvatar(radius: 48, backgroundColor: Colors.deepOrange.shade100, backgroundImage: avatar, child: avatar == null ? const Icon(Icons.person, size: 56, color: Colors.deepOrange) : null),
            const SizedBox(height: 12),
            Text(nombre.isEmpty ? 'Artesano de Bécal' : nombre, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_value(p['correo']), style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              Chip(avatar: const Icon(Icons.work_outline, size: 18), label: Text('$experiencia años de experiencia')),
              Chip(avatar: const Icon(Icons.terrain, size: 18), label: Text(_value(p['cueva'], 'Sin cueva'))),
              Chip(avatar: const Icon(Icons.storefront_outlined, size: 18), label: Text(_value(p['puesto'], 'Sin puesto'))),
            ]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _editar(p), icon: const Icon(Icons.edit_outlined), label: const Text('Editar mi perfil'))),
          ]))),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Resumen de mi taller', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _detail('Teléfono', _value(p['telefono'])),
            _detail('Años de experiencia', experiencia),
            _detail('Fecha de registro', _value(p['fecha_registro'])),
            _detail('Biografía', _value(p['biografia'])),
          ]))),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Datos de asignación', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _detail('ID de artesano', '${p['id_artesano'] ?? widget.idArtesano}'),
            _detail('Cueva', _value(p['cueva'])),
            _detail('Dirección de cueva', _value(p['direccion_cueva'])),
            _detail('Puesto', _value(p['puesto'])),
            _detail('Número de puesto', _value(p['numero_puesto'])),
            const SizedBox(height: 6),
            const Text('Los identificadores y la asignación de cueva y puesto se administran desde el panel correspondiente.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]))),
        ]),
      );
    },
  );

  Widget _detail(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: Text(label, style: TextStyle(color: Colors.grey.shade700)),), Expanded(child: Text(value))]));
}
