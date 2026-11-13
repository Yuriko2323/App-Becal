"""API principal del Parador Artesanal de Bécal.

Incluye CRUD base, imágenes de productos y rutas adicionales de la Fase 2.
Antes de desplegarla públicamente, agrega autenticación/autorización por roles.
"""

from typing import Any, Optional, Type, Literal
from pathlib import Path
from uuid import uuid4
import unicodedata

import bcrypt
from fastapi import FastAPI, Depends, HTTPException, Query, status, UploadFile, File, Body
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from datetime import date, timedelta
from decimal import Decimal



from .database import engine, get_db
from .models import (
    Base, Vendedor, Producto, FotoProducto, PrecioMayorista, Cliente, Pedido, Puesto, DetallePedido,
    CategoriaEstilo, Calidad, Material, Cueva, Venta, DetalleVenta, AsignacionPuesto, Artesano,
    Inventario, EstadoPedido, Proveedor, Usuario
)
from . import schemas

app = FastAPI(
    title="API Parador Artesanal de Bécal",
    version="1.0.0",
    description="API REST para la aplicación web/móvil del Parador Artesanal de Bécal.",
)

# ---------------------- Almacenamiento de imágenes ----------------------
# SQL Server guarda una ruta corta; el archivo se guarda en el servidor.
UPLOAD_ROOT = Path(__file__).resolve().parent / "uploads"
PRODUCT_IMAGE_DIR = UPLOAD_ROOT / "productos"
PROFILE_IMAGE_DIR = UPLOAD_ROOT / "perfiles"
PRODUCT_IMAGE_DIR.mkdir(parents=True, exist_ok=True)
PROFILE_IMAGE_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_ROOT)), name="uploads")
MAX_IMAGE_BYTES = 5 * 1024 * 1024  # 5 MiB

# Ajusta estos orígenes a tus dominios reales en producción.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://parador-becal-web.onrender.com"
    ],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", tags=["Sistema"])
def root():
    return {"message": "API Parador Artesanal de Bécal funcionando", "docs": "/docs"}

@app.get("/health", tags=["Sistema"])
def health(db: Session = Depends(get_db)):
    try:
        db.execute(select(1))
        return {"status": "ok", "database": "connected"}
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Base de datos no disponible: {exc}")

# ---------------------- Contraseñas ----------------------
# bcrypt trunca a 72 bytes; para correos/contraseñas normales no afecta.

def _hash_password(contrasena: str) -> str:
    return bcrypt.hashpw(contrasena.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def _verify_password(contrasena: str, contrasena_hash: str) -> bool:
    try:
        return bcrypt.checkpw(contrasena.encode("utf-8"), contrasena_hash.encode("utf-8"))
    except ValueError:
        # Hash con formato inválido (p. ej. contraseñas viejas guardadas en
        # texto plano antes de este cambio) -- nunca deja pasar el login.
        return False

# Cada entrada: (ruta, clase ORM, esquema create, update, response, nombre del PK)
RESOURCES = [
    ("vendedores", Vendedor, schemas.VendedorCreate, schemas.VendedorUpdate, schemas.VendedorResponse, "id_vendedor"),
    ("productos", Producto, schemas.ProductoCreate, schemas.ProductoUpdate, schemas.ProductoResponse, "id_producto"),
    ("fotos-producto", FotoProducto, schemas.FotoProductoCreate, schemas.FotoProductoUpdate, schemas.FotoProductoResponse, "id_foto"),
    ("precios-mayorista", PrecioMayorista, schemas.PrecioMayoristaCreate, schemas.PrecioMayoristaUpdate, schemas.PrecioMayoristaResponse, "id_precio_mayorista"),
    ("clientes", Cliente, schemas.ClienteCreate, schemas.ClienteUpdate, schemas.ClienteResponse, "id_cliente"),
    ("pedidos", Pedido, schemas.PedidoCreate, schemas.PedidoUpdate, schemas.PedidoResponse, "id_pedido"),
    ("puestos", Puesto, schemas.PuestoCreate, schemas.PuestoUpdate, schemas.PuestoResponse, "id_puesto"),
    ("detalle-pedidos", DetallePedido, schemas.DetallePedidoCreate, schemas.DetallePedidoUpdate, schemas.DetallePedidoResponse, "id_detalle_pedido"),
    ("categorias-estilo", CategoriaEstilo, schemas.CategoriaEstiloCreate, schemas.CategoriaEstiloUpdate, schemas.CategoriaEstiloResponse, "id_estilo"),
    ("calidades", Calidad, schemas.CalidadCreate, schemas.CalidadUpdate, schemas.CalidadResponse, "id_calidad"),
    ("materiales", Material, schemas.MaterialCreate, schemas.MaterialUpdate, schemas.MaterialResponse, "id_material"),
    ("cuevas", Cueva, schemas.CuevaCreate, schemas.CuevaUpdate, schemas.CuevaResponse, "id_cueva"),
    ("ventas", Venta, schemas.VentaCreate, schemas.VentaUpdate, schemas.VentaResponse, "id_venta"),
    ("detalle-ventas", DetalleVenta, schemas.DetalleVentaCreate, schemas.DetalleVentaUpdate, schemas.DetalleVentaResponse, "id_detalle_venta"),
    ("asignaciones-puesto", AsignacionPuesto, schemas.AsignacionPuestoCreate, schemas.AsignacionPuestoUpdate, schemas.AsignacionPuestoResponse, "id_asignacion"),
    ("artesanos", Artesano, schemas.ArtesanoCreate, schemas.ArtesanoUpdate, schemas.ArtesanoResponse, "id_artesano"),
    ("inventarios", Inventario, schemas.InventarioCreate, schemas.InventarioUpdate, schemas.InventarioResponse, "id_inventario"),
    ("estados-pedido", EstadoPedido, schemas.EstadoPedidoCreate, schemas.EstadoPedidoUpdate, schemas.EstadoPedidoResponse, "id_estado_pedido"),
    ("proveedores", Proveedor, schemas.ProveedorCreate, schemas.ProveedorUpdate, schemas.ProveedorResponse, "id_proveedor"),
    ("usuarios", Usuario, schemas.UsuarioCreate, schemas.UsuarioUpdate, schemas.UsuarioResponse, "id_usuario"),
]


def _get_or_404(db: Session, model: Type[Any], pk_name: str, value: int):
    obj = db.get(model, value)
    if obj is None:
        raise HTTPException(status_code=404, detail=f"{model.__tablename__}: registro no encontrado")
    return obj


def _normalizar_estado_pedido(valor: Optional[str]) -> str:
    """Normaliza el nombre de un estado para comparar sin distinguir acentos o mayúsculas."""
    texto = unicodedata.normalize("NFKD", (valor or "").casefold())
    return "".join(caracter for caracter in texto if not unicodedata.combining(caracter)).strip()


def _commit_or_409(db: Session):
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="No se pudo guardar el registro. Revisa claves foráneas, duplicados o restricciones de la base de datos."
        ) from exc


