# API Parador Artesanal de Bécal

API FastAPI + SQLAlchemy para la base de datos SQL Server existente del proyecto.

## Qué contiene

- 18 entidades del modelo físico.
- 24 relaciones mediante claves foráneas.
- CRUD para las 18 entidades.
- GET por ID, paginación, PUT y PATCH.
- Manejo de errores de integridad (HTTP 409).
- CORS para conectar una app web/móvil.
- Endpoints de catálogo para productos y artesanos.
- `/docs` para probar la API desde Swagger.
- NO usa `Base.metadata.create_all()`: la base debe existir previamente en SQL Server.

## 1. Instalar

```bash
python -m venv .venv
.venv\Scripts\activate
# Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
```

También debes tener instalado en Windows el **Microsoft ODBC Driver 17 for SQL Server** (o adaptar la URL al driver que tengas).

## 2. Configurar conexión

Copia `.env.example` a `.env` y sustituye usuario, contraseña, servidor y nombre de base de datos.

Ejemplo:

```env
DATABASE_URL=mssql+pyodbc://sa:MiClave@localhost/ParadorBecal?driver=ODBC+Driver+17+for+SQL+Server&TrustServerCertificate=yes
```

## 3. Ejecutar

```bash
python run.py
```

Luego abre `http://127.0.0.1:8000/docs`.

## 4. Antes de conectar la app

Prueba primero:

- `GET /health` para verificar SQL Server.
- `GET /productos` para comprobar que el ORM coincide con la tabla real.
- `GET /artesanos` para comprobar la segunda entidad.
- Los POST/PUT/PATCH/DELETE desde Swagger.

## Importante

Este proyecto está diseñado para la estructura del archivo DM1 proporcionado. Los nombres físicos como `Id_puesto`, `Id_producto`, `id_Proveedor` y `años_experiencia` se mapean desde Python para evitar problemas con nombres poco cómodos.

El endpoint `/catalogo/productos` permite filtrar por nombre, artesano, estilo y calidad.

La autenticación de usuarios (login/JWT) debe añadirse antes de poner la API públicamente en Internet; para la primera integración móvil/web conviene probar primero que la conexión y el CRUD funcionan correctamente.
