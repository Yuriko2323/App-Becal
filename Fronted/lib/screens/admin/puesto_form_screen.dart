import 'package:flutter/material.dart';
import '../../services/puesto_service.dart';

class PuestoFormScreen extends StatefulWidget {
  final Map<String, dynamic>? puesto;

  const PuestoFormScreen({Key? key, this.puesto}) : super(key: key);

  @override
  State<PuestoFormScreen> createState() => _PuestoFormScreenState();
}

class _PuestoFormScreenState extends State<PuestoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PuestoService _puestoService = PuestoService();

  late TextEditingController _nombreController;
  late TextEditingController _numeroController;
  late TextEditingController _sectorController;
  late TextEditingController _categoriaController;
  
  String _estadoSeleccionado = 'Activo';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.puesto?['nombre_puesto'] ?? '');
    _numeroController = TextEditingController(text: widget.puesto?['numero_puesto'] ?? '');
    _sectorController = TextEditingController(text: widget.puesto?['ubicacion_sector'] ?? '');
    _categoriaController = TextEditingController(text: widget.puesto?['categoria'] ?? '');
    _estadoSeleccionado = widget.puesto?['estado'] ?? 'Activo';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _numeroController.dispose();
    _sectorController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final datos = {
        'nombre_puesto': _nombreController.text.trim(),
        'numero_puesto': _numeroController.text.trim(),
        'ubicacion_sector': _sectorController.text.trim(),
        'categoria': _categoriaController.text.trim(),
        'estado': _estadoSeleccionado,
      };

      if (widget.puesto == null) {
        await _puestoService.crearPuesto(datos);
      } else {
        await _puestoService.actualizarPuesto(widget.puesto!['id_puesto'], datos);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.puesto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Puesto' : 'Registrar Nuevo Puesto'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Puesto / Local',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número de Puesto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _sectorController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación o Sector',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado del Puesto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                items: const [
                  DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'Mantenimiento', child: Text('Mantenimiento')),
                ],
                onChanged: (val) => setState(() => _estadoSeleccionado = val!),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.save),
                      label: Text(esEdicion ? 'Actualizar Puesto' : 'Guardar Puesto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}