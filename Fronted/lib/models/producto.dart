class Producto {
  final int idProducto;
  final String? nombre;
  final String? descripcion;
  final String? imagenUrl;
  final double? precioBase;
  final String? talla;
  final String? color;
  final String? material;
  final String? tipoTejido;
  final int? numPartida;
  final bool activo;
  final int idArtesano;
  final int idEstilo;
  final int idCalidad;

  Producto({
    required this.idProducto,
    this.nombre,
    this.descripcion,
    this.imagenUrl,
    this.precioBase,
    this.talla,
    this.color,
    this.material,
    this.tipoTejido,
    this.numPartida,
    required this.activo,
    required this.idArtesano,
    required this.idEstilo,
    required this.idCalidad,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    double? parsePrecio(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return Producto(
      idProducto: json['id_producto'] ?? 0,
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      imagenUrl: json['imagen_url'] as String?,
      precioBase: parsePrecio(json['precio_base']),
      talla: json['talla'],
      color: json['color'],
      material: json['material'],
      tipoTejido: json['tipo_tejido'],
      numPartida: json['num_partida'],
      activo: json['activo'] ?? true,
      idArtesano: json['id_artesano'] ?? 0,
      idEstilo: json['id_estilo'] ?? 0,
      idCalidad: json['id_calidad'] ?? 0,
    );
  }
}