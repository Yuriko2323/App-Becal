import 'package:flutter/material.dart';
import 'puesto_form_screen.dart';

class PuestoDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> puesto;

  const PuestoDetalleScreen({Key? key, required this.puesto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(puesto['nombre_puesto'] ?? 'Detalles del Puesto'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.store, size: 40, color: Colors.blue.shade800),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow('Nombre:', puesto['nombre_puesto'] ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow('Número de Puesto:', puesto['numero_puesto'] ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow('Sector / Ubicación:', puesto['ubicacion_sector'] ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow('Categoría:', puesto['categoria'] ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow('Estado:', puesto['estado'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                // Al presionar, navega al formulario en modo edición
                final actualizado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PuestoFormScreen(puesto: puesto),
                  ),
                );
                if (actualizado == true) {
                  if (!context.mounted) return;
                  Navigator.pop(context, true); // Regresa al listado refrescando
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Actualizar Datos del Puesto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}