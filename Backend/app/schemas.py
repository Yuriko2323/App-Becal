from datetime import date, datetime, time
from decimal import Decimal
from typing import Literal, Optional
from pydantic import BaseModel, ConfigDict, Field

# Valores permitidos por los CHECK constraints de la base de datos.
# Si agregas un valor nuevo en la BD, agrégalo también aquí.
RolVendedor = Literal['Cajero', 'Gerente', 'Mostrador']
# 'Admin' agregado: es quien crea las cuevas, los locales, y las cuentas
# de Artesano/Vendedor.
TipoUsuario = Literal['Artesano', 'Cliente', 'Vendedor', 'Admin']
TipoCliente = Literal['Local', 'Mayorista', 'Turista']
EstadoPuesto = Literal['Activo', 'Mantenimiento']
MetodoPago = Literal['Efectivo', 'Tarjeta', 'Transferencia']
TurnoAsignacion = Literal['Completo', 'Matutino', 'Vespertino']
# Nuevo: estado de una solicitud de empleo (Asignacion_Puesto).
EstadoSolicitud = Literal['Pendiente', 'Aceptado', 'Rechazado']

class ORMBase(BaseModel):
    model_config = ConfigDict(from_attributes=True)

class VendedorCreate(BaseModel):
    telefono: Optional[str] = None
    nombre: Optional[str] = None
    rol: Optional[RolVendedor] = None
    apellido_materno: Optional[str] = None
    apellido_paterno: Optional[str] = None
    id_usuario: int

class VendedorUpdate(BaseModel):
    telefono: Optional[str] = None
    nombre: Optional[str] = None
    rol: Optional[RolVendedor] = None
    apellido_materno: Optional[str] = None
    apellido_paterno: Optional[str] = None
    activo: Optional[bool] = None
    id_usuario: Optional[int] = None

class VendedorResponse(ORMBase):
    id_vendedor: int
    telefono: Optional[str] = None
    nombre: Optional[str] = None
    rol: Optional[RolVendedor] = None
    apellido_materno: Optional[str] = None
    apellido_paterno: Optional[str] = None
    activo: bool
    id_usuario: int

class ProductoCreate(BaseModel):
    
    imagen_url: Optional[str] = None
    descripcion: Optional[str] = None
    num_partida: Optional[int] = None
    talla: Optional[str] = None
    color: Optional[str] = None
    nombre: Optional[str] = None
    tipo_tejido: Optional[str] = None
    precio_base: Optional[Decimal] = None
    material: Optional[str] = None
    id_artesano: int
    id_estilo: int
    id_calidad: int

class ProductoUpdate(BaseModel):
    imagen_url: Optional[str] = None
    descripcion: Optional[str] = None
    num_partida: Optional[int] = None
    talla: Optional[str] = None
    color: Optional[str] = None
    nombre: Optional[str] = None
    tipo_tejido: Optional[str] = None
    precio_base: Optional[Decimal] = None
    material: Optional[str] = None
    activo: Optional[bool] = None
    id_artesano: Optional[int] = None
    id_estilo: Optional[int] = None
    id_calidad: Optional[int] = None

class ProductoResponse(ORMBase):
    id_producto: int
    imagen_url: Optional[str] = None
    descripcion: Optional[str] = None
    num_partida: Optional[int] = None
    talla: Optional[str] = None
    color: Optional[str] = None
    nombre: Optional[str] = None
    tipo_tejido: Optional[str] = None
    precio_base: Optional[Decimal] = None
    material: Optional[str] = None
    activo: bool
    id_artesano: int
    id_estilo: int
    id_calidad: int

class FotoProductoCreate(BaseModel):
    id_producto: int
    url_imagen: str
    es_principal: Optional[bool] = None
    orden: Optional[int] = None

class FotoProductoUpdate(BaseModel):
    id_producto: Optional[int] = None
    url_imagen: Optional[str] = None
    es_principal: Optional[bool] = None
    orden: Optional[int] = None

class FotoProductoResponse(ORMBase):
    id_foto: int
    id_producto: int
    url_imagen: str
    es_principal: bool
    orden: Optional[int] = None
    fecha_subida: datetime

class PrecioMayoristaCreate(BaseModel):
    id_producto: int
    cantidad_minima: int
    precio_unitario: Decimal

