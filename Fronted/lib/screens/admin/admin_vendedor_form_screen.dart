import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class AdminVendedorFormScreen extends StatefulWidget {
  const AdminVendedorFormScreen({super.key});
  @override
  State<AdminVendedorFormScreen> createState() => _AdminVendedorFormScreenState();
}

class _AdminVendedorFormScreenState extends State<AdminVendedorFormScreen> {
  final _key = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidoP = TextEditingController();
  final _apellidoM = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _telefono = TextEditingController();
  String _rol = 'Cajero';
  bool _saving = false;

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final result = await ApiClient.post('/registro/vendedor', body: {
        'nombre': _nombre.text.trim(),
        'apellido_paterno': _apellidoP.text.trim().isEmpty ? null : _apellidoP.text.trim(),
        'apellido_materno': _apellidoM.text.trim().isEmpty ? null : _apellidoM.text.trim(),
        'correo': _correo.text.trim(),
        'contrasena': _contrasena.text,
        'telefono': _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
        'rol': _rol,
      });
      if (!mounted) return;
      final id = result is Map ? result['id_vendedor'] : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cuenta creada${id == null ? '' : ' (vendedor #$id)'}.'), duration: const Duration(seconds: 4)));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo crear la cuenta: $e'), backgroundColor: Colors.red.shade700));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose(); _apellidoP.dispose(); _apellidoM.dispose(); _correo.dispose(); _contrasena.dispose(); _telefono.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear cuenta de vendedor'), backgroundColor: Colors.brown.shade700, foregroundColor: Colors.white),
    body: Form(key: _key, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Datos personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _field(_nombre, 'Nombre', required: true),
      _field(_apellidoP, 'Apellido paterno'),
      _field(_apellidoM, 'Apellido materno'),
      _field(_telefono, 'Teléfono', keyboard: TextInputType.phone),
      const SizedBox(height: 16),
      const Text('Datos de acceso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _field(_correo, 'Correo electrónico', required: true, keyboard: TextInputType.emailAddress, validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Ingresa un correo válido' : null),
      _field(_contrasena, 'Contraseña temporal', required: true, obscure: true, validator: (v) => (v ?? '').length < 8 ? 'Usa al menos 8 caracteres' : null),
      DropdownButtonFormField<String>(value: _rol, decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
        items: const [DropdownMenuItem(value: 'Cajero', child: Text('Cajero')), DropdownMenuItem(value: 'Gerente', child: Text('Gerente')), DropdownMenuItem(value: 'Mostrador', child: Text('Mostrador'))], onChanged: (v) { if (v != null) setState(() => _rol = v); }),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: _saving ? null : _save,
        icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add_alt_1),
        label: Text(_saving ? 'Creando cuenta...' : 'Crear cuenta de vendedor'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50))),
      const SizedBox(height: 12),
      const Text('La contraseña no se puede recuperar después. Entrega la contraseña temporal directamente al vendedor y pide que la cambie al tener esa función disponible.', style: TextStyle(color: Colors.grey)),
    ])),
  );

  Widget _field(TextEditingController controller, String label, {bool required = false, bool obscure = false, TextInputType? keyboard, String? Function(String?)? validator}) => Padding(
    padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controller, obscureText: obscure, keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: validator ?? (required ? (v) => (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null : null)),
  );
}