# ---------------------- Imágenes y estados de productos/cuentas ----------------------
@app.post("/productos/{id_producto}/imagen", tags=["Catalogo"])
async def subir_imagen_producto(
    id_producto: int,
    archivo: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Guarda una imagen localmente y persiste en SQL Server solo la ruta."""
    producto = _get_or_404(db, Producto, "id_producto", id_producto)
    contenido = await archivo.read(MAX_IMAGE_BYTES + 1)
    if not contenido:
        raise HTTPException(status_code=400, detail="El archivo está vacío.")
    if len(contenido) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="La imagen no puede superar 5 MB.")

    # Validar el contenido real, no confiar únicamente en la extensión.
    if contenido.startswith(bytes([0xFF, 0xD8, 0xFF])):
        extension = ".jpg"
    elif contenido.startswith(bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])):
        extension = ".png"
    elif len(contenido) >= 12 and contenido[0:4] == b"RIFF" and contenido[8:12] == b"WEBP":
        extension = ".webp"
    else:
        raise HTTPException(status_code=415, detail="Formato no admitido. Usa JPG, PNG o WEBP.")

    nombre = f"{uuid4().hex}{extension}"
    ruta = PRODUCT_IMAGE_DIR / nombre
    ruta.write_bytes(contenido)
    url = f"/uploads/productos/{nombre}"
    try:
        fotos = db.scalars(
            select(FotoProducto).where(FotoProducto.id_producto == id_producto)
        ).all()
        for foto in fotos:
            foto.es_principal = False
        db.add(FotoProducto(
            id_producto=id_producto,
            url_imagen=url,
            es_principal=True,
            orden=0,
        ))
        producto.imagen_url = url
        _commit_or_409(db)
        db.refresh(producto)
    except Exception:
        try:
            ruta.unlink(missing_ok=True)
        except OSError:
            pass
        raise

    return {"id_producto": id_producto, "imagen_url": url}


@app.patch("/productos/{id_producto}/estado", tags=["Catalogo"])
def cambiar_estado_producto(
    id_producto: int,
    data: dict = Body(...),
    db: Session = Depends(get_db),
):
    """Activa/desactiva un producto sin eliminar el registro ni su historial."""
    activo = data.get("activo") if isinstance(data, dict) else None
    if not isinstance(activo, bool):
        raise HTTPException(status_code=422, detail="El campo 'activo' debe ser true o false.")
    producto = _get_or_404(db, Producto, "id_producto", id_producto)
    producto.activo = activo
    _commit_or_409(db)
    db.refresh(producto)
    return {"id_producto": id_producto, "activo": bool(producto.activo)}


@app.post("/artesanos/{id_artesano}/foto-perfil", tags=["Perfil Artesano"])
async def subir_foto_perfil_artesano(
    id_artesano: int,
    archivo: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Guarda la imagen del perfil como archivo y almacena solo su ruta en SQL Server."""
    artesano = _get_or_404(db, Artesano, "id_artesano", id_artesano)
    contenido = await archivo.read(MAX_IMAGE_BYTES + 1)
    if not contenido:
        raise HTTPException(status_code=400, detail="El archivo está vacío.")
    if len(contenido) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="La imagen no puede superar 5 MB.")

    if contenido.startswith(bytes([0xFF, 0xD8, 0xFF])):
        extension = ".jpg"
    elif contenido.startswith(bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])):
        extension = ".png"
    elif len(contenido) >= 12 and contenido[0:4] == b"RIFF" and contenido[8:12] == b"WEBP":
        extension = ".webp"
    else:
        raise HTTPException(status_code=415, detail="Formato no admitido. Usa JPG, PNG o WEBP.")

    nombre = f"{uuid4().hex}{extension}"
    ruta = PROFILE_IMAGE_DIR / nombre
    ruta.write_bytes(contenido)
    url = f"/uploads/perfiles/{nombre}"
    try:
        artesano.foto_perfil = url
        _commit_or_409(db)
        db.refresh(artesano)
    except Exception:
        try:
            ruta.unlink(missing_ok=True)
        except OSError:
            pass
        raise

    return {"id_artesano": artesano.id_artesano, "foto_perfil": artesano.foto_perfil}


@app.patch("/admin/vendedores/{id_vendedor}/estado", tags=["Administracion"])
def cambiar_estado_vendedor(
    id_vendedor: int,
    data: dict = Body(...),
    db: Session = Depends(get_db),
):
    """Activa/desactiva el perfil de vendedor y su Usuario en una transacción."""
    activo = data.get("activo") if isinstance(data, dict) else None
    if not isinstance(activo, bool):
        raise HTTPException(status_code=422, detail="El campo 'activo' debe ser true o false.")
    vendedor = _get_or_404(db, Vendedor, "id_vendedor", id_vendedor)
    usuario = _get_or_404(db, Usuario, "id_usuario", vendedor.id_usuario)
    vendedor.activo = activo
    usuario.activo = activo
    _commit_or_409(db)
    return {"id_vendedor": id_vendedor, "id_usuario": usuario.id_usuario, "activo": activo}


