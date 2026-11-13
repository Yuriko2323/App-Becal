import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../services/cliente_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Cliente cliente;

  const EditarPerfilScreen({Key? key, required this.cliente}) : super(key: key);

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final ClienteService _clienteService = ClienteService();

  late TextEditingController _nombreController;
  late TextEditingController _apellidoPController;
  late TextEditingController _apellidoMController;
  late TextEditingController _telefonoController;
  late TextEditingController _nacionalidadController;
  late TextEditingController _idiomaController;

  String? _fotoBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente.nombre ?? '');
    _apellidoPController = TextEditingController(text: widget.cliente.apellidoPaterno ?? '');
    _apellidoMController = TextEditingController(text: widget.cliente.apellidoMaterno ?? '');
    _telefonoController = TextEditingController(text: widget.cliente.telefono ?? '');
    _nacionalidadController = TextEditingController(text: widget.cliente.nacionalidad ?? 'Mexicana');
    _idiomaController = TextEditingController(text: widget.cliente.idiomaPreferido ?? 'Español');
    _fotoBase64 = widget.cliente.fotoPerfil;
  }

  Future<void> _seleccionarFoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final Uint8List? fileBytes = result.files.first.bytes;

        if (fileBytes != null) {
          final String base64String = base64Encode(fileBytes);

          setState(() {
            _fotoBase64 = 'data:image/png;base64,$base64String';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar la imagen: $e')),
        );
      }
    }
  }

  void _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final exito = await _clienteService.actualizarPerfil(
        idCliente: widget.cliente.idCliente,
        nombre: _nombreController.text,
        apellidoPaterno: _apellidoPController.text,
        apellidoMaterno: _apellidoMController.text,
        telefono: _telefonoController.text,
        nacionalidad: _nacionalidadController.text,
        idiomaPreferido: _idiomaController.text,
        fotoPerfilBase64: _fotoBase64,
      );

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_fotoBase64 != null && _fotoBase64!.trim().isNotEmpty) {
      final foto = _fotoBase64!.trim();
      if (foto.startsWith('http')) {
        imageProvider = NetworkImage(foto);
      } else {
        try {
          String cleanBase64 = foto.contains(',') ? foto.split(',').last : foto;
          cleanBase64 = cleanBase64.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
          while (cleanBase64.length % 4 != 0) {
            cleanBase64 += '=';
          }
          imageProvider = MemoryImage(base64Decode(cleanBase64));
        } catch (_) {
          imageProvider = null;
        }
      }
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepOrange.shade100,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 60, color: Colors.deepOrange)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                onPressed: _seleccionarFoto,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(height: 24),
              const Text(
                'Información Personal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre(s)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _apellidoPController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido Paterno',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _apellidoMController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido Materno',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de contacto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Preferencias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nacionalidadController,
                decoration: const InputDecoration(
                  labelText: 'Nacionalidad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idiomaController,
                decoration: const InputDecoration(
                  labelText: 'Idioma preferido',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.cliente.tipoCliente ?? 'Sin especificar',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cliente (Inmutable)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  filled: true,
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _guardarCambios,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}