class ItemPedido {
  final int idProducto;
  final String? producto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  ItemPedido({
    required this.idProducto,
    this.producto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return ItemPedido(
      idProducto: json['id_producto'] ?? 0,
      producto: json['producto'] ?? 'Producto',
      cantidad: json['cantidad'] ?? 1,
      precioUnitario: parseNum(json['precio_unitario']),
      subtotal: parseNum(json['subtotal']),
    );
  }
}

class Pedido {
  final int idPedido;
  final String? fechaSolicitud;
  final String? fechaEntregaEstimada;
  final double anticipo;
  final String? observaciones;
  final String? artesano;
  final String? estado;
  final int idEstadoPedido;
  final double total;
  final List<ItemPedido> items;

  Pedido({
    required this.idPedido,
    this.fechaSolicitud,
    this.fechaEntregaEstimada,
    required this.anticipo,
    this.observaciones,
    this.artesano,
    this.estado,
    required this.idEstadoPedido,
    required this.total,
    required this.items,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    var rawItems = json['items'] as List? ?? [];
    List<ItemPedido> itemsLista = rawItems.map((i) => ItemPedido.fromJson(i)).toList();

    return Pedido(
      idPedido: json['id_pedido'] ?? 0,
      fechaSolicitud: json['fecha_solicitud'],
      fechaEntregaEstimada: json['fecha_entrega_estimada'],
      anticipo: parseNum(json['anticipo']),
      observaciones: json['observaciones'],
      artesano: json['artesano'] ?? 'Artesano de Bécal',
      estado: json['estado'] ?? 'Pendiente',
      idEstadoPedido: json['id_estado_pedido'] ?? 1,
      total: parseNum(json['total']),
      items: itemsLista,
    );
  }
}

class PedidoDetalle {
  final int idPedido;
  final String? fechaSolicitud;
  final String? fechaEntregaEstimada;
  final double anticipo;
  final String? observaciones;
  final String? cliente;
  final String? clienteTelefono;
  final String? clienteCorreo;
  final String? artesano;
  final String? artesanoTelefono;
  final String? puesto;
  final String? puestoNumero;
  final String? estado;
  final int idEstadoPedido;
  final double total;
  final List<ItemPedido> items;

  PedidoDetalle({
    required this.idPedido,
    this.fechaSolicitud,
    this.fechaEntregaEstimada,
    required this.anticipo,
    this.observaciones,
    this.cliente,
    this.clienteTelefono,
    this.clienteCorreo,
    this.artesano,
    this.artesanoTelefono,
    this.puesto,
    this.puestoNumero,
    this.estado,
    required this.idEstadoPedido,
    required this.total,
    required this.items,
  });

  factory PedidoDetalle.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    var rawItems = json['items'] as List? ?? [];
    List<ItemPedido> itemsLista = rawItems.map((i) => ItemPedido.fromJson(i)).toList();

    return PedidoDetalle(
      idPedido: json['id_pedido'] ?? 0,
      fechaSolicitud: json['fecha_solicitud'],
      fechaEntregaEstimada: json['fecha_entrega_estimada'],
      anticipo: parseNum(json['anticipo']),
      observaciones: json['observaciones'],
      cliente: json['cliente'],
      clienteTelefono: json['cliente_telefono'],
      clienteCorreo: json['cliente_correo'],
      artesano: json['artesano'],
      artesanoTelefono: json['artesano_telefono'],
      puesto: json['puesto'],
      puestoNumero: json['puesto_numero'],
      estado: json['estado'] ?? 'Pendiente',
      idEstadoPedido: json['id_estado_pedido'] ?? 1,
      total: parseNum(json['total']),
      items: itemsLista,
    );
  }
}