def register_crud(path: str, model: Type[Any], create_schema: Type[Any], update_schema: Type[Any], response_schema: Type[Any], pk_name: str):
    # POST
    def create(item: create_schema, db: Session = Depends(get_db)):
        obj = model(**item.model_dump(exclude_unset=True))
        db.add(obj)
        _commit_or_409(db)
        db.refresh(obj)
        return obj
    create.__name__ = f"crear_{path.replace('-', '_')}"
    app.add_api_route(
        f"/{path}", create, methods=["POST"], response_model=response_schema,
        status_code=status.HTTP_201_CREATED, tags=[path]
    )

    # GET all with pagination
    # SQL Server exige ORDER BY cuando se usa OFFSET/LIMIT (a diferencia de
    # Postgres/MySQL), así que ordenamos siempre por la PK.
    pk_column = getattr(model, pk_name)

    def list_all(
        skip: int = Query(0, ge=0),
        limit: int = Query(50, ge=1, le=200),
        db: Session = Depends(get_db),
    ):
        return db.scalars(
            select(model).order_by(pk_column).offset(skip).limit(limit)
        ).all()
    list_all.__name__ = f"listar_{path.replace('-', '_')}"
    app.add_api_route(
        f"/{path}", list_all, methods=["GET"], response_model=list[response_schema], tags=[path]
    )

    # GET one
    def get_one(item_id: int, db: Session = Depends(get_db)):
        return _get_or_404(db, model, pk_name, item_id)
    get_one.__name__ = f"obtener_{path.replace('-', '_')}"
    app.add_api_route(
        f"/{path}/{{item_id}}", get_one, methods=["GET"], response_model=response_schema, tags=[path]
    )

    # PUT = reemplazo completo de los campos editables
    def update(item_id: int, item: update_schema, db: Session = Depends(get_db)):
        obj = _get_or_404(db, model, pk_name, item_id)
        for key, value in item.model_dump(exclude_unset=True).items():
            if key != pk_name:
                setattr(obj, key, value)
        _commit_or_409(db)
        db.refresh(obj)
        return obj
    update.__name__ = f"actualizar_{path.replace('-', '_')}"
    app.add_api_route(
        f"/{path}/{{item_id}}", update, methods=["PUT"], response_model=response_schema, tags=[path]
    )

    # PATCH = actualización parcial
    def patch(item_id: int, item: update_schema, db: Session = Depends(get_db)):
        obj = _get_or_404(db, model, pk_name, item_id)
        for key, value in item.model_dump(exclude_unset=True).items():
            if key != pk_name:
                setattr(obj, key, value)
        _commit_or_409(db)
        db.refresh(obj)
        return obj
    patch.__name__ = f"parchar_{path.replace('-', '_')}"
    app.add_api_route(
        f"/{path}/{{item_id}}", patch, methods=["PATCH"], response_model=response_schema, tags=[path]
    )

    # DELETE
    # Si el modelo tiene columna 'activo' (Usuario, Vendedor, Cliente,
    # Producto, Artesano), se hace soft delete en vez de borrar la fila,
    # para no perder el historial de ventas/pedidos que la referencian.
    def delete(item_id: int, db: Session = Depends(get_db)):
        obj = _get_or_404(db, model, pk_name, item_id)
        if hasattr(obj, "activo"):
            obj.activo = False
        else:
            db.delete(obj)
        _commit_or_409(db)
        return None
    delete.__name__ = f"eliminar_{path.replace('-', '_')}"
    app.add_api_route(
        f"/{path}/{{item_id}}", delete, methods=["DELETE"], status_code=status.HTTP_204_NO_CONTENT, tags=[path]
    )


for resource in RESOURCES:
    register_crud(*resource)


# ---------------------- Fase 2: perfiles y fichas de administración ----------------------
# Estas rutas no devuelven hashes de contraseñas. NOTA: todavía requieren autenticación
# por rol (JWT/sesión) antes de exponerse en producción.

def _fase2_payload_artesano(db: Session, artesano: Artesano, usuario: Usuario):
    cueva = db.get(Cueva, artesano.id_cueva) if artesano.id_cueva is not None else None
    puesto = db.get(Puesto, artesano.id_puesto) if artesano.id_puesto is not None else None
    return {
        "id_artesano": artesano.id_artesano,
        "id_usuario": artesano.id_usuario,
        "nombre": artesano.nombre,
        "apellido_paterno": artesano.apellido_paterno,
        "apellido_materno": artesano.apellido_materno,
        "telefono": artesano.telefono,
        "biografia": artesano.biografia,
        "anios_experiencia": artesano.anios_experiencia,
        "fecha_registro": artesano.fecha_registro,
        "foto_perfil": artesano.foto_perfil,
        "foto_perfil_registrada": bool(artesano.foto_perfil),
        "id_cueva": artesano.id_cueva,
        "cueva": cueva.nombre_cueva if cueva else None,
        "direccion_cueva": cueva.direccion_ubicacion if cueva else None,
        "id_puesto": artesano.id_puesto,
        "puesto": puesto.nombre_puesto if puesto else (f"Puesto #{artesano.id_puesto}" if artesano.id_puesto else None),
        "numero_puesto": puesto.numero_puesto if puesto else None,
        "correo": usuario.correo,
        "activo": bool(artesano.activo),
        "usuario_activo": bool(usuario.activo),
    }


def _fase2_payload_vendedor(
    db: Session,
    vendedor: Vendedor,
    usuario: Usuario,
    incluir_asignaciones: bool = False,
):
    data = {
        "id_vendedor": vendedor.id_vendedor,
        "id_usuario": vendedor.id_usuario,
        "nombre": vendedor.nombre,
        "apellido_paterno": vendedor.apellido_paterno,
        "apellido_materno": vendedor.apellido_materno,
        "telefono": vendedor.telefono,
        "rol": vendedor.rol,
        "correo": usuario.correo,
        "activo": bool(vendedor.activo and usuario.activo),
        "vendedor_activo": bool(vendedor.activo),
        "usuario_activo": bool(usuario.activo),
    }
    if incluir_asignaciones:
        rows = db.execute(
            select(AsignacionPuesto, Puesto)
            .join(Puesto, AsignacionPuesto.id_puesto == Puesto.id_puesto)
            .where(AsignacionPuesto.id_vendedor == vendedor.id_vendedor)
            .order_by(AsignacionPuesto.id_asignacion.desc())
        ).all()
        data["asignaciones"] = [
            {
                "id_asignacion": asignacion.id_asignacion,
                "id_puesto": asignacion.id_puesto,
                "nombre_puesto": puesto.nombre_puesto,
                "numero_puesto": puesto.numero_puesto,
                "turno": asignacion.turno,
                "fecha_inicio": asignacion.fecha_inicio,
                "fecha_fin": asignacion.fecha_fin,
                "estado": asignacion.estado,
            }
            for asignacion, puesto in rows
        ]
    return data


@app.get("/admin/artesanos", tags=["Administracion"])
def fase2_listar_artesanos_admin(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        select(Artesano, Usuario)
        .join(Usuario, Artesano.id_usuario == Usuario.id_usuario)
        .order_by(Artesano.id_artesano)
        .offset(skip)
        .limit(limit)
    ).all()
    return [_fase2_payload_artesano(db, artesano, usuario) for artesano, usuario in rows]


