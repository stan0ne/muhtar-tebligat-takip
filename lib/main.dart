import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/log_service.dart';
import 'ui/providers/app_provider.dart';
import 'ui/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Servisleri başlat (DB aç + seed admin).
  await Services.init();

  final appProvider = AppProvider();
  await appProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
      ],
      child: const AppRoot(),
    ),
  );
}
