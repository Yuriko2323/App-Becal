import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../artesano/artesano_dashboard_screen.dart';
import '../vendedor/vendedor_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _iniciarSesion() async {
    if (_correoController.text.trim().isEmpty || _contrasenaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuario = await _authService.login(
        _correoController.text.trim(),
        _contrasenaController.text,
      );

      if (!mounted) return;
      switch (usuario.tipoUsuario) {
        case 'Admin':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
          break;
        case 'Cliente':
          final idCliente = usuario.idCliente;
          if (idCliente == null) {
            throw Exception('La API autenticó la cuenta, pero no devolvió id_cliente. Revisa el perfil en la base de datos.');
          }
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(idCliente: idCliente)));
          break;
        case 'Artesano':
          final id = usuario.idArtesano;
          if (id == null) throw Exception('La API no devolvió id_artesano para esta cuenta.');
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ArtesanoDashboardScreen(idArtesano: id, nombre: usuario.nombre)));
          break;
        case 'Vendedor':
          final id = usuario.idVendedor;
          if (id == null) throw Exception('La API no devolvió id_vendedor para esta cuenta.');
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VendedorDashboardScreen(idVendedor: id, nombre: usuario.nombre)));
          break;
        default:
          throw Exception('Tipo de usuario no reconocido: ${usuario.tipoUsuario}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Estilo minimalista para los inputs
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.brown.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.brown.shade400, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo de la aplicación
                  Center(
                    child: Image.asset(
                      'assets/images/logo_parador.jpg',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Bienvenido de vuelta!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Correo electrónico', Icons.email_outlined),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _contrasenaController,
                    obscureText: true,
                    decoration: _inputDecoration('Contraseña', Icons.lock_outline),
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.brown))
                      : ElevatedButton(
                          onPressed: _iniciarSesion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown.shade800,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/registro'),
                        style: TextButton.styleFrom(foregroundColor: Colors.brown.shade700),
                        child: const Text('Regístrate aquí', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}