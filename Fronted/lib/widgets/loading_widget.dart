import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String mensaje;
  const LoadingWidget({super.key, this.mensaje = 'Cargando información…'});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(), const SizedBox(height: 12), Text(mensaje),
    ]),
  ));
}
