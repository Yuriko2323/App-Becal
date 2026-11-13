import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();
  final AuthService _authService = AuthService();

  String _tipoUsuario = 'Cliente'; // 'Cliente', 'Artesano', 'Vendedor'
  String _subtipoCliente = 'Local'; // 'Local', 'Mayorista', 'Turista'
  bool _isLoading = false;

  void _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_contrasenaController.text != _confirmarContrasenaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (_tipoUsuario != 'Cliente') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Las cuentas de $_tipoUsuario se gestionan a través de la administración del Parador.',
          ),
          backgroundColor: Colors.brown.shade600,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exito = await _authService.registrarCliente(
        correo: _correoController.text.trim(),
        contrasena: _contrasenaController.text,
        tipoCliente: _subtipoCliente,
      );

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Cuenta creada con éxito! Por favor inicia sesión.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context);
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

  // Estilo minimalista consistente con el Login
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.brown.shade800),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crear Cuenta',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Únete al Parador Artesanal de Bécal.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Correo electrónico', Icons.email_outlined),
                      validator: Validators.validarCorreo,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _contrasenaController,
                      obscureText: true,
                      decoration: _inputDecoration('Contraseña', Icons.lock_outline),
                      validator: Validators.validarContrasena,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _confirmarContrasenaController,
                      obscureText: true,
                      decoration: _inputDecoration('Confirmar Contraseña', Icons.lock_clock_outlined),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Confirma tu contraseña';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: _tipoUsuario,
                      decoration: _inputDecoration('Tipo de Cuenta', Icons.badge_outlined),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.brown.shade400),
                      items: const [
                        DropdownMenuItem(value: 'Cliente', child: Text('Cliente / Comprador')),

                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _tipoUsuario = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    if (_tipoUsuario == 'Cliente') ...[
                      DropdownButtonFormField<String>(
                        value: _subtipoCliente,
                        decoration: _inputDecoration('Modalidad de Cliente', Icons.shopping_bag_outlined),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.brown.shade400),
                        items: const [
                          DropdownMenuItem(value: 'Local', child: Text('Local')),
                          DropdownMenuItem(value: 'Turista', child: Text('Turista')),
                        
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _subtipoCliente = val);
                        },
                      ),
                      const SizedBox(height: 32),
                    ],

                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.brown))
                        : ElevatedButton(
                            onPressed: _registrar,
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
                              'REGISTRARSE',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}