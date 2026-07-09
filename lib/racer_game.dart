import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'car_painter.dart';
import 'game_store.dart';

class _RoadObject {
  _RoadObject(this.z, this.lane);
  double z;
  final double lane;
  bool dead = false;
}

class _Traffic extends _RoadObject {
  _Traffic(super.z, super.lane, this.config, this.speed);
  final double speed;
  final CarConfig config;
}

class _Coin extends _RoadObject {
  _Coin(super.z, super.lane);
}

const List<double> _laneCenters = [-0.6, 0.0, 0.6];
const double _visibleRange = 700;

/// Pseudo-3D sonsuz trafik yarışı (yatay). Kontroller dışarıdan beslenir:
/// [gasHeld]/[brakeHeld] hızı, [steerInput] (-1..1) yönü belirler.
class RacerGame extends FlameGame {
  RacerGame({required this.store, required this.onGameOver});

  final GameStore store;
  final void Function(int distance, int coins) onGameOver;

  // ---- Dışarıdan (UI/kontroller) beslenen girdi ----
  bool gasHeld = false;
  bool brakeHeld = false;
  double steerInput = 0; // -1 sol .. +1 sağ

  // ---- HUD ----
  final ValueNotifier<int> distanceMeters = ValueNotifier(0);
  final ValueNotifier<int> coinsCollected = ValueNotifier(0);
  final ValueNotifier<double> speedFrac = ValueNotifier(0);
  final ValueNotifier<int> speedKmh = ValueNotifier(0);

  final _rng = Random();

  late CarConfig _playerConfig;
  double _playerLane = 0;

  double _speed = 90;
  late double _maxSpeed;
  late double _accel;
  late double _steerSpeed;

  double _distance = 0;
  int _coins = 0;
  bool _crashed = false;
  bool get crashed => _crashed;

  final List<_Traffic> _traffic = [];
  final List<_Coin> _coinItems = [];
  double _distToNextSpawn = 140;
  double _shake = 0;

  // Projeksiyon.
  double _horizonY = 0;
  double _bottomY = 0;
  double _centerX = 0;
  double _roadHalfNear = 0;
  static const double _sMin = 0.12;

  @override
  Color backgroundColor() => const Color(0xFF6DD5FA);

  @override
  Future<void> onLoad() async {
    _playerConfig = store.selectedConfig;
    final cls = _playerConfig.car.speedClass;
    _maxSpeed = 260 +
        store.upgradeFactor(UpgradeKind.engine) * 220 +
        cls * 28;
    _accel = 60 + store.upgradeFactor(UpgradeKind.accel) * 90 + cls * 4;
    _steerSpeed = 1.5 + store.upgradeFactor(UpgradeKind.handling) * 1.6;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _horizonY = size.y * 0.26;
    _bottomY = size.y;
    _centerX = size.x / 2;
    // Yatayda yol çok geniş olmasın.
    _roadHalfNear = min(size.x * 0.34, size.y * 1.1);
  }

  double _tOf(double z) => (z / _visibleRange).clamp(0.0, 1.0);
  double _s(double t) => 1.0 / (1.0 + t * (1.0 / _sMin - 1.0));
  double _screenY(double t) {
    final s = _s(t);
    return _bottomY - (_bottomY - _horizonY) * (1 - s) / (1 - _sMin);
  }

  double _roadHalf(double t) => _roadHalfNear * _s(t);
  double _screenX(double lane, double t) => _centerX + lane * _roadHalf(t);

