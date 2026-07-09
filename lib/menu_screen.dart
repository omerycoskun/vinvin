import 'package:flutter/material.dart';

import 'ad_banner.dart';
import 'game_screen.dart';
import 'game_store.dart';
import 'garage_screen.dart';
import 'settings_screen.dart';
import 'ui_common.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GameStore.instance;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: const [Spacer(), MoneyBadge()],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // Sol: logo + araba önizleme.
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _Logo(),
                              const SizedBox(height: 6),
                              CarPreview(config: store.selectedConfig, size: 130),
                              Text(
                                store.selectedCarModel.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'En iyi: ${store.bestDistance} m',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                        // Sağ: butonlar.
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                BigButton(
                                  label: 'OYNA',
                                  icon: Icons.play_arrow,
                                  color: const Color(0xFFE53935),
                                  onTap: () => _open(context, const GameScreen()),
                                ),
                                const SizedBox(height: 14),
                                BigButton(
                                  label: 'GARAJ',
                                  icon: Icons.garage,
                                  color: const Color(0xFF1E88E5),
                                  onTap: () =>
                                      _open(context, const GarageScreen()),
                                ),
                                const SizedBox(height: 14),
                                BigButton(
                                  label: 'AYARLAR',
                                  icon: Icons.settings,
                                  color: const Color(0xFF546E7A),
                                  onTap: () =>
                                      _open(context, const SettingsScreen()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const AdBanner(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFF7043)],
          ).createShader(rect),
          child: const Text(
            'VIN VIN',
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          'sonsuz trafik yarışı',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
