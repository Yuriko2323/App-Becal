import 'package:flutter/material.dart';
import '../../services/cueva_service.dart';
import 'cueva_form_screen.dart';

class AdminCuevasScreen extends StatefulWidget {
  const AdminCuevasScreen({Key? key}) : super(key: key);

  @override
  State<AdminCuevasScreen> createState() => _AdminCuevasScreenState();
}

class _AdminCuevasScreenState extends State<AdminCuevasScreen> {
  final CuevaService _cuevaService = CuevaService();
  late Future<List<dynamic>> _futureCuevas;

  @override
  void initState() {
    super.initState();
    _cargarCuevas();
  }

  void _cargarCuevas() {
    setState(() {
      _futureCuevas = _cuevaService.getCuevas();
    });
  }

  void _eliminar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar esta cueva? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _cuevaService.eliminarCueva(id);
        _cargarCuevas();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cueva eliminada correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Cuevas'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureCuevas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay cuevas registradas.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final cuevas = snapshot.data!;

          return Column(
            children: [
              // Cabecera con indicador de total de cuevas activas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.brown.shade50,
                child: Text(
                  'Total de Cuevas Registradas: ${cuevas.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade800,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cuevas.length,
                  itemBuilder: (context, index) {
                    final cueva = cuevas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.terrain, color: Colors.orange.shade800),
                        ),
                        title: Text(
                          cueva['nombre_cueva'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Tipo: ${cueva['tipo_cueva']}\nUbicación: ${cueva['direccion_ubicacion']}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminar(cueva['id_cueva']),
                        ),
                        onTap: () async {
                          // Al hacer clic, navega al formulario de edición
                          final actualizado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CuevaFormScreen(cueva: cueva),
                            ),
                          );
                          if (actualizado == true) {
                            _cargarCuevas();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Botón para mandar a la pantalla de creación de nuevas cuevas
          final creado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CuevaFormScreen()),
          );
          if (creado == true) {
            _cargarCuevas();
          }
        },
        label: const Text('Nueva Cueva'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}