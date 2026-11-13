
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import 'admin_vendedor_form_screen.dart';
import 'admin_vendedor_detalle_screen.dart';

class AdminVendedoresScreen extends StatefulWidget {
  const AdminVendedoresScreen({super.key});

  @override
  State<AdminVendedoresScreen> createState() =>
      _AdminVendedoresScreenState();
}

class _AdminVendedoresScreenState
    extends State<AdminVendedoresScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _vendedores = [];

  int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final respuesta = await ApiClient.get(
        '/admin/vendedores?skip=0&limit=200',
      );

      if (respuesta is! List) {
        throw Exception(
          'La API no devolvió una lista válida de vendedores.',
        );
      }

      final lista = respuesta
          .whereType<Map>()
          .map(
            (elemento) =>
                Map<String, dynamic>.from(elemento),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _vendedores = lista;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setActive(
    Map<String, dynamic> vendedor,
  ) async {
    final id = _int(vendedor['id_vendedor']);

    if (id == null) {
      _message(
        'La API no devolvió el ID del vendedor.',
        error: true,
      );
      return;
    }

    // "activo" representa el estado efectivo de la cuenta
    // devuelto por la ruta administrativa de FastAPI.
    final estaActivo = vendedor['activo'] == true;
    final siguienteEstado = !estaActivo;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            siguienteEstado
                ? 'Activar cuenta'
                : 'Desactivar cuenta',
          ),
          content: Text(
            siguienteEstado
                ? '¿Deseas activar la cuenta del vendedor #$id?'
                : '¿Deseas desactivar la cuenta del vendedor '
                    '#$id? El usuario no debería poder iniciar '
                    'sesión mientras su cuenta esté inactiva.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(
                siguienteEstado ? 'Activar' : 'Desactivar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !mounted) return;

    try {
      await ApiClient.patch(
        '/admin/vendedores/$id/estado',
        body: {'activo': siguienteEstado},
      );

      _message(
        siguienteEstado
            ? 'Cuenta activada correctamente.'
            : 'Cuenta desactivada correctamente.',
      );

      await _load();
    } catch (error) {
      _message(
        'No se pudo cambiar el estado: $error. '
        'Verifica que la ruta de FastAPI esté habilitada.',
        error: true,
      );
    }
  }

  Future<void> _openDetail(
    Map<String, dynamic> vendedor,
  ) async {
    final id = _int(vendedor['id_vendedor']);

    if (id == null) {
      _message(
        'La API no devolvió el ID del vendedor.',
        error: true,
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminVendedorDetalleScreen(idVendedor: id),
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  Future<void> _crearCuenta() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminVendedorFormScreen(),
      ),
    );

    if (creada == true && mounted) {
      await _load();
    }
  }

  void _message(
    String mensaje, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas de vendedores'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearCuenta,
        icon: const Icon(Icons.person_add),
        label: const Text('Crear cuenta'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudieron cargar las cuentas '
                'de vendedores.\n$_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Colors.brown.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Cuentas encontradas: ${_vendedores.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (_vendedores.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Todavía no hay vendedores. '
                'Utiliza “Crear cuenta” para registrar uno.',
                textAlign: TextAlign.center,
              ),
            ),

          ..._vendedores.map(_buildVendedorCard),

          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Las contraseñas no se pueden consultar '
              'desde esta pantalla.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendedorCard(
    Map<String, dynamic> vendedor,
  ) {
    final id = _int(vendedor['id_vendedor']);
    final activo = vendedor['activo'] == true;

    final nombreCompleto = [
      vendedor['nombre'],
      vendedor['apellido_paterno'],
      vendedor['apellido_materno'],
    ]
        .where(
          (parte) =>
              parte != null &&
              parte.toString().trim().isNotEmpty,
        )
        .join(' ');

    final nombreMostrar = nombreCompleto.isEmpty
        ? 'Vendedor #${id ?? '—'}'
        : nombreCompleto;

    final correo =
        vendedor['correo']?.toString() ?? 'No disponible';
    final rol =
        vendedor['rol']?.toString() ?? 'Sin rol';
    final telefono =
        vendedor['telefono']?.toString() ?? 'No registrado';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: activo
              ? Colors.green.shade100
              : Colors.grey.shade300,
          child: Icon(
            Icons.badge_outlined,
            color: activo
                ? Colors.green.shade800
                : Colors.grey.shade700,
          ),
        ),
        title: Text(
          nombreMostrar,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Correo: $correo\n'
          'ID vendedor: ${id ?? '—'} · '
          '${activo ? 'Activo' : 'Inactivo'}\n'
          'Rol: $rol · Teléfono: $telefono',
        ),
        isThreeLine: true,
        onTap: () => _openDetail(vendedor),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: activo
                  ? 'Desactivar cuenta'
                  : 'Activar cuenta',
              onPressed: () => _setActive(vendedor),
              icon: Icon(
                activo
                    ? Icons.person_off_outlined
                    : Icons.person_add_alt_1_outlined,
              ),
              color: activo
                  ? Colors.red.shade700
                  : Colors.green.shade700,
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
