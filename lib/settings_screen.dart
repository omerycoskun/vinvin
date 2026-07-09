import 'package:flutter/material.dart';

import 'game_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GameStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
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
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('Direksiyon kontrolü'),
                  RadioGroup<SteerMode>(
                    groupValue: store.steerMode,
                    onChanged: (v) {
                      if (v != null) store.setSteerMode(v);
                    },
                    child: Column(
                      children: SteerMode.values
                          .map((m) => RadioListTile<SteerMode>(
                                value: m,
                                secondary: Icon(m.icon),
                                title: Text(m.title),
                                subtitle: Text(m.desc),
                                activeColor: const Color(0xFFE53935),
                              ))
                          .toList(),
                    ),
                  ),
                  const Divider(),
                  _section('Düzen'),
                  ListTile(
                    leading: const Icon(Icons.touch_app),
                    title: const Text('Gaz / fren tarafı'),
                    subtitle: Text(store.gasOnRight
                        ? 'Sağda (yön solda)'
                        : 'Solda (yön sağda)'),
                    trailing: ToggleButtons(
                      isSelected: [!store.gasOnRight, store.gasOnRight],
                      onPressed: (i) => store.setGasOnRight(i == 1),
                      borderRadius: BorderRadius.circular(8),
                      constraints:
                          const BoxConstraints(minWidth: 52, minHeight: 36),
                      children: const [Text('Sol'), Text('Sağ')],
                    ),
                  ),
                  const Divider(),
                  _section('Genel'),
                  SwitchListTile(
                    value: store.soundOn,
                    onChanged: store.setSoundOn,
                    title: const Text('Ses'),
                    secondary: const Icon(Icons.volume_up),
                    activeThumbColor: const Color(0xFF43A047),
                  ),
                  ListTile(
                    leading: const Icon(Icons.emoji_events),
                    title: const Text('En iyi mesafe'),
                    trailing: Text('${store.bestDistance} m',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('İlerlemeyi sıfırla'),
                    subtitle: const Text(
                        'Para, arabalar, modifiye ve yükseltmeler silinir'),
                    onTap: () => _confirmReset(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
        child: Text(
          t.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
          ),
        ),
      );

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emin misin?'),
        content: const Text('Tüm ilerleme kalıcı olarak silinecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (ok == true) await GameStore.instance.resetAll();
  }
}
