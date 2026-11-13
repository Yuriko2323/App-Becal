class FotoProducto {
  final int idFoto;
  final int idProducto;
  final String urlImagen;
  final bool esPrincipal;
  final int orden;
  const FotoProducto({required this.idFoto, required this.idProducto, required this.urlImagen, required this.esPrincipal, required this.orden});
  factory FotoProducto.fromJson(Map<String, dynamic> json) => FotoProducto(
    idFoto: _int(json['id_foto']), idProducto: _int(json['id_producto']),
    urlImagen: (json['url_imagen'] ?? '').toString(), esPrincipal: json['es_principal'] == true,
    orden: _int(json['orden']),
  );
}
int _int(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
