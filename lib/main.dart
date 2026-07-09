import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ad_service.dart';
import 'game_store.dart';
import 'menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await GameStore.instance.load();
  // Reklamları arka planda başlat (web/masaüstünde no-op).
  unawaited(AdService.instance.initialize());
  runApp(const VinVinApp());
}

class VinVinApp extends StatelessWidget {
  const VinVinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vın Vın',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE53935),
        brightness: Brightness.dark,
      ),
      home: const MenuScreen(),
    );
  }
}
