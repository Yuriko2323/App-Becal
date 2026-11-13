
#!/usr/bin/env bash
set -euo pipefail

echo "===================================="
echo "Instalando dependencias para SQL Server"
echo "===================================="

# Comprobar el sistema operativo
. /etc/os-release
echo "Sistema detectado: $PRETTY_NAME"

if [ "${ID:-}" != "debian" ] || [ "${VERSION_ID:-}" != "12" ]; then
    echo "Error: Se esperaba Debian 12."
    exit 1
fi

# Ejecutar comandos con permisos administrativos
run_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Descargar el repositorio oficial de Microsoft para Debian 12
curl -fsSL -o /tmp/packages-microsoft-prod.deb \
    https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb

# Registrar el repositorio
run_root dpkg -i /tmp/packages-microsoft-prod.deb

# Actualizar paquetes
run_root apt-get update

# Instalar ODBC Driver 17 y sus dependencias
run_root env ACCEPT_EULA=Y apt-get install -y \
    msodbcsql17 \
    unixodbc-dev \
    libgssapi-krb5-2

# Instalar dependencias Python
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

# Comprobar que el controlador quedó registrado
echo "===================================="
echo "Controladores ODBC instalados:"
echo "===================================="

odbcinst -q -d

echo "Instalación finalizada."
