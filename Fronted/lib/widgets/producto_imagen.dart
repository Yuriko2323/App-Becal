import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';

/// Muestra URL absoluta, ruta relativa /uploads/... o Base64 legado.
class ProductoImagen extends StatelessWidget {
  final String? origen;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool permitirZoom;
  const ProductoImagen({super.key, required this.origen, this.fit = BoxFit.contain, this.width, this.height, this.permitirZoom = false});

  ImageProvider? _provider() {
    final raw = origen?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return NetworkImage(raw);
    if (raw.startsWith('/') || raw.startsWith('uploads/')) {
      final path = raw.startsWith('/') ? raw : '/$raw';
      return NetworkImage('${ApiConfig.baseUrl}$path');
    }
    try {
      var b64 = raw.startsWith('data:') && raw.contains(',') ? raw.substring(raw.indexOf(',') + 1) : raw;
      b64 = b64.replaceAll(RegExp(r'\s+'), '');
      while (b64.length % 4 != 0) { b64 += '='; }
      return MemoryImage(base64Decode(b64));
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider();
    if (provider == null) return SizedBox(width: width, height: height, child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 44, color: Colors.grey)));
    final image = Image(image: provider, fit: fit, width: width, height: height, filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 44, color: Colors.grey)));
    if (!permitirZoom) return image;
    return GestureDetector(onTap: () => showDialog<void>(context: context, builder: (ctx) => Dialog.fullscreen(
      backgroundColor: Colors.black, child: Stack(children: [
        Center(child: InteractiveViewer(minScale: 0.5, maxScale: 5, child: Image(image: provider, fit: BoxFit.contain))),
        Positioned(right: 12, top: 24, child: IconButton(color: Colors.white, icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))),
      ]))), child: image);
  }
}
