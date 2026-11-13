import 'package:flutter/material.dart';
import 'admin_cuevas_screen.dart';
import 'admin_puestos_screen.dart';
import 'admin_artesanos_screen.dart';
import 'admin_ventas_screen.dart';
import 'admin_vendedores_screen.dart';
import 'admin_catalogos_screen.dart';
import 'admin_pedidos_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              // Lógica para limpiar sesión y regresar al Login
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard(
              context,
              title: 'Gestionar Cuevas',
              icon: Icons.terrain,
              color: Colors.orange.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminCuevasScreen()),
                );
              },
            ),
            _buildAdminCard(
              context,
              title: 'Gestionar Puestos',
              icon: Icons.store,
              color: Colors.blue.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPuestosScreen()),
                );
              },
            ),
            _buildAdminCard(
              context,
              title: 'Cuentas Artesanos',
              icon: Icons.engineering,
              color: Colors.green.shade700,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminArtesanosScreen()));
              },
            ),
            _buildAdminCard(
              context,
              title: 'Cuentas Vendedores',
              icon: Icons.badge,
              color: Colors.purple.shade700,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVendedoresScreen()));
              },
            ),
            _buildAdminCard(
              context,
              title: 'Catálogos del Sistema',
              icon: Icons.category,
              color: Colors.teal.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminCatalogosScreen()),
                );
              },
            ),
            _buildAdminCard(
              context,
              title: 'Pedidos de Clientes',
              icon: Icons.shopping_bag_outlined,
              color: Colors.deepOrange.shade700,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPedidosScreen()));
              },
            ),
            _buildAdminCard(
              context,
              title: 'Ventas y Reportes',
              icon: Icons.bar_chart,
              color: Colors.red.shade700,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVentasScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}