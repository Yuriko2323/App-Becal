import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class _CatalogField {
  final String key;
  final String label;
  final bool required;
  final bool numeric;
  final int maxLines;
  final bool provider;

  const _CatalogField({
    required this.key,
    required this.label,
    this.required = false,
    this.numeric = false,
    this.maxLines = 1,
    this.provider = false,
  });
}

class _CatalogSpec {
  final String endpoint;
  final String idKey;
  final String title;
  final List<_CatalogField> fields;

  const _CatalogSpec({
    required this.endpoint,
    required this.idKey,
    required this.title,
    required this.fields,
  });
}

class AdminCatalogosScreen extends StatefulWidget {
  const AdminCatalogosScreen({super.key});

  @override
  State<AdminCatalogosScreen> createState() => _AdminCatalogosScreenState();
}

class _AdminCatalogosScreenState extends State<AdminCatalogosScreen> {
  static const List<_CatalogSpec> _specs = [
    _CatalogSpec(
      endpoint: 'categorias-estilo',
      idKey: 'id_estilo',
      title: 'Estilos',
      fields: [
        _CatalogField(
            key: 'nombre_estilo', label: 'Nombre del estilo', required: true),
        _CatalogField(key: 'descripcion', label: 'Descripción', maxLines: 3),
      ],
    ),
    _CatalogSpec(
      endpoint: 'calidades',
      idKey: 'id_calidad',
      title: 'Calidades',
      fields: [
        _CatalogField(
            key: 'nombre_calidad', label: 'Nombre de calidad', required: true),
        _CatalogField(
            key: 'dias_elaboracion_estimados',
            label: 'Días estimados de elaboración',
            numeric: true),
        _CatalogField(
            key: 'numero_partidas', label: 'Número de partidas', numeric: true),
      ],
    ),
    _CatalogSpec(
      endpoint: 'materiales',
      idKey: 'id_material',
      title: 'Materiales',
      fields: [
        _CatalogField(
            key: 'nombre_material',
            label: 'Nombre del material',
            required: true),
        _CatalogField(key: 'unidad_medida', label: 'Unidad de medida'),
        _CatalogField(
            key: 'id_proveedor',
            label: 'Proveedor',
            required: true,
            numeric: true,
            provider: true),
      ],
    ),
  ];

  bool _loading = true;
  String? _error;
  final Map<String, List<Map<String, dynamic>>> _records = {};
  List<Map<String, dynamic>> _providers = [];

