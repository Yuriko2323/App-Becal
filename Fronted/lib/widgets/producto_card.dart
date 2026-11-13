import 'package:flutter/material.dart';
import '../models/producto.dart';
import 'producto_imagen.dart';


class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onComprar;

  const ProductoCard({
    Key? key,
    required this.producto,
    this.onComprar,
  }) : super(key: key);

  Widget _buildImagenProducto(String? imagenRaw) => ProductoImagen(origen: imagenRaw, fit: BoxFit.cover, width: double.infinity, height: double.infinity);

  Widget _buildPlaceholder(String motivo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo, size: 40, color: Colors.grey),
          const SizedBox(height: 4),
          const Text('FOTO', style: TextStyle(color: Colors.grey, fontSize: 12)),
          // Descomenta la siguiente línea solo si quieres ver el motivo en la pantalla:
          Text(motivo, style: const TextStyle(color: Colors.red, fontSize: 9)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade200,
                child: _buildImagenProducto(producto.imagenUrl),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre ?? 'Sin Nombre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${(producto.precioBase ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onComprar ?? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Comprar: ${producto.nombre}')),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart, size: 16),
                    label: const Text('Comprar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}