  @override
  void update(double dt) {
    super.update(dt);
    if (_crashed) return;
    dt = dt.clamp(0.0, 1 / 30);

    // Hız: gaz / fren / boşta yavaşlama.
    if (gasHeld) {
      _speed = min(_maxSpeed, _speed + _accel * dt);
    } else if (brakeHeld) {
      _speed = max(0, _speed - _accel * 2.2 * dt);
    } else {
      _speed = max(0, _speed - _accel * 0.5 * dt);
    }
    speedFrac.value = (_speed / _maxSpeed).clamp(0.0, 1.0);
    speedKmh.value = (_speed * 0.9).round();

    _distance += _speed * dt;
    distanceMeters.value = _distance ~/ 1;

    // Direksiyon (dış girdi).
    _playerLane += steerInput * _steerSpeed * dt;
    _playerLane = _playerLane.clamp(-0.85, 0.85);

    _updateTraffic(dt);
    _updateCoins(dt);
    _updateSpawns(dt);
    if (_shake > 0) _shake = max(0, _shake - dt * 40);
  }

  void _updateTraffic(double dt) {
    for (final t in _traffic) {
      t.z -= (_speed - t.speed) * dt;
      if (t.z < 12 && t.z > -6 && (t.lane - _playerLane).abs() < 0.42) {
        _onCrash();
        return;
      }
      if (t.z < -40 || t.z > _visibleRange + 200) t.dead = true;
    }
    _traffic.removeWhere((t) => t.dead);
  }

  void _updateCoins(double dt) {
    for (final c in _coinItems) {
      c.z -= _speed * dt;
      if (c.z < 10 && c.z > -6 && (c.lane - _playerLane).abs() < 0.4) {
        c.dead = true;
        _coins += 1;
        coinsCollected.value = _coins;
      } else if (c.z < -20) {
        c.dead = true;
      }
    }
    _coinItems.removeWhere((c) => c.dead);
  }

  void _updateSpawns(double dt) {
    _distToNextSpawn -= _speed * dt;
    if (_distToNextSpawn > 0) return;

    final difficulty = (_distance / 2500).clamp(0.0, 1.0);
    _distToNextSpawn = 230 - difficulty * 120 + _rng.nextDouble() * 90;

    final lane = _rng.nextInt(3);
    final blockedNear =
        _traffic.where((t) => (t.z - _visibleRange).abs() < 90).length;
    if (blockedNear >= 2) return; // en az bir şerit boş

    final car = kCars[_rng.nextInt(kCars.length)];
    final paint = _rng.nextInt(kPaints.length);
    final cfg = CarConfig(
        car: car, paintIndex: paint, rimIndex: 0, bumperIndex: 0);
    final tspeed = 70 + _rng.nextDouble() * 120 + difficulty * 70;
    _traffic.add(_Traffic(_visibleRange, _laneCenters[lane], cfg, tspeed));

    if (_rng.nextDouble() < 0.5) {
      final coinLane = _laneCenters[_rng.nextInt(3)];
      final base = _visibleRange - 40.0;
      for (var i = 0; i < 4; i++) {
        _coinItems.add(_Coin(base - i * 32, coinLane));
      }
    }
  }

  void _onCrash() {
    if (_crashed) return;
    _crashed = true;
    _shake = 18;
    Future.microtask(() => onGameOver(_distance ~/ 1, _coins));
  }

