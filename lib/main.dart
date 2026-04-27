import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'core/router.dart';
import 'core/theme/app_colors.dart';

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
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.lightBackground,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
          titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          labelLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w500),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'PE'),
        Locale('es'),
        Locale('en'),
      ],
      routerConfig: router,
    );
  }
}