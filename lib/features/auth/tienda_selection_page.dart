import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class TiendaSelectionPage extends ConsumerWidget {
  const TiendaSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    final tiendas = authState.userMe?.tiendas ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Seleccionar Tienda")),
      body: ListView.builder(
        itemCount: tiendas.length,
        itemBuilder: (context, index) {
          final tienda = tiendas[index];

          return ListTile(
            title: Text(tienda.tiendaNombre),
            subtitle: Text(authState.userMe?.rol ?? ''),
            onTap: () {
              notifier.selectTienda(tienda.tiendaId);
              Navigator.pushReplacementNamed(context, '/inventory');
            },
          );
        },
      ),
    );
  }
}
