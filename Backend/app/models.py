from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, Integer, Numeric, String, Text, Time, func
from sqlalchemy.orm import DeclarativeBase, relationship

class Base(DeclarativeBase):
    pass

class Vendedor(Base):
    __tablename__ = 'Vendedor'
    id_vendedor = Column('Id_vendedor', Integer, primary_key=True, autoincrement=True)
    telefono = Column(String(15), nullable=True)
    nombre = Column(String(50), nullable=True)
    rol = Column(String(30), nullable=True)
    apellido_materno = Column('Apellido_M', String(50), nullable=True)
    apellido_paterno = Column('Apellido_p', String(50), nullable=True)
    activo = Column(Boolean, nullable=False, server_default='1')
    id_usuario = Column(Integer, ForeignKey('Usuario.id_usuario'), nullable=False)
    usuario = relationship('Usuario', foreign_keys=[id_usuario])

class Producto(Base):
    __tablename__ = 'Producto'
    id_producto = Column('Id_producto', Integer, primary_key=True, autoincrement=True)
    imagen_url = Column(String(300), nullable=True)
    descripcion = Column(String(250), nullable=True)
    num_partida = Column('Num_partida', Integer, nullable=True)
    talla = Column(String(10), nullable=True)
    color = Column(String(30), nullable=True)
    nombre = Column(String(100), nullable=True)
    # Ampliado de 10 a 30: "tipo de tejido" no cabía en 10 caracteres.
    tipo_tejido = Column(String(30), nullable=True)
    precio_base = Column(Numeric(20, 2), nullable=True)
    material = Column('Material', String(30), nullable=True)
    activo = Column(Boolean, nullable=False, server_default='1')
    id_artesano = Column(Integer, ForeignKey('Artesano.id_artesano'), nullable=False)
    id_estilo = Column(Integer, ForeignKey('Categoria_Estilo.id_estilo'), nullable=False)
    id_calidad = Column(Integer, ForeignKey('Calidad.id_calidad'), nullable=False)
    artesano = relationship('Artesano', foreign_keys=[id_artesano])
    categoriaEstilo = relationship('CategoriaEstilo', foreign_keys=[id_estilo])
    calidad = relationship('Calidad', foreign_keys=[id_calidad])

class FotoProducto(Base):
    """Galería de fotos por producto. Sustituye a la columna única
    Producto.imagen_url para poder tener varias fotos por producto."""
    __tablename__ = 'Foto_Producto'
    id_foto = Column(Integer, primary_key=True, autoincrement=True)
    id_producto = Column(Integer, ForeignKey('Producto.Id_producto'), nullable=False)
    url_imagen = Column(String(300), nullable=False)
    es_principal = Column(Boolean, nullable=False, server_default='0')
    orden = Column(Integer, nullable=True)
    fecha_subida = Column(DateTime, nullable=False, server_default=func.now())
    producto = relationship('Producto', foreign_keys=[id_producto])

class PrecioMayorista(Base):
    """Precio escalonado por cantidad mínima, para clientes con
    tipo_cliente = 'Mayorista'."""
    __tablename__ = 'Precio_Mayorista'
    id_precio_mayorista = Column(Integer, primary_key=True, autoincrement=True)
    id_producto = Column(Integer, ForeignKey('Producto.Id_producto'), nullable=False)
    cantidad_minima = Column(Integer, nullable=False)
    precio_unitario = Column(Numeric(20, 2), nullable=False)
    producto = relationship('Producto', foreign_keys=[id_producto])

class Cliente(Base):
    __tablename__ = 'Cliente'
    id_cliente = Column(Integer, primary_key=True, autoincrement=True)
    idioma_preferido = Column(String(50), nullable=True)
    nacionalidad = Column(String(50), nullable=True)
    tipo_cliente = Column(String(30), nullable=True)
    telefono = Column(String(15), nullable=True)
    nombre = Column(String(50), nullable=True)
    apellido_m = Column(String(50), nullable=True)
    apellido_p = Column(String(50), nullable=True)
    foto_perfil = Column(String, nullable=True)
    activo = Column(Boolean, nullable=False, server_default='1')
    id_usuario = Column(Integer, ForeignKey('Usuario.id_usuario'), nullable=False)
    usuario = relationship('Usuario', foreign_keys=[id_usuario])

