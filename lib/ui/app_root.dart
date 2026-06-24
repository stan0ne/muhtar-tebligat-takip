import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'shell/home_shell.dart';

/// Uygulama kökü: tema + giriş/durum yönlendirmesi.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: app.themeMode,
      home: const HomeShell(),
    );
  }
}
