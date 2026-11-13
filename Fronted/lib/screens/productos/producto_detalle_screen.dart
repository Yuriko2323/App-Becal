import 'package:flutter/material.dart';
import '../../models/foto_producto.dart';
import '../../models/producto.dart';
import '../../services/producto_service.dart';
import '../../widgets/producto_imagen.dart';
import '../../utils/formatters.dart';

class ProductoDetalleScreen extends StatefulWidget {
  final Producto producto;
  final int? idCliente;
  final Future<bool> Function(int cantidad)? onComprar;
  const ProductoDetalleScreen({super.key, required this.producto, this.idCliente, this.onComprar});
  @override State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}
class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  final _service = ProductoService();
  late Future<List<FotoProducto>> _fotos;
  int _cantidad = 1;
  bool _comprando = false;
  @override void initState() { super.initState(); _fotos = _service.obtenerFotos(widget.producto.idProducto); }
  @override Widget build(BuildContext context) {
    final p = widget.producto;
    return Scaffold(appBar: AppBar(title: const Text('Detalle del producto')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SizedBox(height: 320, child: FutureBuilder<List<FotoProducto>>(future: _fotos, builder: (context, snapshot) {
          final fotos = snapshot.data ?? [];
          if (fotos.isEmpty) return ProductoImagen(origen: p.imagenUrl, fit: BoxFit.contain, permitirZoom: true);
          return PageView(children: fotos.map((f) => Padding(padding: const EdgeInsets.all(6), child: ProductoImagen(origen: f.urlImagen, fit: BoxFit.contain, permitirZoom: true))).toList());
        })),
        const SizedBox(height: 18), Text(p.nombre ?? 'Producto artesanal', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), Text(formatoMoneda(p.precioBase), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16), Text(p.descripcion?.trim().isNotEmpty == true ? p.descripcion! : 'Sin descripción disponible.'),
        const SizedBox(height: 18), const Text('Características', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: [
          if (p.material?.isNotEmpty == true) Chip(label: Text('Material: ${p.material}')),
          if (p.color?.isNotEmpty == true) Chip(label: Text('Color: ${p.color}')),
          if (p.talla?.isNotEmpty == true) Chip(label: Text('Talla: ${p.talla}')),
          if (p.tipoTejido?.isNotEmpty == true) Chip(label: Text('Tejido: ${p.tipoTejido}')),
        ]),
        if (widget.onComprar != null) ...[
          const SizedBox(height: 22), Row(children: [const Text('Cantidad'), const Spacer(), IconButton(onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null, icon: const Icon(Icons.remove_circle_outline)), Text('$_cantidad', style: const TextStyle(fontSize: 18)), IconButton(onPressed: () => setState(() => _cantidad++), icon: const Icon(Icons.add_circle_outline))]),
          FilledButton.icon(
            onPressed: _comprando ? null : () async {
              setState(() => _comprando = true);
              try {
                final creado = await widget.onComprar!(_cantidad);
                if (creado && context.mounted) Navigator.pop(context);
              } finally {
                if (mounted) setState(() => _comprando = false);
              }
            },
            icon: _comprando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.shopping_bag_outlined),
            label: Text(_comprando ? 'Registrando pedido...' : 'Crear pedido'),
          ),
        ],
      ]));
  }
}
