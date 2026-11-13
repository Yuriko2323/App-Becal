import 'package:flutter/material.dart';
import '../../models/pedido.dart';
import '../../services/pedido_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_widget.dart';

class PedidoDetalleScreen extends StatelessWidget {
  final int idPedido;
  final int idPerfil;
  final bool modoArtesano;
  const PedidoDetalleScreen({super.key, required this.idPedido, required this.idPerfil, this.modoArtesano = false});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Pedido #$idPedido')),
    body: FutureBuilder<PedidoDetalle>(future: modoArtesano ? PedidoService().obtenerDetallePedidoArtesano(idPerfil, idPedido) : PedidoService().obtenerDetallePedido(idPerfil, idPedido), builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingWidget();
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('No se pudo cargar el pedido.\n${snapshot.error}', textAlign: TextAlign.center)));
      final p = snapshot.data!;
      return ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('Pedido #${p.idPedido}', style: Theme.of(context).textTheme.titleLarge)), Chip(label: Text(p.estado ?? 'Pendiente'))]),
          _dato('Fecha de solicitud', formatoFecha(p.fechaSolicitud)), _dato('Entrega estimada', formatoFecha(p.fechaEntregaEstimada)),
          _dato('Total', formatoMoneda(p.total)), _dato('Anticipo', formatoMoneda(p.anticipo)),
          if (p.observaciones?.isNotEmpty == true) _dato('Observaciones', p.observaciones!),
        ]))),
        if (modoArtesano) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Información del cliente', style: Theme.of(context).textTheme.titleMedium), _dato('Nombre', p.cliente ?? 'No disponible'), _dato('Correo', p.clienteCorreo ?? 'No disponible'), _dato('Teléfono', p.clienteTelefono ?? 'No disponible'),
        ]))) else Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Artesano y puesto', style: Theme.of(context).textTheme.titleMedium), _dato('Artesano', p.artesano ?? 'No disponible'), _dato('Teléfono', p.artesanoTelefono ?? 'No disponible'), _dato('Puesto', '${p.puesto ?? 'No disponible'} ${p.puestoNumero ?? ''}')]))),
        const SizedBox(height: 8), Text('Productos solicitados', style: Theme.of(context).textTheme.titleLarge),
        if (p.items.isEmpty) const Card(child: ListTile(title: Text('La API no devolvió partidas para este pedido.'))),
        ...p.items.map((i) => Card(child: ListTile(leading: const Icon(Icons.inventory_2_outlined), title: Text(i.producto ?? 'Producto'), subtitle: Text('${i.cantidad} × ${formatoMoneda(i.precioUnitario)}'), trailing: Text(formatoMoneda(i.subtotal), style: const TextStyle(fontWeight: FontWeight.bold))))),
      ]);
    }));
  static Widget _dato(String titulo, String valor) => Padding(padding: const EdgeInsets.only(top: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 140, child: Text(titulo, style: const TextStyle(color: Colors.grey))), Expanded(child: Text(valor))]));
}