class PrecioMayoristaUpdate(BaseModel):
    id_producto: Optional[int] = None
    cantidad_minima: Optional[int] = None
    precio_unitario: Optional[Decimal] = None

class PrecioMayoristaResponse(ORMBase):
    id_precio_mayorista: int
    id_producto: int
    cantidad_minima: int
    precio_unitario: Decimal

class ClienteCreate(BaseModel):
    
    idioma_preferido: Optional[str] = None
    nacionalidad: Optional[str] = None
    tipo_cliente: Optional[TipoCliente] = None
    telefono: Optional[str] = None
    nombre: Optional[str] = None
    apellido_m: Optional[str] = None
    apellido_p: Optional[str] = None
    id_usuario: int

class ClienteUpdate(BaseModel):
    idioma_preferido: Optional[str] = None
    nacionalidad: Optional[str] = None
    tipo_cliente: Optional[TipoCliente] = None
    telefono: Optional[str] = None
    nombre: Optional[str] = None
    apellido_m: Optional[str] = None
    apellido_p: Optional[str] = None
    foto_perfil: Optional[str] = None
    activo: Optional[bool] = None
    id_usuario: Optional[int] = None

class ClienteResponse(ORMBase):
    id_cliente: int
    idioma_preferido: Optional[str] = None
    nacionalidad: Optional[str] = None
    tipo_cliente: Optional[TipoCliente] = None
    telefono: Optional[str] = None
    nombre: Optional[str] = None
    apellido_m: Optional[str] = None
    apellido_p: Optional[str] = None
    foto_perfil: Optional[str] = None
    activo: bool
    id_usuario: int

class PedidoCreate(BaseModel):
   
    fecha_solicitud: Optional[date] = None
    fecha_entrega_estimada: Optional[date] = None
    anticipo: Optional[Decimal] = None
    observaciones: Optional[str] = None
    id_cliente: int
    id_puesto: int
    id_artesano: int
    id_estado_pedido: int

class PedidoUpdate(BaseModel):
    fecha_solicitud: Optional[date] = None
    fecha_entrega_estimada: Optional[date] = None
    anticipo: Optional[Decimal] = None
    observaciones: Optional[str] = None
    id_cliente: Optional[int] = None
    id_puesto: Optional[int] = None
    id_artesano: Optional[int] = None
    id_estado_pedido: Optional[int] = None

class PedidoResponse(ORMBase):
    id_pedido: int
    fecha_solicitud: Optional[date] = None
    fecha_entrega_estimada: Optional[date] = None
    anticipo: Optional[Decimal] = None
    observaciones: Optional[str] = None
    id_cliente: int
    id_puesto: int
    id_artesano: int
    id_estado_pedido: int

class PuestoCreate(BaseModel):
    
    horario_cierre: Optional[time] = None
    horario_apertura: Optional[time] = None
    estado: Optional[EstadoPuesto] = None
    categoria: Optional[str] = None
    numero_puesto: Optional[str] = None
    ubicacion_sector: Optional[str] = None
    nombre_puesto: Optional[str] = None

class PuestoUpdate(BaseModel):
    horario_cierre: Optional[time] = None
    horario_apertura: Optional[time] = None
    estado: Optional[EstadoPuesto] = None
    categoria: Optional[str] = None
    numero_puesto: Optional[str] = None
    ubicacion_sector: Optional[str] = None
    nombre_puesto: Optional[str] = None

class PuestoResponse(ORMBase):
    id_puesto: int
    horario_cierre: Optional[time] = None
    horario_apertura: Optional[time] = None
    estado: Optional[EstadoPuesto] = None
    categoria: Optional[str] = None
    numero_puesto: Optional[str] = None
    ubicacion_sector: Optional[str] = None
    nombre_puesto: Optional[str] = None

class DetallePedidoCreate(BaseModel):
    
    cantidad: Optional[int] = None
    precio_acordado: Optional[Decimal] = None
    id_producto: int
    id_pedido: int

class DetallePedidoUpdate(BaseModel):
    cantidad: Optional[int] = None
    precio_acordado: Optional[Decimal] = None
    id_producto: Optional[int] = None
    id_pedido: Optional[int] = None

class DetallePedidoResponse(ORMBase):
    id_detalle_pedido: int
    cantidad: Optional[int] = None
    precio_acordado: Optional[Decimal] = None
    id_producto: int
    id_pedido: int