@app.get("/admin/artesanos/{id_artesano}", tags=["Administracion"])
def fase2_detalle_artesano_admin(id_artesano: int, db: Session = Depends(get_db)):
    artesano = _get_or_404(db, Artesano, "id_artesano", id_artesano)
    usuario = _get_or_404(db, Usuario, "id_usuario", artesano.id_usuario)
    return _fase2_payload_artesano(db, artesano, usuario)


@app.get("/admin/vendedores", tags=["Administracion"])
def fase2_listar_vendedores_admin(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        select(Vendedor, Usuario)
        .join(Usuario, Vendedor.id_usuario == Usuario.id_usuario)
        .order_by(Vendedor.id_vendedor)
        .offset(skip)
        .limit(limit)
    ).all()
    return [_fase2_payload_vendedor(db, vendedor, usuario) for vendedor, usuario in rows]


@app.get("/admin/vendedores/{id_vendedor}", tags=["Administracion"])
def fase2_detalle_vendedor_admin(id_vendedor: int, db: Session = Depends(get_db)):
    vendedor = _get_or_404(db, Vendedor, "id_vendedor", id_vendedor)
    usuario = _get_or_404(db, Usuario, "id_usuario", vendedor.id_usuario)
    return _fase2_payload_vendedor(db, vendedor, usuario, incluir_asignaciones=True)


@app.get("/artesanos/{id_artesano}/perfil", tags=["Perfil Artesano"])
def fase2_obtener_perfil_artesano(id_artesano: int, db: Session = Depends(get_db)):
    artesano = _get_or_404(db, Artesano, "id_artesano", id_artesano)
    usuario = _get_or_404(db, Usuario, "id_usuario", artesano.id_usuario)
    return _fase2_payload_artesano(db, artesano, usuario)


@app.patch("/artesanos/{id_artesano}/perfil", tags=["Perfil Artesano"])
def fase2_actualizar_perfil_artesano(
    id_artesano: int,
    payload: dict = Body(...),
    db: Session = Depends(get_db),
):
    artesano = _get_or_404(db, Artesano, "id_artesano", id_artesano)
    usuario = _get_or_404(db, Usuario, "id_usuario", artesano.id_usuario)

    permitidos = {
        "nombre", "apellido_paterno", "apellido_materno", "telefono",
        "biografia", "anios_experiencia", "correo",
    }
    desconocidos = set(payload.keys()) - permitidos
    if desconocidos:
        raise HTTPException(
            status_code=422,
            detail="No se permiten modificar estos campos desde el perfil: " + ", ".join(sorted(desconocidos)),
        )

    for key, max_len in (
        ("nombre", 50), ("apellido_paterno", 50), ("apellido_materno", 50),
        ("telefono", 15), ("biografia", 250),
    ):
        if key not in payload:
            continue
        value = payload[key]
        if value is not None and not isinstance(value, str):
            raise HTTPException(status_code=422, detail=f"El campo '{key}' debe ser texto o null.")
        if value is not None:
            value = value.strip()
            if key == "nombre" and not value:
                raise HTTPException(status_code=422, detail="El nombre no puede quedar vacío.")
            if len(value) > max_len:
                raise HTTPException(status_code=422, detail=f"El campo '{key}' supera el máximo de {max_len} caracteres.")
        setattr(artesano, key, value if value else (None if key != "nombre" else value))

    if "anios_experiencia" in payload:
        experiencia = payload["anios_experiencia"]
        if isinstance(experiencia, bool):
            raise HTTPException(status_code=422, detail="Años de experiencia debe ser un entero mayor o igual que cero.")
        try:
            experiencia = int(experiencia)
        except (TypeError, ValueError):
            raise HTTPException(status_code=422, detail="Años de experiencia debe ser un entero mayor o igual que cero.")
        if experiencia < 0:
            raise HTTPException(status_code=422, detail="Años de experiencia debe ser un entero mayor o igual que cero.")
        artesano.anios_experiencia = experiencia

    if "correo" in payload:
        correo = payload["correo"]
        if not isinstance(correo, str) or not correo.strip() or "@" not in correo:
            raise HTTPException(status_code=422, detail="Ingresa un correo electrónico válido.")
        correo = correo.strip().lower()
        existente = db.scalar(
            select(Usuario).where(
                Usuario.correo == correo,
                Usuario.id_usuario != usuario.id_usuario,
            )
        )
        if existente:
            raise HTTPException(status_code=409, detail="Ese correo ya está registrado en otra cuenta.")
        usuario.correo = correo

    _commit_or_409(db)
    db.refresh(artesano)
    db.refresh(usuario)
    return _fase2_payload_artesano(db, artesano, usuario)


# ---------------------- Consultas útiles para la aplicación ----------------------

