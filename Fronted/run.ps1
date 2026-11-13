# Detecta automáticamente la IP IPv4 activa de tu computadora (ignorando localhost y redes virtuales)
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -ExpandProperty IPAddress -First 1)

Write-Host "==================================================" -ForegroundColor Green
Write-Host "  IP Local detectada automáticamente: $ip" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green

# Ejecuta Flutter inyectando esa IP de manera dinámica
flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080 --dart-define=API_IP=$ip