class CategoriaEstiloCreate(BaseModel):
    
    descripcion: Optional[str] = None
    nombre_estilo: Optional[str] = None

class CategoriaEstiloUpdate(BaseModel):
    descripcion: Optional[str] = None
    nombre_estilo: Optional[str] = None

class CategoriaEstiloResponse(ORMBase):
    id_estilo: int
    descripcion: Optional[str] = None
    nombre_estilo: Optional[str] = None

class CalidadCreate(BaseModel):
    
    nombre_calidad: Optional[str] = None
    dias_elaboracion_estimados: Optional[int] = None
    numero_partidas: Optional[int] = None

class CalidadUpdate(BaseModel):
    nombre_calidad: Optional[str] = None
    dias_elaboracion_estimados: Optional[int] = None
    numero_partidas: Optional[int] = None

class CalidadResponse(ORMBase):
    id_calidad: int
    nombre_calidad: Optional[str] = None
    dias_elaboracion_estimados: Optional[int] = None
    numero_partidas: Optional[int] = None

class MaterialCreate(BaseModel):
   
    nombre_material: Optional[str] = None
    unidad_medida: Optional[str] = None
    id_proveedor: int

class MaterialUpdate(BaseModel):
    nombre_material: Optional[str] = None
    unidad_medida: Optional[str] = None
    id_proveedor: Optional[int] = None

class MaterialResponse(ORMBase):
    id_material: int
    nombre_material: Optional[str] = None
    unidad_medida: Optional[str] = None
    id_proveedor: int

class CuevaCreate(BaseModel):
    
    direccion_ubicacion: Optional[str] = None
    tipo_cueva: Optional[str] = None
    nombre_cueva: Optional[str] = None

class CuevaUpdate(BaseModel):
    direccion_ubicacion: Optional[str] = None
    tipo_cueva: Optional[str] = None
    nombre_cueva: Optional[str] = None

class CuevaResponse(ORMBase):
    id_cueva: int
    direccion_ubicacion: Optional[str] = None
    tipo_cueva: Optional[str] = None
    nombre_cueva: Optional[str] = None

class VentaCreate(BaseModel):
   
    id_vendedor: int
    fecha_hora: Optional[datetime] = None
    metodo_pago: Optional[MetodoPago] = None
    id_puesto: int
    id_cliente: int

class VentaUpdate(BaseModel):
    id_vendedor: Optional[int] = None
    fecha_hora: Optional[datetime] = None
    metodo_pago: Optional[MetodoPago] = None
    id_puesto: Optional[int] = None
    id_cliente: Optional[int] = None

class VentaResponse(ORMBase):
    id_venta: int
    id_vendedor: int
    fecha_hora: Optional[datetime] = None
    metodo_pago: Optional[MetodoPago] = None
    id_puesto: int
    id_cliente: int

class DetalleVentaCreate(BaseModel):
    
    cantidad: Optional[int] = None
    precio_unitario: Optional[Decimal] = None
    id_venta: int
    id_producto: int

class DetalleVentaUpdate(BaseModel):
    cantidad: Optional[int] = None
    precio_unitario: Optional[Decimal] = None
    id_venta: Optional[int] = None
    id_producto: Optional[int] = None

class DetalleVentaResponse(ORMBase):
    id_detalle_venta: int
    cantidad: Optional[int] = None
    precio_unitario: Optional[Decimal] = None
    id_venta: int
    id_producto: int

class AsignacionPuestoCreate(BaseModel):
    # Antes faltaba este campo: sin él no se podía crear una asignación.
    id_vendedor: int
    turno: Optional[TurnoAsignacion] = None
    fecha_fin: Optional[date] = None
    fecha_inicio: Optional[date] = None
    id_puesto: int
    # Si se omite, la BD la pone en 'Pendiente' por default.
    estado: Optional[EstadoSolicitud] = None

class AsignacionPuestoUpdate(BaseModel):
    id_vendedor: Optional[int] = None
    turno: Optional[TurnoAsignacion] = None
    fecha_fin: Optional[date] = None
    fecha_inicio: Optional[date] = None
    id_puesto: Optional[int] = None
    estado: Optional[EstadoSolicitud] = None