@app.get("/catalogo/productos", response_model=list[schemas.ProductoResponse], tags=["Catalogo"])
def catalogo_productos(
    nombre: Optional[str] = Query(None),
    id_artesano: Optional[int] = Query(None, ge=1),
    id_estilo: Optional[int] = Query(None, ge=1),
    id_calidad: Optional[int] = Query(None, ge=1),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    # Filtramos por defecto solo los productos activos (Soft Delete = False no se muestran)
    stmt = select(Producto).where(Producto.activo == True)
    
    if nombre:
        stmt = stmt.where(Producto.nombre.ilike(f"%{nombre}%"))
    if id_artesano is not None:
        stmt = stmt.where(Producto.id_artesano == id_artesano)
    if id_estilo is not None:
        stmt = stmt.where(Producto.id_estilo == id_estilo)
    if id_calidad is not None:
        stmt = stmt.where(Producto.id_calidad == id_calidad)
        
    stmt = stmt.order_by(Producto.id_producto)
    return db.scalars(stmt.offset(skip).limit(limit)).all()

@app.get("/artesanos/{id_artesano}/productos", response_model=list[schemas.ProductoResponse], tags=["Catalogo"])
def productos_de_artesano(
    id_artesano: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    _get_or_404(db, Artesano, "id_artesano", id_artesano)
    stmt = select(Producto).where(Producto.id_artesano == id_artesano).order_by(Producto.id_producto).offset(skip).limit(limit)
    return db.scalars(stmt).all()

@app.get("/productos/{id_producto}/inventario", response_model=list[schemas.InventarioResponse], tags=["Catalogo"])
def inventario_de_producto(
    id_producto: int,
    db: Session = Depends(get_db),
):
    _get_or_404(db, Producto, "id_producto", id_producto)
    return db.scalars(select(Inventario).where(Inventario.id_producto == id_producto)).all()

@app.get("/productos/{id_producto}/fotos", response_model=list[schemas.FotoProductoResponse], tags=["Catalogo"])
def fotos_de_producto(
    id_producto: int,
    db: Session = Depends(get_db),
):
    """Galería completa de un producto, la foto con es_principal=True primero."""
    _get_or_404(db, Producto, "id_producto", id_producto)
    stmt = (
        select(FotoProducto)
        .where(FotoProducto.id_producto == id_producto)
        .order_by(FotoProducto.es_principal.desc(), FotoProducto.orden)
    )
    return db.scalars(stmt).all()

@app.get("/productos/{id_producto}/precios-mayorista", response_model=list[schemas.PrecioMayoristaResponse], tags=["Catalogo"])
def precios_mayorista_de_producto(
    id_producto: int,
    db: Session = Depends(get_db),
):
    """Escalones de precio por cantidad para un producto, de menor a mayor cantidad."""
    _get_or_404(db, Producto, "id_producto", id_producto)
    stmt = (
        select(PrecioMayorista)
        .where(PrecioMayorista.id_producto == id_producto)
        .order_by(PrecioMayorista.cantidad_minima)
    )
    return db.scalars(stmt).all()

#no confirmado 
@app.get("/artesanos/{id_artesano}/dashboard", tags=["Ruta Artesano"])
def dashboard_artesano(id_artesano: int, db: Session = Depends(get_db)):
    """Panel principal que muestra el resumen de negocio del artesano."""
    _get_or_404(db, Artesano, "id_artesano", id_artesano)

    # 1. Total de productos activos en el catálogo
    total_productos = db.scalar(
        select(func.count(Producto.id_producto))
        .where(Producto.id_artesano == id_artesano, Producto.activo == True)
    )

    # 2. Total de pedidos recibidos
    total_pedidos = db.scalar(
        select(func.count(Pedido.id_pedido))
        .where(Pedido.id_artesano == id_artesano)
    )

    # 3. Ingresos generados (Multiplicando cantidad por precio_acordado de sus pedidos)
    ingresos = db.scalar(
        select(func.sum(DetallePedido.cantidad * DetallePedido.precio_acordado))
        .join(Pedido, Pedido.id_pedido == DetallePedido.id_pedido)
        .where(Pedido.id_artesano == id_artesano)
    )

    return {
        "id_artesano": id_artesano,
        "total_productos_activos": total_productos or 0,
        "total_pedidos_recibidos": total_pedidos or 0,
        "ingresos_estimados": float(ingresos or 0.0)
    }

@app.get("/artesanos/{id_artesano}/mis-pedidos", response_model=list[schemas.PedidoResponse], tags=["Ruta Artesano"])
def pedidos_de_artesano(
    id_artesano: int, 
    skip: int = Query(0, ge=0), 
    limit: int = Query(50, ge=1, le=200), 
    db: Session = Depends(get_db)
):
    """Lista todos los pedidos dirigidos a un artesano específico (ordenados por el más reciente)."""
    stmt = (
        select(Pedido)
        .where(Pedido.id_artesano == id_artesano)
        .order_by(Pedido.id_pedido.desc()) # Orden inverso para ver primero lo más nuevo
        .offset(skip).limit(limit)
    )
    return db.scalars(stmt).all()

# ---------------------- Vendedores y asignaciones de puesto ----------------------
# Pantallas: "Vendedores activos en mi puesto" y "Solicitudes de empleo
# recibidas" del flujo de la app. Aceptar/rechazar se hace con el PATCH
# genérico que ya existe: PATCH /asignaciones-puesto/{id} {"estado": "..."}.

@app.get("/artesanos/{id_artesano}/solicitudes-pendientes", response_model=list[schemas.AsignacionPuestoResponse], tags=["Ruta Artesano"])
def solicitudes_pendientes_de_artesano(id_artesano: int, db: Session = Depends(get_db)):
    artesano = _get_or_404(db, Artesano, "id_artesano", id_artesano)
    stmt = (
        select(AsignacionPuesto)
        .where(AsignacionPuesto.id_puesto == artesano.id_puesto, AsignacionPuesto.estado == "Pendiente")
        .order_by(AsignacionPuesto.id_asignacion)
    )
    return db.scalars(stmt).all()

@app.get("/puestos/{id_puesto}/vendedores-activos", response_model=list[schemas.AsignacionPuestoResponse], tags=["Catalogo"])
def vendedores_activos_de_puesto(id_puesto: int, db: Session = Depends(get_db)):
    _get_or_404(db, Puesto, "id_puesto", id_puesto)
    stmt = (
        select(AsignacionPuesto)
        .where(AsignacionPuesto.id_puesto == id_puesto, AsignacionPuesto.estado == "Aceptado")
        .order_by(AsignacionPuesto.id_asignacion)
    )
    return db.scalars(stmt).all()


# ==========================================
# RUTAS ESPECÍFICAS: LA RUTA DEL MAYORISTA
# ==========================================

@app.post("/clientes/{id_cliente}/pedido-mayorista", tags=["Ruta Mayorista"])
def crear_pedido_mayorista(id_cliente: int, orden: schemas.PedidoMayoristaRequest, db: Session = Depends(get_db)):
    """
    Procesa un carrito de compras. Si el cliente es 'Mayorista' y 
    lleva volumen suficiente, aplica 10% de descuento.
    """
    cliente = _get_or_404(db, Cliente, "id_cliente", id_cliente)

    # 1. Validar el rol desde la base de datos para seguridad
    if cliente.tipo_cliente != 'Mayorista':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="El cliente no tiene los privilegios de la ruta Mayorista."
        )

    # 2. Lógica del candado de mayoreo (Ejemplo: mínimo 12 artículos para activar el 10%)
    total_articulos = sum(item.cantidad for item in orden.items)
    es_mayoreo = total_articulos >= 12 

    # 3. Crear el registro maestro del Pedido
    nuevo_pedido = Pedido(
        id_cliente=id_cliente,
        id_puesto=orden.id_puesto,
        id_artesano=orden.id_artesano,
        id_estado_pedido=orden.id_estado_pedido,
        observaciones=orden.observaciones,
        fecha_solicitud=func.now() 
    )
    db.add(nuevo_pedido)
    db.commit()
    db.refresh(nuevo_pedido)

    # 4. Procesar el detalle y calcular el total aplicando la regla de descuento
    total_a_pagar = Decimal('0.0')
    
    for item in orden.items:
        precio_final = Decimal(str(item.precio_unitario))
        
        # Aplicamos el 10% directo al servidor, evitando que el front-end mande datos alterados
        if es_mayoreo:
            precio_final = precio_final * Decimal('0.90')

        detalle = DetallePedido(
            id_pedido=nuevo_pedido.id_pedido,
            id_producto=item.id_producto,
            cantidad=item.cantidad,
            precio_acordado=precio_final
        )
        db.add(detalle)
        total_a_pagar += (precio_final * item.cantidad)

    db.commit()

    return {
        "mensaje": "Pedido mayorista procesado exitosamente",
        "id_pedido": nuevo_pedido.id_pedido,
        "descuento_10_aplicado": es_mayoreo,
        "piezas_totales": total_articulos,
        "total_a_pagar": float(total_a_pagar)
    }


from pydantic import BaseModel

# ---------------------- Autenticación y registro ----------------------
class LoginRequest(BaseModel):
    correo: str
    contrasena: str

class RegistroClienteRequest(BaseModel):
    nombre: str
    correo: str
    contrasena: str
    tipo_cliente: Literal['Local', 'Mayorista', 'Turista'] = 'Local'
    telefono: Optional[str] = None
    nacionalidad: Optional[str] = None
    idioma_preferido: Optional[str] = None
    apellido_p: Optional[str] = None
    apellido_m: Optional[str] = None

class RegistroArtesanoRequest(BaseModel):
    nombre: str
    apellido_paterno: Optional[str] = None
    apellido_materno: Optional[str] = None
    correo: str
    contrasena: str
    telefono: Optional[str] = None
    biografia: Optional[str] = None
    anios_experiencia: Optional[int] = None
    id_cueva: int
    id_puesto: int
    foto_perfil: Optional[str] = None

# NOTA: la cuenta de Vendedor la crea el Admin (panel "Gestionar cuentas de
# vendedor" del flujo de la app), no el propio trabajador desde una pantalla
# pública. OJO: esta ruta todavía NO valida que quien la llama sea un Admin
# -- hoy la API no tiene sesiones/tokens, así que cualquiera puede llamarla
# igual que a /registro/cliente y /registro/artesano. Hace falta un sistema
# de autenticación (JWT u otro) antes de exponer esto de verdad.
class RegistroVendedorRequest(BaseModel):
    nombre: str
    apellido_paterno: Optional[str] = None
    apellido_materno: Optional[str] = None
    correo: str
    contrasena: str
    telefono: Optional[str] = None
    rol: Optional[Literal['Cajero', 'Gerente', 'Mostrador']] = None

class CrearPedidoRequest(BaseModel):
    id_producto: int
    cantidad: int = 1
    id_estado_pedido: int
    metodo_pago: Literal['Efectivo', 'Tarjeta', 'Transferencia'] = 'Efectivo'
    observaciones: Optional[str] = None

@app.post('/registro/cliente', tags=['Autenticación'], status_code=status.HTTP_201_CREATED)
def registro_cliente(data: RegistroClienteRequest, db: Session = Depends(get_db)):
    existente = db.scalar(select(Usuario).where(Usuario.correo == data.correo))
    if existente:
        raise HTTPException(status_code=409, detail='Ya existe una cuenta con ese correo.')
    try:
        usuario = Usuario(
            tipo_usuario='Cliente',
            correo=data.correo,
            contrasena_hash=_hash_password(data.contrasena),
            activo=True,
        )
        db.add(usuario)
        db.flush()

        cliente = Cliente(
            idioma_preferido=data.idioma_preferido,
            nacionalidad=data.nacionalidad,
            tipo_cliente=data.tipo_cliente,
            telefono=data.telefono,
            nombre=data.nombre,
            apellido_m=data.apellido_m,
            apellido_p=data.apellido_p,
            id_usuario=usuario.id_usuario,
            activo=True,
        )
        db.add(cliente)
        db.commit()
        db.refresh(usuario)
        db.refresh(cliente)
        return {
            'id_usuario': usuario.id_usuario,
            'id_cliente': cliente.id_cliente,
            'tipo_usuario': usuario.tipo_usuario,
            'correo': usuario.correo,
        }
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail='No se pudo crear la cuenta de cliente.') from exc

