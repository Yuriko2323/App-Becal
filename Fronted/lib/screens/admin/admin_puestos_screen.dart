import 'package:flutter/material.dart';
import '../../services/puesto_service.dart';
import 'puesto_form_screen.dart';
import 'puesto_detalle_screen.dart';

class AdminPuestosScreen extends StatefulWidget {
  const AdminPuestosScreen({Key? key}) : super(key: key);

  @override
  State<AdminPuestosScreen> createState() => _AdminPuestosScreenState();
}

class _AdminPuestosScreenState extends State<AdminPuestosScreen> {
  final PuestoService _puestoService = PuestoService();
  late Future<List<dynamic>> _futurePuestos;

  @override
  void initState() {
    super.initState();
    _cargarPuestos();
  }

  void _cargarPuestos() {
    setState(() {
      _futurePuestos = _puestoService.getPuestos();
    });
  }

  void _eliminar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este puesto?'),
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
        await _puestoService.eliminarPuesto(id);
        _cargarPuestos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Puesto eliminado correctamente')),
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
        title: const Text('Gestión de Puestos / Locales'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futurePuestos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay puestos registrados.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final puestos = snapshot.data!;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.brown.shade50,
                child: Text(
                  'Total de Puestos Registrados: ${puestos.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade800,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: puestos.length,
                  itemBuilder: (context, index) {
                    final puesto = puestos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.store, color: Colors.blue.shade800),
                        ),
                        title: Text(
                          puesto['nombre_puesto'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Número: ${puesto['numero_puesto']} | Sector: ${puesto['ubicacion_sector']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminar(puesto['id_puesto']),
                        ),
                        onTap: () async {
                          // Al dar clic, muestra primero la pantalla de detalles
                          final recargar = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PuestoDetalleScreen(puesto: puesto),
                            ),
                          );
                          if (recargar == true) {
                            _cargarPuestos();
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
          final creado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PuestoFormScreen()),
          );
          if (creado == true) {
            _cargarPuestos();
          }
        },
        label: const Text('Nuevo Puesto'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}