String formatoMoneda(num? valor) => '\$${(valor ?? 0).toStringAsFixed(2)}';
String formatoFecha(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Sin fecha';
  final fecha = DateTime.tryParse(valor);
  if (fecha == null) return valor;
  return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}
