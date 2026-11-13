import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class AdminArtesanoFormScreen extends StatefulWidget {
  const AdminArtesanoFormScreen({super.key});

  @override
  State<AdminArtesanoFormScreen> createState() => _AdminArtesanoFormScreenState();
}

class _AdminArtesanoFormScreenState extends State<AdminArtesanoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidoP = TextEditingController();
  final _apellidoM = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _telefono = TextEditingController();
  final _biografia = TextEditingController();
  final _experiencia = TextEditingController(text: '0');
  List<Map<String, dynamic>> _cuevas = [];
  List<Map<String, dynamic>> _puestos = [];
  int? _idCueva;
  int? _idPuesto;
  bool _loadingOptions = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/cuevas?skip=0&limit=200'),
        ApiClient.get('/puestos?skip=0&limit=200'),
      ]);
      if (results[0] is! List || results[1] is! List) {
        throw Exception('La API no devolvió los catálogos de cuevas y puestos.');
      }
      if (!mounted) return;
      setState(() {
        _cuevas = (results[0] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _puestos = (results[1] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _idCueva = _cuevas.isNotEmpty ? _toInt(_cuevas.first['id_cueva']) : null;
        _idPuesto = _puestos.isNotEmpty ? _toInt(_puestos.first['id_puesto']) : null;
        _loadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingOptions = false; _loadError = e.toString(); });
    }
  }

  int? _toInt(dynamic value) => value is int ? value : int.tryParse('$value');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCueva == null || _idPuesto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero registra al menos una cueva y un puesto.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final experience = int.tryParse(_experiencia.text.trim()) ?? 0;
      final result = await ApiClient.post('/registro/artesano', body: {
        'nombre': _nombre.text.trim(),
        'apellido_paterno': _apellidoP.text.trim().isEmpty ? null : _apellidoP.text.trim(),
        'apellido_materno': _apellidoM.text.trim().isEmpty ? null : _apellidoM.text.trim(),
        'correo': _correo.text.trim(),
        'contrasena': _contrasena.text,
        'telefono': _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
        'biografia': _biografia.text.trim().isEmpty ? null : _biografia.text.trim(),
        'anios_experiencia': experience,
        'id_cueva': _idCueva,
        'id_puesto': _idPuesto,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cuenta de artesano creada. ID: ${result is Map ? result['id_artesano'] ?? 'OK' : 'OK'}')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo crear la cuenta: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose(); _apellidoP.dispose(); _apellidoM.dispose(); _correo.dispose();
    _contrasena.dispose(); _telefono.dispose(); _biografia.dispose(); _experiencia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta de artesano'), backgroundColor: Colors.brown.shade700, foregroundColor: Colors.white),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('No se pudieron cargar cuevas y puestos.\n$_loadError', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: () { setState(() { _loadingOptions = true; _loadError = null; }); _loadOptions(); }, child: const Text('Reintentar'))])))
              : (_cuevas.isEmpty || _puestos.isEmpty)
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Para crear una cuenta de artesano necesitas registrar primero al menos una cueva y un puesto en el panel de administración.', textAlign: TextAlign.center)))
                  : Form(
                      key: _formKey,
                      child: ListView(padding: const EdgeInsets.all(16), children: [
                        const Text('Datos personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _field(_nombre, 'Nombre', required: true),
                        _field(_apellidoP, 'Apellido paterno'),
                        _field(_apellidoM, 'Apellido materno'),
                        _field(_telefono, 'Teléfono', keyboardType: TextInputType.phone),
                        _field(_biografia, 'Biografía', maxLines: 3),
                        _field(_experiencia, 'Años de experiencia', keyboardType: TextInputType.number, required: true, validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) < 0 ? 'Ingresa un número igual o mayor que cero' : null),
                        const SizedBox(height: 20),
                        const Text('Datos de acceso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _field(_correo, 'Correo electrónico', required: true, keyboardType: TextInputType.emailAddress, validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Ingresa un correo válido' : null),
                        _field(_contrasena, 'Contraseña temporal', required: true, obscure: true, validator: (v) => (v ?? '').length < 8 ? 'Usa al menos 8 caracteres' : null),
                        const SizedBox(height: 20),
                        const Text('Asignación al parador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(value: _idCueva, decoration: const InputDecoration(labelText: 'Cueva / taller', border: OutlineInputBorder()), items: _cuevas.map((c) => DropdownMenuItem(value: _toInt(c['id_cueva']), child: Text('${c['nombre_cueva'] ?? 'Cueva'} (#${c['id_cueva']})'))).toList(), onChanged: (v) => setState(() => _idCueva = v)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(value: _idPuesto, decoration: const InputDecoration(labelText: 'Puesto / local', border: OutlineInputBorder()), items: _puestos.map((p) => DropdownMenuItem(value: _toInt(p['id_puesto']), child: Text('${p['nombre_puesto'] ?? 'Puesto'} (#${p['id_puesto']})'))).toList(), onChanged: (v) => setState(() => _idPuesto = v)),
                        const SizedBox(height: 24),
                        FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add_alt_1), label: Text(_saving ? 'Creando cuenta...' : 'Crear cuenta de artesano'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50))),
                        const SizedBox(height: 12),
                        const Text('La contraseña se envía a la API, que debe guardarla mediante hash. Comparte la contraseña temporal con el artesano de forma segura.', style: TextStyle(color: Colors.grey)),
                      ]),
                    ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool required = false, bool obscure = false, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller, obscureText: obscure, maxLines: obscure ? 1 : maxLines, keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validator ?? (required ? (v) => (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null : null),
      ),
    );
  }
}
