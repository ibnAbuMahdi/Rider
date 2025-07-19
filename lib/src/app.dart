import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:secure_application/secure_application.dart';  // Replaced with AppSecurity
import '../utils/app_security.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/auth_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/connectivity_wrapper.dart';

class StikaRiderApp extends ConsumerWidget {
  const StikaRiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);
    
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.4),
          ),
          child: ConnectivityWrapper(
            child: AppSecurity.secureApp(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}