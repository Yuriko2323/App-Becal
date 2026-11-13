import 'package:flutter/material.dart';
import '../../services/cliente_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../productos/productos_screen.dart';
import '../perfil/perfil_screen.dart';
import '../pedidos/pedidos_screen.dart'; // <--- Importación requerida

class HomeScreen extends StatefulWidget {
  final int idCliente;

  const HomeScreen({
    Key? key,
    required this.idCliente,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late Future<String> _nombreUsuarioFuture;
  final ClienteService _clienteService = ClienteService();

  @override
  void initState() {
    super.initState();
    _nombreUsuarioFuture = _clienteService.obtenerNombreCliente(widget.idCliente);
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> paginas = [
      _buildVistaInicio(),
      ProductosScreen(
        idCliente: widget.idCliente, 
        onPedidoCreado: () {
          setState(() => _currentIndex = 2); // Cambia a la pestaña Pedidos
        },
      ),
      PedidosScreen(idCliente: widget.idCliente), 
      PerfilScreen(idCliente: widget.idCliente),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Fondo suave y minimalista
      body: SafeArea(
        child: Center( // Centramos el contenido en pantallas grandes
          child: ConstrainedBox(
            // Limita el ancho en Web/PC, en celular tomará todo el espacio
            constraints: const BoxConstraints(maxWidth: 1200),
            child: paginas[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildVistaInicio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<String>(
            future: _nombreUsuarioFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.brown),
                );
              } else if (snapshot.hasError) {
                return Text(
                  'Hola',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                );
              }
              return Text(
                'Hola, ${snapshot.data}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            '¿Qué deseas encontrar hoy?',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          // Buscador con estilo minimalista
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, color: Colors.brown.shade400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.brown.shade400, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Catálogo disponible',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade800),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ProductosScreen(idCliente: widget.idCliente),
          ),
        ],
      ),
    );
  }
}