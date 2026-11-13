import 'package:flutter/material.dart';
import '../../models/pedido.dart';
import '../../services/pedido_service.dart';

class PedidosScreen extends StatefulWidget {
  final int idCliente;

  const PedidosScreen({Key? key, required this.idCliente}) : super(key: key);

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final PedidoService _pedidoService = PedidoService();
  late Future<List<Pedido>> _pedidosFuture;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  void _cargarPedidos() {
    setState(() {
      _pedidosFuture = _pedidoService.obtenerPedidosCliente(widget.idCliente);
    });
  }

  void _confirmarCancelacion(int idPedido) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: Text('¿Estás seguro de que deseas cancelar el pedido #$idPedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);
              _procesarCancelacion(idPedido);
            },
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _procesarCancelacion(int idPedido) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final exito = await _pedidoService.cancelarPedido(idCliente: widget.idCliente, idPedido: idPedido);
      if (mounted) Navigator.pop(context);

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El pedido #$idPedido ha sido cancelado.'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        _cargarPedidos();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarModalDetalle(int idPedido) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return FutureBuilder<PedidoDetalle>(
          future: _pedidoService.obtenerDetallePedido(widget.idCliente, idPedido),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar el detalle: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final detalle = snapshot.data!;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detalle del Pedido #${detalle.idPedido}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Chip(
                          label: Text(
                            detalle.estado ?? 'Pendiente',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: Colors.deepOrange,
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    const Text('Información del Taller / Puesto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('Artesano: ${detalle.artesano ?? "Sin especificar"}'),
                    if (detalle.artesanoTelefono != null) Text('Teléfono Artesano: ${detalle.artesanoTelefono}'),
                    if (detalle.puesto != null) Text('Puesto: ${detalle.puesto} (#${detalle.puestoNumero ?? ""})'),

                    const SizedBox(height: 16),
                    const Text('Fechas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('Solicitado: ${detalle.fechaSolicitud ?? "N/A"}'),
                    Text('Entrega estimada: ${detalle.fechaEntregaEstimada ?? "N/A"}'),

                    const SizedBox(height: 16),
                    const Text('Productos solicitados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...detalle.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.cantidad}x ${item.producto}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),

                    if (detalle.observaciones != null && detalle.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Observaciones: ${detalle.observaciones}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ],

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                '\$${detalle.total.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                        if ((detalle.estado ?? '').toLowerCase().contains('pendiente'))
                          OutlinedButton.icon(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.pop(modalContext);
                              _confirmarCancelacion(detalle.idPedido);
                            },
                          )
                        else
                          const Flexible(child: Text('Solo se cancelan pedidos pendientes.', textAlign: TextAlign.end, style: TextStyle(color: Colors.grey, fontSize: 12))),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPedidos,
          )
        ],
      ),
      body: FutureBuilder<List<Pedido>>(
        future: _pedidosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al obtener pedidos: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aún no has realizado ningún pedido.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final pedidos = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _cargarPedidos(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                final primerItem = pedido.items.isNotEmpty ? pedido.items.first : null;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _mostrarModalDetalle(pedido.idPedido),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pedido #${pedido.idPedido}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Chip(
                                label: Text(
                                  pedido.estado ?? 'Pendiente',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor: Colors.deepOrange,
                              ),
                            ],
                          ),
                          const Divider(),
                          if (primerItem != null)
                            Text(
                              'Producto: ${primerItem.producto}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          const SizedBox(height: 4),
                          Text('Artesano: ${pedido.artesano}'),
                          if (pedido.fechaSolicitud != null)
                            Text('Fecha: ${pedido.fechaSolicitud}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                '\$${pedido.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Toca para consultar el detalle del pedido',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}