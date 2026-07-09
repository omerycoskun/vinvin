import 'package:flutter/material.dart';

import 'game_store.dart';
import 'ui_common.dart';

enum _Tab { cars, paint, rim, bumper, spoiler, neon, power }

extension on _Tab {
  String get title => switch (this) {
        _Tab.cars => 'Arabalar',
        _Tab.paint => 'Boya',
        _Tab.rim => 'Jant',
        _Tab.bumper => 'Tampon',
        _Tab.spoiler => 'Kanat',
        _Tab.neon => 'Neon',
        _Tab.power => 'Güç',
      };
}

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  _Tab _tab = _Tab.cars;

  @override
  Widget build(BuildContext context) {
    final store = GameStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garaj'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: MoneyBadge()),
        ],
      ),
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
              final car = store.selectedCarModel;
              return Row(
                children: [
                  // Sol: canlı önizleme.
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CarPreview(config: store.selectedConfig, size: 150),
                        const SizedBox(height: 8),
                        Text(car.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        SpeedStars(value: car.speedClass),
                      ],
                    ),
                  ),
                  // Sağ: sekmeler + içerik.
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTabs(),
                        Expanded(child: _buildContent(store, car)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: _Tab.values.map((t) {
          final sel = t == _tab;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(t.title),
              selected: sel,
              onSelected: (_) => setState(() => _tab = t),
              selectedColor: const Color(0xFFE53935),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(GameStore store, CarModel car) {
    switch (_tab) {
      case _Tab.cars:
        return ListView(
          padding: const EdgeInsets.all(10),
          children: kCars.map((c) => _carTile(store, c)).toList(),
        );
      case _Tab.paint:
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            for (var i = 0; i < kPaints.length; i++) _paintTile(store, car, i),
          ],
        );
      case _Tab.rim:
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            for (var i = 0; i < kRims.length; i++) _rimTile(store, car, i),
          ],
        );
      case _Tab.bumper:
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            for (var i = 0; i < kBumpers.length; i++) _bumperTile(store, car, i),
          ],
        );
      case _Tab.spoiler:
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            for (var i = 0; i < kSpoilers.length; i++)
              _spoilerTile(store, car, i),
          ],
        );
      case _Tab.neon:
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            for (var i = 0; i < kNeons.length; i++) _neonTile(store, car, i),
          ],
        );
      case _Tab.power:
        return ListView(
          padding: const EdgeInsets.all(10),
          children:
              UpgradeKind.values.map((k) => _upgradeTile(store, k)).toList(),
        );
    }
  }

  // ---- Araba ----
  Widget _carTile(GameStore store, CarModel c) {
    final owned = store.isCarOwned(c.id);
    final selected = store.selectedCar == c.id;
    final canBuy = !owned && store.money >= c.price;
    return _tile(
      selected: selected,
      leading: CarPreview(config: store.configFor(c.id), size: 56),
      title: c.name,
      subtitle: SpeedStars(value: c.speedClass),
      trailing: selected
          ? const _SelChip()
          : owned
              ? FilledButton(
                  onPressed: () => store.selectCar(c.id),
                  child: const Text('Seç'))
              : _buyBtn(c.price, canBuy, () async {
                  if (await store.buyCar(c.id)) store.selectCar(c.id);
                }),
    );
  }

  // ---- Boya ----
  Widget _paintTile(GameStore store, CarModel car, int i) {
    final opt = kPaints[i];
    final owned = store.isPaintOwned(i);
    final applied = store.carPaint(car.id) == i;
    final swatch = opt.color ?? car.defaultColor;
    final canBuy = !owned && store.money >= opt.price;
    return _tile(
      selected: applied,
      leading: _swatch(swatch),
      title: opt.name,
      trailing: _modTrailing(
        owned: owned,
        applied: applied,
        price: opt.price,
        canBuy: canBuy,
        onApply: () => store.applyPaint(car.id, i),
        onBuy: () async {
          if (await store.buyPaint(i)) store.applyPaint(car.id, i);
        },
      ),
    );
  }

  // ---- Jant ----
  Widget _rimTile(GameStore store, CarModel car, int i) {
    final opt = kRims[i];
    final owned = store.isRimOwned(i);
    final applied = store.carRim(car.id) == i;
    final canBuy = !owned && store.money >= opt.price;
    return _tile(
      selected: applied,
      leading: CircleAvatar(backgroundColor: opt.color, radius: 18,
          child: const Icon(Icons.blur_circular, size: 18, color: Colors.black54)),
      title: opt.name,
      trailing: _modTrailing(
        owned: owned,
        applied: applied,
        price: opt.price,
        canBuy: canBuy,
        onApply: () => store.applyRim(car.id, i),
        onBuy: () async {
          if (await store.buyRim(i)) store.applyRim(car.id, i);
        },
      ),
    );
  }

  // ---- Tampon ----
  Widget _bumperTile(GameStore store, CarModel car, int i) {
    final opt = kBumpers[i];
    final owned = store.isBumperOwned(i);
    final applied = store.carBumper(car.id) == i;
    final canBuy = !owned && store.money >= opt.price;
    return _tile(
      selected: applied,
      leading: const CircleAvatar(
          backgroundColor: Color(0xFF37474F),
          radius: 18,
          child: Icon(Icons.dashboard_customize, size: 18, color: Colors.white70)),
      title: opt.name,
      trailing: _modTrailing(
        owned: owned,
        applied: applied,
        price: opt.price,
        canBuy: canBuy,
        onApply: () => store.applyBumper(car.id, i),
        onBuy: () async {
          if (await store.buyBumper(i)) store.applyBumper(car.id, i);
        },
      ),
    );
  }

  // ---- Kanat ----
  Widget _spoilerTile(GameStore store, CarModel car, int i) {
    final opt = kSpoilers[i];
    final owned = store.isSpoilerOwned(i);
    final applied = store.carSpoiler(car.id) == i;
    final canBuy = !owned && store.money >= opt.price;
    return _tile(
      selected: applied,
      leading: const CircleAvatar(
          backgroundColor: Color(0xFF37474F),
          radius: 18,
          child: Icon(Icons.flight, size: 18, color: Colors.white70)),
      title: opt.name,
      trailing: _modTrailing(
        owned: owned,
        applied: applied,
        price: opt.price,
        canBuy: canBuy,
        onApply: () => store.applySpoiler(car.id, i),
        onBuy: () async {
          if (await store.buySpoiler(i)) store.applySpoiler(car.id, i);
        },
      ),
    );
  }

  // ---- Neon ----
  Widget _neonTile(GameStore store, CarModel car, int i) {
    final opt = kNeons[i];
    final owned = store.isNeonOwned(i);
    final applied = store.carNeon(car.id) == i;
    final canBuy = !owned && store.money >= opt.price;
    return _tile(
      selected: applied,
      leading: opt.color == null
          ? const CircleAvatar(
              backgroundColor: Color(0xFF2A2A2A),
              radius: 18,
              child: Icon(Icons.not_interested, size: 18, color: Colors.white54))
          : _swatch(opt.color!),
      title: opt.name,
      trailing: _modTrailing(
        owned: owned,
        applied: applied,
        price: opt.price,
        canBuy: canBuy,
        onApply: () => store.applyNeon(car.id, i),
        onBuy: () async {
          if (await store.buyNeon(i)) store.applyNeon(car.id, i);
        },
      ),
    );
  }

  // ---- Yükseltme ----
  Widget _upgradeTile(GameStore store, UpgradeKind k) {
    final level = store.upgradeLevel(k);
    final maxed = level >= kMaxUpgradeLevel;
    final cost = maxed ? 0 : upgradeCost(level);
    final canBuy = !maxed && store.money >= cost;
    return _tile(
      selected: false,
      leading: CircleAvatar(
          backgroundColor: const Color(0xFFE53935),
          radius: 18,
          child: Icon(k.icon, size: 18, color: Colors.white)),
      title: k.title,
      subtitle: _LevelBar(level: level),
      trailing: maxed
          ? const Chip(label: Text('MAX'), backgroundColor: Color(0xFFFFA000))
          : _buyBtn(cost, canBuy, () => store.buyUpgrade(k)),
    );
  }

  // ---- ortak ----
  Widget _modTrailing({
    required bool owned,
    required bool applied,
    required int price,
    required bool canBuy,
    required VoidCallback onApply,
    required Future<void> Function() onBuy,
  }) {
    if (applied) return const _SelChip();
    if (owned) {
      return FilledButton(onPressed: onApply, child: const Text('Uygula'));
    }
    return _buyBtn(price, canBuy, () => onBuy());
  }

  Widget _buyBtn(int price, bool canBuy, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: canBuy ? onTap : null,
      icon: const Icon(Icons.monetization_on, size: 16),
      label: Text('$price'),
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
    );
  }

  Widget _swatch(Color c) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
        ),
      );

  Widget _tile({
    required bool selected,
    required Widget leading,
    required String title,
    Widget? subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? const Color(0xFFFFD54F)
              : Colors.white.withValues(alpha: 0.08),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 60, child: Center(child: leading)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  subtitle,
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _SelChip extends StatelessWidget {
  const _SelChip();
  @override
  Widget build(BuildContext context) => const Chip(
        label: Text('AKTİF'),
        backgroundColor: Color(0xFF43A047),
        visualDensity: VisualDensity.compact,
      );
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.level});
  final int level;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(kMaxUpgradeLevel, (i) {
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 20,
          height: 7,
          decoration: BoxDecoration(
            color: i < level
                ? const Color(0xFF43A047)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
