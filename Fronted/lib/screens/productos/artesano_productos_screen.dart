import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../models/producto.dart';
import '../../services/producto_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/producto_imagen.dart';

class ArtesanoProductosScreen extends StatefulWidget {
  final int idArtesano;

  const ArtesanoProductosScreen({super.key, required this.idArtesano});

  @override
  State<ArtesanoProductosScreen> createState() =>
      _ArtesanoProductosScreenState();
}

class _ArtesanoProductosScreenState extends State<ArtesanoProductosScreen> {
  final _service = ProductoService();
  late Future<List<Producto>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _service.obtenerProductosArtesano(widget.idArtesano);
  }

  int? _toInt(dynamic value) =>
      value is int ? value : int.tryParse('$value');

  List<Map<String, dynamic>> _asMaps(dynamic data, String label) {
    if (data is! List) {
      throw Exception('La API devolvió un catálogo de $label inválido.');
    }
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _message(String value, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _form([Producto? product]) async {
    late List<Map<String, dynamic>> styles;
    late List<Map<String, dynamic>> qualities;

    try {
      final results = await Future.wait([
        ApiClient.get('/categorias-estilo?skip=0&limit=200'),
        ApiClient.get('/calidades?skip=0&limit=200'),
      ]);
      styles = _asMaps(results[0], 'estilos');
      qualities = _asMaps(results[1], 'calidades');
    } catch (e) {
      _message('No se pudieron cargar los catálogos: $e', error: true);
      return;
    }

    int? idFrom(Map<String, dynamic> item, String key) =>
        _toInt(item[key]);
    styles = styles.where((item) => idFrom(item, 'id_estilo') != null).toList();
    qualities = qualities
        .where((item) => idFrom(item, 'id_calidad') != null)
        .toList();

    if (styles.isEmpty || qualities.isEmpty) {
      _message(
        'Antes de registrar productos, el administrador debe agregar al menos '
        'un estilo y una calidad en Catálogos del sistema.',
        error: true,
      );
      return;
    }

    final nameController = TextEditingController(text: product?.nombre ?? '');
    final priceController = TextEditingController(
      text: product?.precioBase?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: product?.descripcion ?? '',
    );
    final materialController = TextEditingController(
      text: product?.material ?? '',
    );
    final colorController = TextEditingController(text: product?.color ?? '');
    final sizeController = TextEditingController(text: product?.talla ?? '');

    final styleIds = styles.map((s) => idFrom(s, 'id_estilo')!).toSet();
    final qualityIds = qualities.map((q) => idFrom(q, 'id_calidad')!).toSet();
    int? selectedStyleId =
        styleIds.contains(product?.idEstilo)
            ? product!.idEstilo
            : idFrom(styles.first, 'id_estilo');
    int? selectedQualityId =
        qualityIds.contains(product?.idCalidad)
            ? product!.idCalidad
            : idFrom(qualities.first, 'id_calidad');

    Uint8List? imageBytes;
    String? imageName;
    bool picking = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) => AlertDialog(
          title: Text(
            product == null ? 'Nuevo producto' : 'Editar producto',
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(nameController, 'Nombre *'),
                  _field(
                    priceController,
                    'Precio *',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _field(descriptionController, 'Descripción', maxLines: 3),
                  _field(materialController, 'Material'),
                  _field(colorController, 'Color'),
                  _field(sizeController, 'Talla'),
                  DropdownButtonFormField<int>(
                    value: selectedStyleId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Estilo *',
                      border: OutlineInputBorder(),
                    ),
                    items: styles.map((style) {
                      final id = idFrom(style, 'id_estilo')!;
                      final label =
                          style['nombre_estilo']?.toString().trim().isNotEmpty ==
                                  true
                              ? style['nombre_estilo'].toString()
                              : 'Estilo #$id';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        dialogSetState(() => selectedStyleId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedQualityId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Calidad *',
                      border: OutlineInputBorder(),
                    ),
                    items: qualities.map((quality) {
                      final id = idFrom(quality, 'id_calidad')!;
                      final label =
                          quality['nombre_calidad']?.toString().trim().isNotEmpty ==
                                  true
                              ? quality['nombre_calidad'].toString()
                              : 'Calidad #$id';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        dialogSetState(() => selectedQualityId = value),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Fotografía del producto',
                      style: Theme.of(dialogContext).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (imageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    )
                  else if ((product?.imagenUrl ?? '').trim().isNotEmpty)
                    SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: ProductoImagen(
                        origen: product!.imagenUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  if (imageName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        imageName!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: picking
                        ? null
                        : () async {
                            dialogSetState(() => picking = true);
                            try {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: const [
                                  'jpg',
                                  'jpeg',
                                  'png',
                                  'webp',
                                ],
                                allowMultiple: false,
                                withData: true,
                              );
                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.single;
                                if (file.size > 5 * 1024 * 1024) {
                                  _message(
                                    'La imagen supera 5 MB. Selecciona una '
                                    'imagen más pequeña.',
                                    error: true,
                                  );
                                } else if (file.bytes == null ||
                                    file.bytes!.isEmpty) {
                                  _message(
                                    'No se pudo leer el archivo seleccionado.',
                                    error: true,
                                  );
                                } else {
                                  dialogSetState(() {
                                    imageBytes = file.bytes;
                                    imageName = file.name;
                                  });
                                }
                              }
                            } catch (e) {
                              _message(
                                'No se pudo abrir el selector de archivos: $e',
                                error: true,
                              );
                            } finally {
                              dialogSetState(() => picking = false);
                            }
                          },
                    icon: picking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      picking
                          ? 'Abriendo archivos...'
                          : 'Elegir imagen desde archivos',
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'JPG, PNG o WEBP. Máximo 5 MB. La foto se guarda en el servidor.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      _disposeControllers([
        nameController,
        priceController,
        descriptionController,
        materialController,
        colorController,
        sizeController,
      ]);
      return;
    }

    final nameValue = nameController.text.trim();
    final priceValue = double.tryParse(
      priceController.text.replaceAll(',', '.').trim(),
    );
    if (nameValue.isEmpty ||
        priceValue == null ||
        priceValue <= 0 ||
        selectedStyleId == null ||
        selectedQualityId == null) {
      _message(
        'Revisa los campos obligatorios: nombre, precio mayor que cero, estilo y calidad.',
        error: true,
      );
      _disposeControllers([
        nameController,
        priceController,
        descriptionController,
        materialController,
        colorController,
        sizeController,
      ]);
      return;
    }

    final body = <String, dynamic>{
      'nombre': nameValue,
      'precio_base': priceValue,
      'descripcion': _nullableText(descriptionController.text),
      'material': _nullableText(materialController.text),
      'color': _nullableText(colorController.text),
      'talla': _nullableText(sizeController.text),
      'id_estilo': selectedStyleId,
      'id_calidad': selectedQualityId,
      'imagen_url': product?.imagenUrl,
      if (product == null) 'id_artesano': widget.idArtesano,
      // No enviamos id_producto: SQL Server lo genera como IDENTITY.
    };
    _disposeControllers([
      nameController,
      priceController,
      descriptionController,
      materialController,
      colorController,
      sizeController,
    ]);

    var productSaved = false;
    try {
      int productId;
      if (product == null) {
        final created = await _service.crearProducto(body);
        productSaved = true;
        productId = created is Map ? (_toInt(created['id_producto']) ?? 0) : 0;
      } else {
        await _service.actualizarProducto(product.idProducto, body);
        productSaved = true;
        productId = product.idProducto;
      }

      if (imageBytes != null) {
        if (productId <= 0) {
          throw Exception(
            'El producto se guardó, pero la API no devolvió id_producto; '
            'no se pudo asociar la imagen.',
          );
        }
        await _service.subirImagen(
          productId,
          imageBytes!,
          imageName ?? 'producto.jpg',
        );
      }

      _message(
        imageBytes == null
            ? 'Producto guardado.'
            : 'Producto e imagen guardados.',
      );
      if (mounted) setState(_load);
    } catch (e) {
      _message(
        productSaved
            ? 'El producto se guardó, pero hubo un problema con la imagen o la respuesta de la API: $e'
            : 'No se pudo guardar el producto: $e',
        error: true,
      );
      if (productSaved && mounted) setState(_load);
    }
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> _changeProductState(Producto product, bool active) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(active ? 'Activar producto' : 'Desactivar producto'),
        content: Text(
          active
              ? '¿Volver a publicar “${product.nombre}” en el catálogo?'
              : '¿Ocultar “${product.nombre}” del catálogo? No se eliminará físicamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(active ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.cambiarEstadoProducto(product.idProducto, active);
      _message(active ? 'Producto activado.' : 'Producto desactivado.');
      if (mounted) setState(_load);
    } catch (e) {
      _message(
        'No se pudo ${active ? 'activar' : 'desactivar'} el producto: $e. '
        'Verifica que se haya agregado la ruta de estado a la API.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mis productos')),
        body: FutureBuilder<List<Producto>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error al cargar productos: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(_load),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final products = snapshot.data ?? [];
            return RefreshIndicator(
              onRefresh: () async {
                setState(_load);
                await _future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                children: [
                  FilledButton.icon(
                    onPressed: () => _form(),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar producto'),
                  ),
                  const SizedBox(height: 8),
                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No tienes productos registrados.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ...products.map((product) => Card(
                        child: ListTile(
                          leading: SizedBox(
                            width: 60,
                            height: 60,
                            child: ProductoImagen(
                              origen: product.imagenUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                          title: Text(product.nombre ?? 'Sin nombre'),
                          subtitle: Text(
                            '${formatoMoneda(product.precioBase)} · '
                            '${product.activo ? 'Activo' : 'Inactivo'}',
                          ),
                          trailing: Wrap(
                            spacing: 0,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => _form(product),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: product.activo
                                    ? 'Desactivar producto'
                                    : 'Volver a activar producto',
                                onPressed: () => _changeProductState(
                                  product,
                                  !product.activo,
                                ),
                                icon: Icon(
                                  product.activo
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                color: product.activo
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            );
          },
        ),
      );

  static Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
