class Usuario {
  final int idUsuario;
  final int? idCliente;
  final int? idArtesano;
  final int? idVendedor;
  final String tipoUsuario;
  final String correo;
  final String nombre;

  const Usuario({required this.idUsuario, this.idCliente, this.idArtesano, this.idVendedor, required this.tipoUsuario, required this.correo, required this.nombre});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) => value is int ? value : (value is num ? value.toInt() : int.tryParse(value?.toString() ?? ''));
    return Usuario(
      idUsuario: asInt(json['id_usuario']) ?? (throw const FormatException('La API no devolvió id_usuario.')),
      idCliente: asInt(json['id_cliente']),
      idArtesano: asInt(json['id_artesano']),
      idVendedor: asInt(json['id_vendedor']),
      tipoUsuario: (json['tipo_usuario'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}
