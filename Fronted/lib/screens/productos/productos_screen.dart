import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../services/producto_service.dart';
import '../../services/pedido_service.dart';
import '../../widgets/producto_card.dart';
import 'producto_detalle_screen.dart';

class ProductosScreen extends StatefulWidget {
  final int idCliente;
  final VoidCallback? onPedidoCreado;

  const ProductosScreen({
    Key? key,
    required this.idCliente,
    this.onPedidoCreado,
  }) : super(key: key);

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductoService _productoService = ProductoService();
  final PedidoService _pedidoService = PedidoService();
  late Future<List<Producto>> _productosFuture;

  @override
  void initState() {
    super.initState();
    _productosFuture = _productoService.obtenerProductos();
  }

  void _mostrarModalDetalle(Producto producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductoDetalleScreen(
          producto: producto,
          idCliente: widget.idCliente,
          onComprar: (cantidad) => _procesarCompra(producto, cantidad),
        ),
      ),
    );
  }

  Future<bool> _procesarCompra(Producto producto, int cantidad) async {
    var dialogAbierto = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator(color: Colors.brown.shade400)),
    );

    try {
      final estadoInicial = await _pedidoService.obtenerIdEstadoInicial();
      final respuesta = await _pedidoService.crearPedido(
        idCliente: widget.idCliente,
        idProducto: producto.idProducto,
        cantidad: cantidad,
        idEstadoPedido: estadoInicial,
        metodoPago: 'Efectivo',
      );

      final rawId = respuesta['id_pedido'];
      final idPedido = rawId is num ? rawId.toInt() : int.tryParse('$rawId');
      if (idPedido == null || idPedido <= 0) {
        throw Exception('La API no confirmó el identificador del pedido. No se puede verificar el registro.');
      }

      if (mounted && dialogAbierto) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogAbierto = false;
      }
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido #$idPedido registrado para "${producto.nombre ?? 'Producto'}" (cantidad: $cantidad).'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      widget.onPedidoCreado?.call();
      return true;
    } catch (e) {
      if (mounted && dialogAbierto) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogAbierto = false;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Producto>>(
      future: _productosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.brown.shade400));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade800),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No hay productos disponibles por el momento.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          );
        }

        final productos = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 16.0), // Padding inferior para que no quede pegado
          // EL CAMBIO MÁGICO: Grid dinámico que se adapta al ancho
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280, // Ancho máximo de la tarjeta (creará más columnas si hay espacio)
            childAspectRatio: 0.72,  // Proporción de la tarjeta (ajusta si se ve muy alta o baja)
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            return ProductoCard(
              producto: productos[index],
              onComprar: () => _mostrarModalDetalle(productos[index]),
            );
          },
        );
      },
    );
  }
}