import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../services/cliente_service.dart';
import 'editar_perfil_screen.dart';

class PerfilScreen extends StatefulWidget {
  final int idCliente;

  const PerfilScreen({Key? key, required this.idCliente}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ClienteService _clienteService = ClienteService();
  late Future<Cliente> _clienteFuture;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _clienteFuture = _clienteService.obtenerCliente(widget.idCliente);
    });
  }

  Widget _buildAvatar(Cliente cliente) {
    ImageProvider? imageProvider;

    if (cliente.fotoPerfil != null && cliente.fotoPerfil!.trim().isNotEmpty) {
      final foto = cliente.fotoPerfil!.trim();

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
        } catch (e) {
          debugPrint('Error decodificando foto de perfil: $e');
          imageProvider = null;
        }
      }
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.deepOrange.shade100,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.person, size: 55, color: Colors.deepOrange)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cliente>(
      future: _clienteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error al cargar el perfil: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final cliente = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildAvatar(cliente),
              const SizedBox(height: 16),
              Text(
                cliente.nombreCompleto,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(
                  'Tipo: ${cliente.tipoCliente ?? 'Sin especificar'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Colors.deepOrange.shade50,
                side: BorderSide(color: Colors.deepOrange.shade200),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mi información',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Teléfono'),
                subtitle: Text(
                  cliente.telefono != null && cliente.telefono!.isNotEmpty
                      ? cliente.telefono!
                      : 'No especificado',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Nacionalidad'),
                subtitle: Text(
                  cliente.nacionalidad != null && cliente.nacionalidad!.isNotEmpty
                      ? cliente.nacionalidad!
                      : 'No especificada',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Idioma preferido'),
                subtitle: Text(
                  cliente.idiomaPreferido != null && cliente.idiomaPreferido!.isNotEmpty
                      ? cliente.idiomaPreferido!
                      : 'No especificado',
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(Icons.edit, color: Colors.deepOrange),
                title: const Text(
                  'Editar perfil',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                onTap: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditarPerfilScreen(cliente: cliente),
                    ),
                  );

                  if (resultado == true) {
                    _cargarDatos();
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}