class Cliente {
  final int idCliente;
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? telefono;
  final String? nacionalidad;
  final String? idiomaPreferido;
  final String? tipoCliente;
  final String? fotoPerfil;
  final bool activo;
  final int idUsuario;

  Cliente({
    required this.idCliente,
    this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.telefono,
    this.nacionalidad,
    this.idiomaPreferido,
    this.tipoCliente,
    this.fotoPerfil,
    required this.activo,
    required this.idUsuario,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['id_cliente'],
      nombre: json['nombre'],
      apellidoPaterno: json['apellido_p'],
      apellidoMaterno: json['apellido_m'],
      telefono: json['telefono'],
      nacionalidad: json['nacionalidad'],
      idiomaPreferido: json['idioma_preferido'],
      tipoCliente: json['tipo_cliente'],
      fotoPerfil: json['foto_perfil'],
      activo: json['activo'] ?? true,
      idUsuario: json['id_usuario'],
    );
  }

  String get nombreCompleto {
    final partes = [nombre, apellidoPaterno, apellidoMaterno]
        .where((e) => e != null && e.trim().isNotEmpty);
    return partes.isNotEmpty ? partes.join(' ') : 'Cliente sin nombre';
  }
}