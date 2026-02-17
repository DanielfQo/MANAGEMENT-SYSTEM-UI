import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
// Importa tus carpetas de core cuando las tengas listas
// import 'package:management_system_ui/core/common_libs.dart'; 

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final router = ref.watch(routerProvider);

    return MaterialApp.router( 
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Gestión de Inventario',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      // Configuramos el router
      routerConfig: router,
    );
  }
}