  int? _toInt(dynamic value) => value is int ? value : int.tryParse('$value');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<Map<String, dynamic>>> _readList(String endpoint) async {
    final data = await ApiClient.get('/$endpoint?skip=0&limit=200');
    if (data is! List) throw Exception('Respuesta inválida de /$endpoint.');
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final results = await Future.wait([
        for (final spec in _specs) _readList(spec.endpoint),
        _readList('proveedores'),
      ]);
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _specs.length; i++) {
          _records[_specs[i].endpoint] = results[i];
        }
        _providers = results.last;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _message(String value, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
      backgroundColor: error ? Colors.red.shade700 : null,
    ));
  }

  String _displayName(_CatalogSpec spec, Map<String, dynamic> item) {
    final fields = spec.fields.where((f) => !f.provider).toList();
    if (fields.isEmpty) return '${spec.title} #${item[spec.idKey] ?? '—'}';
    final value = item[fields.first.key]?.toString().trim() ?? '';
    return value.isEmpty ? '${spec.title} #${item[spec.idKey] ?? '—'}' : value;
  }

  String _summary(_CatalogSpec spec, Map<String, dynamic> item) {
    final parts = <String>[];
    for (final field in spec.fields) {
      if (field.provider) {
        final providerId = _toInt(item[field.key]);
        final supplier = _providers
            .where((p) => _toInt(p['id_proveedor']) == providerId)
            .toList();
        final providerName = supplier.isEmpty
            ? 'Proveedor #${providerId ?? '—'}'
            : (supplier.first['nombre_proveedor'] ??
                    supplier.first['nombre'] ??
                    'Proveedor #$providerId')
                .toString();
        parts.add('${field.label}: $providerName');
      } else {
        final value = item[field.key];
        if (value != null && value.toString().trim().isNotEmpty) {
          parts.add('${field.label}: $value');
        }
      }
    }
    return parts.join(' · ');
  }

  Future<void> _form(_CatalogSpec spec,
      [Map<String, dynamic>? existing]) async {
    final controllers = <String, TextEditingController>{};
    for (final field in spec.fields.where((f) => !f.provider)) {
      controllers[field.key] = TextEditingController(
        text: existing?[field.key]?.toString() ?? '',
      );
    }
    int? providerId = _toInt(existing?['id_proveedor']);
    final providerIds = _providers
        .map((p) => _toInt(p['id_proveedor']))
        .whereType<int>()
        .toSet();
    if (!providerIds.contains(providerId)) {
      if (existing == null) {
        providerId = _providers.isEmpty
            ? null
            : _toInt(_providers.first['id_proveedor']);
      } else if (_providers.isNotEmpty) {
        providerId = _toInt(_providers.first['id_proveedor']);
      }
    }

    if (spec.fields.any((f) => f.provider) &&
        _providers.isEmpty &&
        existing == null) {
      _dispose(controllers);
      _message(
          'Primero registra al menos un proveedor para poder crear materiales.',
          error: true);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) => AlertDialog(
          title: Text(existing == null
              ? 'Nuevo registro · ${spec.title}'
              : 'Editar · ${spec.title}'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final field in spec.fields)
                    if (field.provider)
                      DropdownButtonFormField<int>(
                        value: providerId,
                        isExpanded: true,
                        decoration: InputDecoration(
                            labelText:
                                '${field.label}${field.required ? ' *' : ''}',
                            border: const OutlineInputBorder()),
                        items: [
                          if (providerId != null &&
                              !_providers.any((p) =>
                                  _toInt(p['id_proveedor']) == providerId))
                            DropdownMenuItem<int>(
                                value: providerId,
                                child:
                                    Text('Proveedor #$providerId (existente)')),
                          ..._providers.map((p) {
                            final id = _toInt(p['id_proveedor']);
                            if (id == null) return null;
                            final name = p['nombre_proveedor'] ??
                                p['nombre'] ??
                                'Proveedor #$id';
                            return DropdownMenuItem<int>(
                                value: id, child: Text('$name'));
                          }).whereType<DropdownMenuItem<int>>(),
                        ],
                        onChanged: (value) =>
                            dialogSetState(() => providerId = value),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: controllers[field.key],
                          keyboardType: field.numeric
                              ? TextInputType.number
                              : TextInputType.text,
                          maxLines: field.maxLines,
                          decoration: InputDecoration(
                            labelText:
                                '${field.label}${field.required ? ' *' : ''}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (ok != true) {
      _dispose(controllers);
      return;
    }

    final body = <String, dynamic>{};
    String? missing;
    for (final field in spec.fields) {
      if (field.provider) {
        if (providerId == null) {
          missing = field.label;
        } else {
          body[field.key] = providerId;
        }
        continue;
      }
      final text = controllers[field.key]!.text.trim();
      if (field.required && text.isEmpty) {
        missing = field.label;
        break;
      }
      if (field.numeric) {
        if (text.isEmpty) {
          body[field.key] = null;
        } else {
          final parsed = int.tryParse(text);
          if (parsed == null || parsed < 0) {
            missing = 'un valor numérico válido para ${field.label}';
            break;
          }
          body[field.key] = parsed;
        }
      } else {
        body[field.key] = text.isEmpty ? null : text;
      }
    }
    _dispose(controllers);

    if (missing != null) {
      _message('Revisa el campo: $missing.', error: true);
      return;
    }

    try {
      final id = _toInt(existing?[spec.idKey]);
      if (id == null) {
        await ApiClient.post('/${spec.endpoint}', body: body);
        _message('Registro creado. El ID lo asignó la base de datos.');
      } else {
        await ApiClient.patch('/${spec.endpoint}/$id', body: body);
        _message('Registro actualizado.');
      }
      await _load();
    } catch (e) {
      _message('No se pudo guardar ${spec.title.toLowerCase()}: $e',
          error: true);
    }
  }

  void _dispose(Map<String, TextEditingController> controllers) {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Widget _buildTab(_CatalogSpec spec) {
    final items = _records[spec.endpoint] ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('${spec.title}: ${items.length} registros'),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                  'No hay registros en este catálogo. Agrega el primero.',
                  textAlign: TextAlign.center),
            ),
          for (final item in items)
            Card(
              child: ListTile(
                title: Text(_displayName(spec, item)),
                subtitle: Text(
                    'ID ${item[spec.idKey] ?? '—'} · ${_summary(spec, item)}'),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Editar registro',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _form(spec, item),
                ),
              ),
            ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: _specs.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Catálogos del sistema'),
            backgroundColor: Colors.brown.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar')
            ],
            bottom: const TabBar(
              isScrollable: true,
              labelColor:
                  Colors.white, // Color del texto de la pestaña seleccionada
              unselectedLabelColor: Colors
                  .white70, // Color del texto inactivo (blanco ligeramente transparente)
              indicatorColor: Colors
                  .white, // Color de la línea que subraya la pestaña activa
              tabs: [
                Tab(text: 'Estilos'),
                Tab(text: 'Calidades'),
                Tab(text: 'Materiales')
              ],
            ),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                'No se pudieron cargar los catálogos.\n$_error',
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                                onPressed: _load,
                                child: const Text('Reintentar')),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(children: _specs.map(_buildTab).toList()),
          floatingActionButton: Builder(
            builder: (context) => FloatingActionButton.extended(
              onPressed: () {
                final index = DefaultTabController.of(context).index;
                _form(_specs[index]);
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ),
        ),
      );
}
