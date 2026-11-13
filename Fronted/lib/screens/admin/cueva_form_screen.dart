import 'package:flutter/material.dart';
import '../../services/cueva_service.dart';

class CuevaFormScreen extends StatefulWidget {
  final Map<String, dynamic>? cueva; // Si es null, es creación; si trae datos, es edición.

  const CuevaFormScreen({Key? key, this.cueva}) : super(key: key);

  @override
  State<CuevaFormScreen> createState() => _CuevaFormScreenState();
}

class _CuevaFormScreenState extends State<CuevaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CuevaService _cuevaService = CuevaService();

  late TextEditingController _nombreController;
  late TextEditingController _tipoController;
  late TextEditingController _direccionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cueva?['nombre_cueva'] ?? '');
    _tipoController = TextEditingController(text: widget.cueva?['tipo_cueva'] ?? '');
    _direccionController = TextEditingController(text: widget.cueva?['direccion_ubicacion'] ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _tipoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final datos = {
        'nombre_cueva': _nombreController.text.trim(),
        'tipo_cueva': _tipoController.text.trim(),
        'direccion_ubicacion': _direccionController.text.trim(),
      };

      if (widget.cueva == null) {
        await _cuevaService.crearCueva(datos);
      } else {
        await _cuevaService.actualizarCueva(widget.cueva!['id_cueva'], datos);
      }

      if (!mounted) return;
      Navigator.pop(context, true); // Retorna true para refrescar la lista anterior
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
    final esEdicion = widget.cueva != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Cueva' : 'Registrar Nueva Cueva'),
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
                  labelText: 'Nombre de la Cueva',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.terrain),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tipoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cueva',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección o Ubicación',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.save),
                      label: Text(esEdicion ? 'Actualizar Cueva' : 'Guardar Cueva'),
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