class Pedido(Base):
    __tablename__ = 'Pedido'
    id_pedido = Column(Integer, primary_key=True, autoincrement=True)
    fecha_solicitud = Column(Date, nullable=True)
    fecha_entrega_estimada = Column(Date, nullable=True)
    anticipo = Column(Numeric(10, 2), nullable=True)
    observaciones = Column(Text, nullable=True)
    id_cliente = Column(Integer, ForeignKey('Cliente.id_cliente'), nullable=False)
    id_puesto = Column('Id_puesto', Integer, ForeignKey('Puesto.Id_puesto'), nullable=False)
    id_artesano = Column(Integer, ForeignKey('Artesano.id_artesano'), nullable=False)
    id_estado_pedido = Column(Integer, ForeignKey('Estado_Pedido.id_estado_pedido'), nullable=False)
    cliente = relationship('Cliente', foreign_keys=[id_cliente])
    puesto = relationship('Puesto', foreign_keys=[id_puesto])
    artesano = relationship('Artesano', foreign_keys=[id_artesano])
    estadoPedido = relationship('EstadoPedido', foreign_keys=[id_estado_pedido])

class Puesto(Base):
    __tablename__ = 'Puesto'
    id_puesto = Column('Id_puesto', Integer, primary_key=True)
    horario_cierre = Column(Time, nullable=True)
    horario_apertura = Column(Time, nullable=True)
    estado = Column(String(20), nullable=True)
    categoria = Column(String(10), nullable=True)
    numero_puesto = Column(String(10), nullable=True)
    ubicacion_sector = Column(String(100), nullable=True)
    # Ampliado de 10 a 100: un nombre de local real no cabía en 10 caracteres.
    nombre_puesto = Column(String(100), nullable=True)

class DetallePedido(Base):
    __tablename__ = 'Detalle_Pedido'
    id_detalle_pedido = Column(Integer, primary_key=True, autoincrement=True)
    cantidad = Column(Integer, nullable=True)
    precio_acordado = Column(Numeric(10, 2), nullable=True)
    id_producto = Column('Id_producto', Integer, ForeignKey('Producto.Id_producto'), nullable=False)
    id_pedido = Column(Integer, ForeignKey('Pedido.id_pedido'), nullable=False)
    producto = relationship('Producto', foreign_keys=[id_producto])
    pedido = relationship('Pedido', foreign_keys=[id_pedido])

class CategoriaEstilo(Base):
    __tablename__ = 'Categoria_Estilo'
    id_estilo = Column(Integer, primary_key=True, autoincrement=True)
    descripcion = Column(Text, nullable=True)
    nombre_estilo = Column(String(50), nullable=True)

class Calidad(Base):
    __tablename__ = 'Calidad'
    id_calidad = Column(Integer, primary_key=True, autoincrement=True)
    nombre_calidad = Column(String(50), nullable=True)
    dias_elaboracion_estimados = Column(Integer, nullable=True)
    numero_partidas = Column(Integer, nullable=True)

class Material(Base):
    __tablename__ = 'Material'
    id_material = Column(Integer, primary_key=True, autoincrement=True)
    nombre_material = Column(String(100), nullable=True)
    unidad_medida = Column(String(20), nullable=True)
    id_proveedor = Column('id_Proveedor', Integer, ForeignKey('Proveedor.id_Proveedor'), nullable=False)
    proveedor = relationship('Proveedor', foreign_keys=[id_proveedor])

class Cueva(Base):
    __tablename__ = 'Cueva'
    id_cueva = Column(Integer, primary_key=True, autoincrement=True)
    direccion_ubicacion = Column(String(200), nullable=True)
    tipo_cueva = Column(String(50), nullable=True)
    nombre_cueva = Column(String(100), nullable=True)

class Venta(Base):
    __tablename__ = 'Venta'
    id_venta = Column(Integer, primary_key=True, autoincrement=True)
    id_vendedor = Column('Id_vendedor', Integer, ForeignKey('Vendedor.Id_vendedor'), nullable=False)
    fecha_hora = Column(DateTime, nullable=True)
    metodo_pago = Column(String(30), nullable=True)
    id_puesto = Column('Id_puesto', Integer, ForeignKey('Puesto.Id_puesto'), nullable=False)
    id_cliente = Column(Integer, ForeignKey('Cliente.id_cliente'), nullable=False)
    vendedor = relationship('Vendedor', foreign_keys=[id_vendedor])
    puesto = relationship('Puesto', foreign_keys=[id_puesto])
    cliente = relationship('Cliente', foreign_keys=[id_cliente])