class AsignacionPuestoResponse(ORMBase):
    id_asignacion: int
    id_vendedor: int
    turno: Optional[TurnoAsignacion] = None
    fecha_fin: Optional[date] = None
    fecha_inicio: Optional[date] = None
    id_puesto: int
    estado: EstadoSolicitud

class ArtesanoCreate(BaseModel):
   
    foto_perfil: Optional[str] = None
    biografia: Optional[str] = None
    fecha_registro: Optional[date] = None
    anios_experiencia: Optional[int] = None
    telefono: Optional[str] = None
    apellido_materno: Optional[str] = None
    apellido_paterno: Optional[str] = None
    nombre: Optional[str] = None
    id_cueva: int
    id_usuario: int
    id_puesto: int

class ArtesanoUpdate(BaseModel):
    foto_perfil: Optional[str] = None
    biografia: Optional[str] = None
    fecha_registro: Optional[date] = None
    anios_experiencia: Optional[int] = None
    telefono: Optional[str] = None
    apellido_materno: Optional[str] = None
    apellido_paterno: Optional[str] = None
    nombre: Optional[str] = None
    activo: Optional[bool] = None
    id_cueva: Optional[int] = None
    id_usuario: Optional[int] = None
    id_puesto: Optional[int] = None

class ArtesanoResponse(ORMBase):
    id_artesano: int
    foto_perfil: Optional[str] = None
    biografia: Optional[str] = None
    fecha_registro: Optional[date] = None
    anios_experiencia: Optional[int] = None
    telefono: Optional[str] = None
    apellido_materno: Optional[str] = None
    apellido_paterno: Optional[str] = None
    nombre: Optional[str] = None
    activo: bool
    id_cueva: int
    id_usuario: int
    id_puesto: int

class InventarioCreate(BaseModel):
    
    fecha_actualizacion: Optional[datetime] = None
    stock_minimo: Optional[int] = None
    stock_actual: Optional[int] = None
    id_puesto: int
    id_producto: int

class InventarioUpdate(BaseModel):
    fecha_actualizacion: Optional[datetime] = None
    stock_minimo: Optional[int] = None
    stock_actual: Optional[int] = None
    id_puesto: Optional[int] = None
    id_producto: Optional[int] = None

class InventarioResponse(ORMBase):
    id_inventario: int
    fecha_actualizacion: Optional[datetime] = None
    stock_minimo: Optional[int] = None
    stock_actual: Optional[int] = None
    id_puesto: int
    id_producto: int

class EstadoPedidoCreate(BaseModel):
  
    nombre_estado: Optional[str] = None

class EstadoPedidoUpdate(BaseModel):
    nombre_estado: Optional[str] = None

class EstadoPedidoResponse(ORMBase):
    id_estado_pedido: int
    nombre_estado: Optional[str] = None

class ProveedorCreate(BaseModel):
    
    nombre_proveedor: Optional[str] = None
    telefono: Optional[str] = None

class ProveedorUpdate(BaseModel):
    nombre_proveedor: Optional[str] = None
    telefono: Optional[str] = None

class ProveedorResponse(ORMBase):
    id_proveedor: int
    nombre_proveedor: Optional[str] = None
    telefono: Optional[str] = None

class UsuarioCreate(BaseModel):
    tipo_usuario: TipoUsuario
    correo: str
    # La BD ahora pone estos valores por defecto (GETDATE() / 1) si no se envían
    fecha_registro: Optional[datetime] = None
    activo: Optional[bool] = None
    contrasena_hash: str

class UsuarioUpdate(BaseModel):
    tipo_usuario: Optional[TipoUsuario] = None
    correo: Optional[str] = None
    fecha_registro: Optional[datetime] = None
    activo: Optional[bool] = None
    contrasena_hash: Optional[str] = None

class UsuarioResponse(ORMBase):
    id_usuario: int
    tipo_usuario: TipoUsuario
    correo: str
    fecha_registro: datetime
    activo: bool
    contrasena_hash: str

# ---------------------- Pedido mayorista (ruta /clientes/{id}/pedido-mayorista) ----------------------

class ItemPedidoRequest(BaseModel):
    id_producto: int
    cantidad: int
    precio_unitario: Decimal

class PedidoMayoristaRequest(BaseModel):
    id_puesto: int
    id_artesano: int
    id_estado_pedido: int
    observaciones: Optional[str] = None
    items: list[ItemPedidoRequest]