@app.post('/registro/artesano', tags=['Autenticación'], status_code=status.HTTP_201_CREATED)
def registro_artesano(data: RegistroArtesanoRequest, db: Session = Depends(get_db)):
    existente = db.scalar(select(Usuario).where(Usuario.correo == data.correo))
    if existente:
        raise HTTPException(status_code=409, detail='Ya existe una cuenta con ese correo.')

    _get_or_404(db, Cueva, 'id_cueva', data.id_cueva)
    _get_or_404(db, Puesto, 'id_puesto', data.id_puesto)

    try:
        usuario = Usuario(
            tipo_usuario='Artesano',
            correo=data.correo,
            contrasena_hash=_hash_password(data.contrasena),
            activo=True,
        )
        db.add(usuario)
        db.flush()

        artesano = Artesano(
            foto_perfil=data.foto_perfil,
            biografia=data.biografia,
            fecha_registro=date.today(),
            anios_experiencia=data.anios_experiencia,
            telefono=data.telefono,
            apellido_materno=data.apellido_materno,
            apellido_paterno=data.apellido_paterno,
            nombre=data.nombre,
            activo=True,
            id_cueva=data.id_cueva,
            id_usuario=usuario.id_usuario,
            id_puesto=data.id_puesto,
        )
        db.add(artesano)
        db.commit()
        db.refresh(usuario)
        db.refresh(artesano)
        return {
            'id_usuario': usuario.id_usuario,
            'id_artesano': artesano.id_artesano,
            'tipo_usuario': usuario.tipo_usuario,
            'correo': usuario.correo,
        }
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail='No se pudo crear la cuenta de artesano. Revisa las relaciones seleccionadas.') from exc

@app.post('/registro/vendedor', tags=['Autenticación'], status_code=status.HTTP_201_CREATED)
def registro_vendedor(data: RegistroVendedorRequest, db: Session = Depends(get_db)):
    """Pensado para llamarse desde el panel de Admin, no desde una
    pantalla pública de registro. Ver nota de seguridad junto a
    RegistroVendedorRequest."""
    existente = db.scalar(select(Usuario).where(Usuario.correo == data.correo))
    if existente:
        raise HTTPException(status_code=409, detail='Ya existe una cuenta con ese correo.')
    try:
        usuario = Usuario(
            tipo_usuario='Vendedor',
            correo=data.correo,
            contrasena_hash=_hash_password(data.contrasena),
            activo=True,
        )
        db.add(usuario)
        db.flush()

        vendedor = Vendedor(
            telefono=data.telefono,
            nombre=data.nombre,
            rol=data.rol,
            apellido_materno=data.apellido_materno,
            apellido_paterno=data.apellido_paterno,
            id_usuario=usuario.id_usuario,
            activo=True,
        )
        db.add(vendedor)
        db.commit()
        db.refresh(usuario)
        db.refresh(vendedor)
        return {
            'id_usuario': usuario.id_usuario,
            'id_vendedor': vendedor.id_vendedor,
            'tipo_usuario': usuario.tipo_usuario,
            'correo': usuario.correo,
        }
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail='No se pudo crear la cuenta de vendedor.') from exc