class DetalleVenta(Base):
    __tablename__ = 'Detalle_Venta'
    id_detalle_venta = Column(Integer, primary_key=True, autoincrement=True)
    cantidad = Column(Integer, nullable=True)
    precio_unitario = Column(Numeric(20, 2), nullable=True)
    id_venta = Column(Integer, ForeignKey('Venta.id_venta'), nullable=False)
    id_producto = Column('Id_producto', Integer, ForeignKey('Producto.Id_producto'), nullable=False)
    venta = relationship('Venta', foreign_keys=[id_venta])
    producto = relationship('Producto', foreign_keys=[id_producto])

class AsignacionPuesto(Base):
    __tablename__ = 'Asignacion_Puesto'
    id_asignacion = Column(Integer, primary_key=True, autoincrement=True)
    id_vendedor = Column('Id_vendedor', Integer, ForeignKey('Vendedor.Id_vendedor'), nullable=False)
    turno = Column(String(30), nullable=True)
    fecha_fin = Column(Date, nullable=True)
    fecha_inicio = Column(Date, nullable=True)
    id_puesto = Column('Id_puesto', Integer, ForeignKey('Puesto.Id_puesto'), nullable=False)
    # Nueva: distingue una solicitud de empleo pendiente de una ya
    # aceptada o rechazada. Antes toda fila aquí era "ya está trabajando".
    estado = Column(String(20), nullable=False, server_default='Pendiente')
    puesto = relationship('Puesto', foreign_keys=[id_puesto])
    vendedor = relationship('Vendedor', foreign_keys=[id_vendedor])

class Artesano(Base):
    __tablename__ = 'Artesano'
    id_artesano = Column(Integer, primary_key=True, autoincrement=True)
    foto_perfil = Column(String(300), nullable=True)
    biografia = Column(String(250), nullable=True)
    fecha_registro = Column(Date, nullable=True)
    anios_experiencia = Column('años_experiencia', Integer, nullable=True)
    telefono = Column(String(15), nullable=True)
    apellido_materno = Column(String(50), nullable=True)
    apellido_paterno = Column(String(50), nullable=True)
    nombre = Column(String(50), nullable=True)
    activo = Column(Boolean, nullable=False, server_default='1')
    id_cueva = Column(Integer, ForeignKey('Cueva.id_cueva'), nullable=False)
    id_usuario = Column(Integer, ForeignKey('Usuario.id_usuario'), nullable=False)
    id_puesto = Column('Id_puesto', Integer, ForeignKey('Puesto.Id_puesto'), nullable=False)
    cueva = relationship('Cueva', foreign_keys=[id_cueva])
    usuario = relationship('Usuario', foreign_keys=[id_usuario])
    puesto = relationship('Puesto', foreign_keys=[id_puesto])

class Inventario(Base):
    __tablename__ = 'Inventario'
    id_inventario = Column(Integer, primary_key=True, autoincrement=True)
    fecha_actualizacion = Column(DateTime, nullable=True)
    stock_minimo = Column(Integer, nullable=True)
    stock_actual = Column(Integer, nullable=True)
    id_puesto = Column('Id_puesto', Integer, ForeignKey('Puesto.Id_puesto'), nullable=False)
    id_producto = Column('Id_producto', Integer, ForeignKey('Producto.Id_producto'), nullable=False)
    puesto = relationship('Puesto', foreign_keys=[id_puesto])
    producto = relationship('Producto', foreign_keys=[id_producto])

class EstadoPedido(Base):
    __tablename__ = 'Estado_Pedido'
    id_estado_pedido = Column(Integer, primary_key=True, autoincrement=True)
    nombre_estado = Column(String(50), nullable=True)

class Proveedor(Base):
    __tablename__ = 'Proveedor'
    id_proveedor = Column('id_Proveedor', Integer, primary_key=True, autoincrement=True)
    nombre_proveedor = Column(String(100), nullable=True)
    telefono = Column(String(15), nullable=True)

class Usuario(Base):
    __tablename__ = 'Usuario'
    id_usuario = Column(Integer, primary_key=True, autoincrement=True)
    tipo_usuario = Column(String(20), nullable=False)
    correo = Column(String(150), nullable=False)
    # La BD ahora define DEFAULT GETDATE() para esta columna
    fecha_registro = Column(DateTime, nullable=False, server_default=func.now())
    # La BD ahora define DEFAULT 1 para esta columna
    activo = Column(Boolean, nullable=False, server_default='1')
    contrasena_hash = Column(String(255), nullable=False)