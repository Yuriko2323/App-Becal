import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../models/pedido.dart';
import '../../services/pedido_service.dart';

import '../../widgets/loading_widget.dart';
import '../../widgets/pedido_card.dart';
import '../pedidos/pedido_detalle_screen.dart';
import '../productos/artesano_productos_screen.dart';
import 'artesano_perfil_screen.dart';

class ArtesanoDashboardScreen extends StatefulWidget {
  final int idArtesano; final String nombre;
  const ArtesanoDashboardScreen({super.key, required this.idArtesano, required this.nombre});
  @override State<ArtesanoDashboardScreen> createState() => _ArtesanoDashboardScreenState();
}
class _ArtesanoDashboardScreenState extends State<ArtesanoDashboardScreen> {
  int _tab = 0;
  Future<Map<String,dynamic>> _dashboard() async { final r = await ApiClient.get('/artesanos/${widget.idArtesano}/dashboard'); if (r is! Map<String,dynamic>) throw Exception('Respuesta de dashboard inválida'); return r; }
  Future<List<Pedido>> _pedidos() => PedidoService().obtenerPedidosArtesano(widget.idArtesano);
  @override Widget build(BuildContext context) {
    final pages = <Widget>[
      _inicio(),
      ArtesanoProductosScreen(idArtesano: widget.idArtesano),
      _listaPedidos(),
      ArtesanoPerfilScreen(idArtesano: widget.idArtesano),
    ];
    return Scaffold(appBar: AppBar(title: Text('Artesano · ${widget.nombre}'), actions: [IconButton(tooltip: 'Cerrar sesión', onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false), icon: const Icon(Icons.logout))]),
      body: SafeArea(child: pages[_tab]), bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (v) => setState(() => _tab=v), destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Resumen'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Productos'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Pedidos'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Mi perfil'),
      ]));
  }
  Widget _inicio() => RefreshIndicator(onRefresh: () async { setState(() {}); await _dashboard(); }, child: ListView(padding: const EdgeInsets.all(16), children: [Text('Tu taller', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 12), FutureBuilder<Map<String,dynamic>>(future: _dashboard(), builder: (context,s) { if(s.connectionState==ConnectionState.waiting) return const LoadingWidget(); if(s.hasError) return _error(s.error.toString()); final d=s.data!; return GridView.count(shrinkWrap:true, physics: const NeverScrollableScrollPhysics(), crossAxisCount:2, crossAxisSpacing:12, mainAxisSpacing:12, childAspectRatio:1.35, children:[_stat('Productos activos', '${d['total_productos_activos'] ?? 0}', Icons.inventory_2),_stat('Pedidos recibidos','${d['total_pedidos_recibidos'] ?? 0}',Icons.receipt_long),_stat('Ingresos estimados','\$${((d['ingresos_estimados'] as num?) ?? 0).toStringAsFixed(2)}',Icons.payments)]); }), const SizedBox(height:20), FilledButton.icon(onPressed:()=>setState(()=>_tab=1), icon: const Icon(Icons.add), label: const Text('Administrar mis productos')), const SizedBox(height:8), OutlinedButton.icon(onPressed:()=>setState(()=>_tab=2), icon: const Icon(Icons.list_alt), label: const Text('Ver pedidos recibidos'))]));
  Widget _stat(String title,String value,IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(icon,color:Colors.deepOrange,size:28),const SizedBox(height:8),Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold),textAlign:TextAlign.center),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:12))])));
  Widget _listaPedidos() => FutureBuilder<List<Pedido>>(
    future: _pedidos(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingWidget();
      if (snapshot.hasError) return _error('${snapshot.error}');
      final items = snapshot.data ?? <Pedido>[];
      if (items.isEmpty) return const Center(child: Text('Todavía no hay pedidos recibidos.'));
      return RefreshIndicator(
        onRefresh: () async { setState(() {}); await _pedidos(); },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: items.map((pedido) => PedidoCard(
            pedido: pedido,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PedidoDetalleScreen(
                idPedido: pedido.idPedido,
                idPerfil: widget.idArtesano,
                modoArtesano: true,
              ),
            )),
          )).toList(),
        ),
      );
    },
  );
  Widget _error(String message)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('No se pudo cargar esta sección.\n$message',textAlign:TextAlign.center)));
}