@app.post('/login', tags=['Autenticación'])
def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    usuario = db.scalar(select(Usuario).where(Usuario.correo == credentials.correo))

    if not usuario or not usuario.activo or not _verify_password(credentials.contrasena, usuario.contrasena_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Correo o contraseña incorrectos')

    cliente = db.scalar(select(Cliente).where(Cliente.id_usuario == usuario.id_usuario))
    artesano = db.scalar(select(Artesano).where(Artesano.id_usuario == usuario.id_usuario))
    vendedor = db.scalar(select(Vendedor).where(Vendedor.id_usuario == usuario.id_usuario))
    # Admin no tiene tabla de perfil propia todavía: solo existe la fila en
    
    if usuario.tipo_usuario == 'Admin':
        nombre_usuario = 'Administrador General'
    else:
        nombre_usuario = (artesano.nombre if artesano else cliente.nombre if cliente else vendedor.nombre if vendedor else 'Usuario')
    # Usuario, así que no hay nombre que mostrar más allá del correo.

    return {
        'id_usuario': usuario.id_usuario,
        'id_cliente': cliente.id_cliente if cliente else None,
        'id_artesano': artesano.id_artesano if artesano else None,
        'id_vendedor': vendedor.id_vendedor if vendedor else None,
        'tipo_usuario': usuario.tipo_usuario,
        'correo': usuario.correo,
        'nombre': nombre_usuario,
    }

# ---------------------- Pedidos de la aplicación ----------------------
@app.post('/clientes/{id_cliente}/crear-pedido', tags=['Pedidos App'], status_code=status.HTTP_201_CREATED)
def crear_pedido_app(id_cliente: int, data: CrearPedidoRequest, db: Session = Depends(get_db)):
    cliente = _get_or_404(db, Cliente, 'id_cliente', id_cliente)
    producto = _get_or_404(db, Producto, 'id_producto', data.id_producto)
    artesano = _get_or_404(db, Artesano, 'id_artesano', producto.id_artesano)
    estado_inicial = _get_or_404(db, EstadoPedido, 'id_estado_pedido', data.id_estado_pedido)
    if 'pendiente' not in _normalizar_estado_pedido(estado_inicial.nombre_estado):
        raise HTTPException(
            status_code=409,
            detail='El pedido debe iniciar con estado Pendiente. Revisa el catálogo Estado_Pedido y selecciona ese estado.',
        )
    _get_or_404(db, Puesto, 'id_puesto', artesano.id_puesto)

    if not producto.activo:
        raise HTTPException(status_code=409, detail='El producto no está disponible.')
    if data.cantidad < 1:
        raise HTTPException(status_code=422, detail='La cantidad debe ser mayor que cero.')
    if producto.precio_base is None:
        raise HTTPException(status_code=409, detail='El producto no tiene precio configurado.')

    precio = Decimal(str(producto.precio_base))
    total = precio * data.cantidad

    # Para la demo evitamos registros con información visualmente vacía.
    # La fecha de entrega se estima usando los días configurados para la calidad.
    calidad = db.get(Calidad, producto.id_calidad)
    dias_elaboracion = (calidad.dias_elaboracion_estimados if calidad else None) or 7
    fecha_solicitud = date.today()
    fecha_entrega = fecha_solicitud + timedelta(days=max(1, int(dias_elaboracion)))
    anticipo = Decimal('0.00')
    pago_texto = f'Método de pago: {data.metodo_pago}'
    observaciones = pago_texto
    if data.observaciones and data.observaciones.strip():
        observaciones += f'. {data.observaciones.strip()}'

    try:
        pedido = Pedido(
            fecha_solicitud=fecha_solicitud,
            fecha_entrega_estimada=fecha_entrega,
            anticipo=anticipo,
            observaciones=observaciones,
            id_cliente=cliente.id_cliente,
            id_puesto=artesano.id_puesto,
            id_artesano=artesano.id_artesano,
            id_estado_pedido=estado_inicial.id_estado_pedido,
        )
        db.add(pedido)
        db.flush()

        detalle = DetallePedido(
            cantidad=data.cantidad,
            precio_acordado=precio,
            id_producto=producto.id_producto,
            id_pedido=pedido.id_pedido,
        )
        db.add(detalle)
        db.commit()
        db.refresh(pedido)
        return {
            'mensaje': 'Pedido registrado correctamente',
            'id_pedido': pedido.id_pedido,
            'id_cliente': cliente.id_cliente,
            'id_artesano': artesano.id_artesano,
            'id_producto': producto.id_producto,
            'cantidad': data.cantidad,
            'precio_unitario': float(precio),
            'total': float(total),
            'metodo_pago': data.metodo_pago,
            'id_estado_pedido': data.id_estado_pedido,
            'fecha_solicitud': pedido.fecha_solicitud.isoformat(),
            'fecha_entrega_estimada': pedido.fecha_entrega_estimada.isoformat(),
            'anticipo': float(pedido.anticipo or 0),
            'observaciones': pedido.observaciones,
        }
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail='No se pudo registrar el pedido.') from exc