  // ---------------- Render ----------------

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (_shake > 0) {
      canvas.translate((_rng.nextDouble() - 0.5) * _shake,
          (_rng.nextDouble() - 0.5) * _shake);
    }
    _drawSkyAndGround(canvas);
    _drawRoad(canvas);
    _drawLaneMarkings(canvas);
    _drawObjectsAndPlayer(canvas);
    canvas.restore();
    super.render(canvas);
  }

  void _drawSkyAndGround(Canvas canvas) {
    final sky = Rect.fromLTWH(0, 0, size.x, _horizonY);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2980B9), Color(0xFF6DD5FA)],
        ).createShader(sky),
    );
    final ground = Rect.fromLTWH(0, _horizonY, size.x, size.y - _horizonY);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5AA02C), Color(0xFF3C7A18)],
        ).createShader(ground),
    );
  }

  void _drawRoad(Canvas canvas) {
    final nearHalf = _roadHalf(0);
    final farHalf = _roadHalf(1);
    final road = Path()
      ..moveTo(_centerX - nearHalf, _bottomY)
      ..lineTo(_centerX + nearHalf, _bottomY)
      ..lineTo(_centerX + farHalf, _horizonY)
      ..lineTo(_centerX - farHalf, _horizonY)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF424852));

    const step = 24.0;
    for (double z = 0; z < _visibleRange; z += step) {
      final t0 = _tOf(z);
      final t1 = _tOf(z + step);
      final band = ((z + _distance) ~/ step) % 2 == 0;
      final color = band ? const Color(0xFFDD3333) : Colors.white;
      for (final side in [-1.0, 1.0]) {
        final path = Path()
          ..moveTo(_screenX(side * 1.02, t0), _screenY(t0))
          ..lineTo(_screenX(side * 1.12, t0), _screenY(t0))
          ..lineTo(_screenX(side * 1.12, t1), _screenY(t1))
          ..lineTo(_screenX(side * 1.02, t1), _screenY(t1))
          ..close();
        canvas.drawPath(path, Paint()..color = color);
      }
    }

    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(_screenX(side, 0), _bottomY),
        Offset(_screenX(side, 1), _horizonY),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );
    }
  }

  void _drawLaneMarkings(Canvas canvas) {
    const period = 60.0;
    const dashLen = 30.0;
    const step = 12.0;
    for (final boundary in [-0.3, 0.3]) {
      for (double z = 0; z < _visibleRange; z += step) {
        if ((z + _distance) % period > dashLen) continue;
        final t0 = _tOf(z);
        final t1 = _tOf(z + step);
        final wHalf0 = _roadHalf(t0) * 0.012 + 1;
        final wHalf1 = _roadHalf(t1) * 0.012 + 1;
        final x0 = _screenX(boundary, t0);
        final x1 = _screenX(boundary, t1);
        final path = Path()
          ..moveTo(x0 - wHalf0, _screenY(t0))
          ..lineTo(x0 + wHalf0, _screenY(t0))
          ..lineTo(x1 + wHalf1, _screenY(t1))
          ..lineTo(x1 - wHalf1, _screenY(t1))
          ..close();
        canvas.drawPath(
            path, Paint()..color = Colors.white.withValues(alpha: 0.9));
      }
    }
  }

  void _drawObjectsAndPlayer(Canvas canvas) {
    final objs = <_RoadObject>[..._traffic, ..._coinItems]
      ..sort((a, b) => b.z.compareTo(a.z));

    for (final o in objs) {
      if (o.z <= 0) continue;
      final t = _tOf(o.z);
      final s = _s(t);
      if (o is _Traffic) {
        final w = _roadHalfNear * 0.5 * s;
        final h = w * 1.5;
        final cx = _screenX(o.lane, t);
        final cy = _screenY(t);
        paintCar(
          canvas,
          Rect.fromCenter(center: Offset(cx, cy - h * 0.5), width: w, height: h),
          o.config,
        );
      } else {
        _drawCoin(canvas, o.lane, t, s);
      }
    }

    // Oyuncu (en yakın).
    final w = _roadHalfNear * 0.52;
    final h = w * 1.5;
    final cx = _screenX(_playerLane, 0);
    final cy = _bottomY - h * 0.28;
    paintCar(
      canvas,
      Rect.fromCenter(center: Offset(cx, cy - h * 0.5), width: w, height: h),
      _playerConfig,
      brake: brakeHeld,
    );
  }

  void _drawCoin(Canvas canvas, double lane, double t, double s) {
    final r = _roadHalfNear * 0.08 * s;
    if (r < 1) return;
    final cx = _screenX(lane, t);
    final cy = _screenY(t) - r * 2.2;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(
        Offset(cx, cy), r * 0.62, Paint()..color = const Color(0xFFFFA000));
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.3), r * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  @override
  void onRemove() {
    distanceMeters.dispose();
    coinsCollected.dispose();
    speedFrac.dispose();
    speedKmh.dispose();
    super.onRemove();
  }
}
