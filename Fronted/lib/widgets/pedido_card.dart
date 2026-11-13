import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../utils/formatters.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;
  const PedidoCard({super.key, required this.pedido, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    onTap: onTap, leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
    title: Text('Pedido #${pedido.idPedido}', style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text('${pedido.artesano ?? 'Pedido artesanal'} · ${formatoFecha(pedido.fechaSolicitud)}\n${pedido.items.isEmpty ? 'Detalle disponible al abrir' : pedido.items.map((e) => '${e.cantidad} × ${e.producto ?? 'Producto'}').join(', ')}'),
    isThreeLine: true, trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(formatoMoneda(pedido.total), style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(pedido.estado ?? 'Pendiente', style: TextStyle(color: Colors.deepOrange.shade700, fontSize: 12)),
    ]),
  ));
}