def _resumen_pedido(db: Session, pedido: Pedido):
    detalles = db.scalars(
        select(DetallePedido).where(DetallePedido.id_pedido == pedido.id_pedido)
    ).all()
    estado = db.get(EstadoPedido, pedido.id_estado_pedido)
    cliente = db.get(Cliente, pedido.id_cliente)
    artesano = db.get(Artesano, pedido.id_artesano)
    items = []
    total = Decimal('0')
    for detalle in detalles:
        producto = db.get(Producto, detalle.id_producto)
        precio = Decimal(str(detalle.precio_acordado or 0))
        cantidad = detalle.cantidad or 0
        total += precio * cantidad
        items.append({
            'id_producto': detalle.id_producto,
            'producto': producto.nombre if producto else None,
            'cantidad': cantidad,
            'precio_unitario': float(precio),
            'subtotal': float(precio * cantidad),
        })
    return {
        'id_pedido': pedido.id_pedido,
        'fecha_solicitud': pedido.fecha_solicitud.isoformat() if pedido.fecha_solicitud else None,
        'fecha_entrega_estimada': pedido.fecha_entrega_estimada.isoformat() if pedido.fecha_entrega_estimada else None,
        'anticipo': float(pedido.anticipo or 0),
        'observaciones': pedido.observaciones,
        'id_cliente': pedido.id_cliente,
        'cliente': f'{cliente.nombre or ""} {cliente.apellido_p or ""}'.strip() if cliente else None,
        'id_artesano': pedido.id_artesano,
        'artesano': f'{artesano.nombre or ""} {artesano.apellido_paterno or ""}'.strip() if artesano else None,
        'estado': estado.nombre_estado if estado else None,
        'id_estado_pedido': pedido.id_estado_pedido,
        'items': items,
        'total': float(total),
    }

@app.get('/clientes/{id_cliente}/pedidos-detallados', tags=['Pedidos App'])
def pedidos_cliente_detallados(id_cliente: int, skip: int = Query(0, ge=0), limit: int = Query(50, ge=1, le=200), db: Session = Depends(get_db)):
    _get_or_404(db, Cliente, 'id_cliente', id_cliente)
    pedidos = db.scalars(
        select(Pedido)
        .where(Pedido.id_cliente == id_cliente)
        .order_by(Pedido.id_pedido.desc())
        .offset(skip).limit(limit)
    ).all()
    return [_resumen_pedido(db, pedido) for pedido in pedidos]

@app.get('/artesanos/{id_artesano}/pedidos-detallados', tags=['Ruta Artesano'])
def pedidos_artesano_detallados(id_artesano: int, skip: int = Query(0, ge=0), limit: int = Query(50, ge=1, le=200), db: Session = Depends(get_db)):
    _get_or_404(db, Artesano, 'id_artesano', id_artesano)
    pedidos = db.scalars(
        select(Pedido)
        .where(Pedido.id_artesano == id_artesano)
        .order_by(Pedido.id_pedido.desc())
        .offset(skip).limit(limit)
    ).all()
    return [_resumen_pedido(db, pedido) for pedido in pedidos]


def _detalle_pedido_completo(db: Session, pedido: Pedido):
    resumen = _resumen_pedido(db, pedido)
    cliente = db.get(Cliente, pedido.id_cliente)
    artesano = db.get(Artesano, pedido.id_artesano)
    usuario_cliente = db.get(Usuario, cliente.id_usuario) if cliente else None
    puesto = db.get(Puesto, pedido.id_puesto)
    resumen['cliente_telefono'] = cliente.telefono if cliente else None
    resumen['cliente_correo'] = usuario_cliente.correo if usuario_cliente else None
    resumen['artesano_telefono'] = artesano.telefono if artesano else None
    resumen['puesto'] = puesto.nombre_puesto if puesto else None
    resumen['puesto_numero'] = puesto.numero_puesto if puesto else None
    return resumen

@app.get('/clientes/{id_cliente}/pedidos-detallados/{id_pedido}', tags=['Pedidos App'])
def detalle_pedido_cliente(id_cliente: int, id_pedido: int, db: Session = Depends(get_db)):
    pedido = db.get(Pedido, id_pedido)
    if pedido is None or pedido.id_cliente != id_cliente:
        raise HTTPException(status_code=404, detail='Pedido no encontrado para este cliente.')
    return _detalle_pedido_completo(db, pedido)

@app.get('/artesanos/{id_artesano}/pedidos-detallados/{id_pedido}', tags=['Ruta Artesano'])
def detalle_pedido_artesano(id_artesano: int, id_pedido: int, db: Session = Depends(get_db)):
    pedido = db.get(Pedido, id_pedido)
    if pedido is None or pedido.id_artesano != id_artesano:
        raise HTTPException(status_code=404, detail='Pedido no encontrado para este artesano.')
    return _detalle_pedido_completo(db, pedido)


# ---------------------- Fase 3: pedidos visibles para administración y cancelación ----------------------
@app.get("/admin/pedidos-detallados", tags=["Administracion", "Pedidos App"])
def admin_pedidos_detallados(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    """Lista pedidos de clientes; los pedidos no se confunden con ventas de caja."""
    pedidos = db.scalars(
        select(Pedido)
        .order_by(Pedido.id_pedido.desc())
        .offset(skip)
        .limit(limit)
    ).all()
    return [_detalle_pedido_completo(db, pedido) for pedido in pedidos]


@app.patch("/clientes/{id_cliente}/pedidos/{id_pedido}/cancelar", tags=["Pedidos App"])
def cancelar_pedido_cliente(
    id_cliente: int,
    id_pedido: int,
    db: Session = Depends(get_db),
):
    """Cancela lógicamente un pedido pendiente del cliente; conserva el historial."""
    _get_or_404(db, Cliente, "id_cliente", id_cliente)
    pedido = db.get(Pedido, id_pedido)
    if pedido is None or pedido.id_cliente != id_cliente:
        raise HTTPException(status_code=404, detail="Pedido no encontrado para este cliente.")

    estado_actual = db.get(EstadoPedido, pedido.id_estado_pedido)
    nombre_actual = _normalizar_estado_pedido(estado_actual.nombre_estado if estado_actual else None)
    if "cancel" in nombre_actual:
        return {"id_pedido": pedido.id_pedido, "estado": estado_actual.nombre_estado if estado_actual else "Cancelado", "cancelado": True}
    if "pendiente" not in nombre_actual:
        raise HTTPException(
            status_code=409,
            detail="Solo puedes cancelar un pedido que continúe en estado Pendiente.",
        )

    estados = db.scalars(select(EstadoPedido).order_by(EstadoPedido.id_estado_pedido)).all()
    estado_cancelado = next(
        (estado for estado in estados if "cancel" in _normalizar_estado_pedido(estado.nombre_estado)),
        None,
    )
    try:
        if estado_cancelado is None:
            estado_cancelado = EstadoPedido(nombre_estado="Cancelado")
            db.add(estado_cancelado)
            db.flush()
        pedido.id_estado_pedido = estado_cancelado.id_estado_pedido
        _commit_or_409(db)
        db.refresh(pedido)
    except Exception:
        db.rollback()
        raise

    return {"id_pedido": pedido.id_pedido, "estado": estado_cancelado.nombre_estado, "cancelado": True}
