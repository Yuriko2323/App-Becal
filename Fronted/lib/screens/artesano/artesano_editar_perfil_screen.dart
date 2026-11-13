import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../config/api_config.dart';
import 'dart:convert';

class ArtesanoEditarPerfilScreen extends StatefulWidget {
  final int idArtesano;
  final Map<String, dynamic> perfil;
  const ArtesanoEditarPerfilScreen({super.key, required this.idArtesano, required this.perfil});
  @override
  State<ArtesanoEditarPerfilScreen> createState() => _ArtesanoEditarPerfilScreenState();
}

class _ArtesanoEditarPerfilScreenState extends State<ArtesanoEditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: _s('nombre'));
  late final TextEditingController _apellidoPaterno = TextEditingController(text: _s('apellido_paterno'));
  late final TextEditingController _apellidoMaterno = TextEditingController(text: _s('apellido_materno'));
  late final TextEditingController _correo = TextEditingController(text: _s('correo'));
  late final TextEditingController _telefono = TextEditingController(text: _s('telefono'));
  late final TextEditingController _biografia = TextEditingController(text: _s('biografia'));
  late final TextEditingController _experiencia = TextEditingController(text: _s('anios_experiencia', '0'));
  Uint8List? _fotoBytes;
  String? _fotoNombre;
  bool _saving = false;

  ImageProvider? _fotoActual() {
    final raw = _s('foto_perfil').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return NetworkImage(raw);
    if (raw.startsWith('/')) return NetworkImage('${ApiConfig.baseUrl}$raw');
    try {
      final encoded = raw.startsWith('data:') && raw.contains(',') ? raw.substring(raw.indexOf(',') + 1) : raw;
      return MemoryImage(base64Decode(encoded.replaceAll(RegExp(r'\s+'), '')));
    } catch (_) { return null; }
  }

  String _s(String key, [String fallback = '']) => widget.perfil[key]?.toString() ?? fallback;
  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'], allowMultiple: false, withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.size > 5 * 1024 * 1024) {
        _message('La foto no puede superar 5 MB.', error: true);
        return;
      }
      if (file.bytes == null || file.bytes!.isEmpty) {
        _message('No se pudo leer la imagen seleccionada.', error: true);
        return;
      }
      setState(() { _fotoBytes = file.bytes; _fotoNombre = file.name; });
    } catch (e) { _message('No se pudo abrir el selector de archivos: $e', error: true); }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final correo = _correo.text.trim();
    if (!correo.contains('@') || !correo.contains('.')) { _message('Escribe un correo válido.', error: true); return; }
    setState(() => _saving = true);
    bool datosGuardados = false;
    try {
      await ApiClient.patch('/artesanos/${widget.idArtesano}/perfil', body: {
        'nombre': _nombre.text.trim(),
        'apellido_paterno': _optional(_apellidoPaterno.text),
        'apellido_materno': _optional(_apellidoMaterno.text),
        'correo': correo,
        'telefono': _optional(_telefono.text),
        'biografia': _optional(_biografia.text),
        'anios_experiencia': int.parse(_experiencia.text.trim()),
      });
      datosGuardados = true;
      if (_fotoBytes != null) {
        await ApiClient.uploadFile('/artesanos/${widget.idArtesano}/foto-perfil', bytes: _fotoBytes!, filename: _fotoNombre ?? 'perfil.jpg', fieldName: 'archivo');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado correctamente.'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final prefijo = datosGuardados ? 'Tus datos se guardaron, pero la foto no pudo actualizarse: ' : 'No se pudo guardar el perfil: ';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$prefijo$e'), backgroundColor: Colors.red.shade700));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  void _message(String value, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value), backgroundColor: error ? Colors.red.shade700 : null));
  }

  @override
  void dispose() {
    _nombre.dispose(); _apellidoPaterno.dispose(); _apellidoMaterno.dispose(); _correo.dispose(); _telefono.dispose(); _biografia.dispose(); _experiencia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar mi perfil')),
    body: Form(
      key: _formKey,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Column(children: [
          CircleAvatar(radius: 52, backgroundColor: Colors.deepOrange.shade100, backgroundImage: _fotoBytes != null ? MemoryImage(_fotoBytes!) : _fotoActual(), child: (_fotoBytes == null && _fotoActual() == null) ? const Icon(Icons.person, size: 58, color: Colors.deepOrange) : null),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _saving ? null : _pickPhoto, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Elegir foto de perfil')),
          if (_fotoNombre != null) Text(_fotoNombre!, maxLines: 1, overflow: TextOverflow.ellipsis),
          const Text('JPG, PNG o WEBP; máximo 5 MB.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        const SizedBox(height: 20),
        _field(_nombre, 'Nombre *', required: true, icon: Icons.person_outline),
        _field(_apellidoPaterno, 'Apellido paterno', icon: Icons.person_outline),
        _field(_apellidoMaterno, 'Apellido materno', icon: Icons.person_outline),
        _field(_correo, 'Correo de acceso *', required: true, keyboard: TextInputType.emailAddress, icon: Icons.email_outlined),
        _field(_telefono, 'Teléfono', keyboard: TextInputType.phone, icon: Icons.phone_outlined),
        _field(_biografia, 'Biografía del taller', maxLines: 4, icon: Icons.description_outlined),
        _field(_experiencia, 'Años de experiencia *', required: true, keyboard: TextInputType.number, icon: Icons.work_outline, validator: (v) { final n = int.tryParse((v ?? '').trim()); if (n == null || n < 0) return 'Escribe un número mayor o igual que cero.'; return null; }),
        const SizedBox(height: 4),
        const Text('La cueva, el puesto y los identificadores no se modifican desde el perfil.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Guardando...' : 'Guardar cambios'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50))),
      ]),
    ),
  );

  Widget _field(TextEditingController controller, String label, {bool required = false, TextInputType? keyboard, int maxLines = 1, IconData? icon, String? Function(String?)? validator}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(controller: controller, keyboardType: keyboard, maxLines: maxLines, decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon), border: const OutlineInputBorder()), validator: validator ?? (required ? (v) => v == null || v.trim().isEmpty ? 'Este campo es obligatorio.' : null : null)),
  );
}
