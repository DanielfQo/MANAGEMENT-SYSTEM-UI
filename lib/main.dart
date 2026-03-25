import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // App cerrada (cold start)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      final path = '/${initialLink.host}${initialLink.path}';
      final query = initialLink.query.isNotEmpty ? '?${initialLink.query}' : '';
      ref.read(routerProvider).go('$path$query');
    }

    // App abierta (foreground)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final path = '/${uri.host}${uri.path}';
        final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
        ref.read(routerProvider).go('$path$query');
      });
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Gestión de Inventario',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}