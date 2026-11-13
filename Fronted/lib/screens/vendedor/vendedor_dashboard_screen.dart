
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../widgets/loading_widget.dart';

class VendedorDashboardScreen extends StatefulWidget {
  final int idVendedor;
  final String nombre;

  const VendedorDashboardScreen({
    super.key,
    required this.idVendedor,
    required this.nombre,
  });

  @override
  State<VendedorDashboardScreen> createState() =>
      _VendedorDashboardScreenState();
}

class _VendedorDashboardScreenState
    extends State<VendedorDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _futureVentas;

  @override
  void initState() {
    super.initState();
    _futureVentas = _obtenerVentas();
  }

  Future<List<Map<String, dynamic>>> _obtenerVentas() async {
    final respuesta = await ApiClient.get(
      '/ventas?skip=0&limit=100',
    );

    if (respuesta is! List) {
      throw Exception(
        'La API no devolvió una lista válida de ventas.',
      );
    }

    final ventasFiltradas = <Map<String, dynamic>>[];

    for (final elemento in respuesta) {
      if (elemento is! Map) continue;

      final venta = Map<String, dynamic>.from(elemento);
      final idVendedorVenta = venta['id_vendedor'];

      if (idVendedorVenta?.toString() ==
          widget.idVendedor.toString()) {
        ventasFiltradas.add(venta);
      }
    }

    return ventasFiltradas;
  }

  Future<void> _recargarVentas() async {
    final nuevaConsulta = _obtenerVentas();

    setState(() {
      _futureVentas = nuevaConsulta;
    });

    try {
      await nuevaConsulta;
    } catch (_) {
      // FutureBuilder mostrará el error de la consulta.
    }
  }

  void _cerrarSesion() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendedor · ${widget.nombre}'),
        actions: [
          IconButton(
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureVentas,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudo consultar el historial de ventas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _recargarVentas,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final ventas = snapshot.data ??
              <Map<String, dynamic>>[];

          return RefreshIndicator(
            onRefresh: _recargarVentas,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Panel de vendedor',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ventas registradas: ${ventas.length}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 12),

                if (ventas.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay ventas asociadas a esta cuenta. '
                        'Si esperabas ver ventas, verifica que la '
                        'respuesta de la API incluya id_vendedor.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                ...ventas.map((venta) {
                  final idVenta =
                      venta['id_venta']?.toString() ?? '—';
                  final idPuesto =
                      venta['id_puesto']?.toString() ?? '—';
                  final idCliente =
                      venta['id_cliente']?.toString() ?? '—';
                  final metodoPago =
                      venta['metodo_pago']?.toString() ??
                          'Sin método';

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.point_of_sale,
                      ),
                      title: Text('Venta #$idVenta'),
                      subtitle: Text(
                        'Puesto: $idPuesto · Cliente: $idCliente',
                      ),
                      trailing: SizedBox(
                        width: 100,
                        child: Text(
                          metodoPago,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
