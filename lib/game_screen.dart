import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'ad_service.dart';
import 'controls.dart';
import 'game_store.dart';
import 'racer_game.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late RacerGame _game;
  bool _gameOver = false;
  int _finalDistance = 0;
  int _finalCoins = 0;
  int _earned = 0;

  final _focus = FocusNode();
  final Set<LogicalKeyboardKey> _keys = {};
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _game = RacerGame(store: GameStore.instance, onGameOver: _handleGameOver);
    if (GameStore.instance.steerMode == SteerMode.gyro) {
      _subscribeGyro();
    }
  }

  void _subscribeGyro() {
    _accelSub?.cancel();
    try {
      _accelSub = accelerometerEventStream().listen((e) {
        // Yatay modda telefonu sağa/sola yatırma ekseni.
        final v = (-e.y * 0.32).clamp(-1.0, 1.0);
        _game.steerInput = v.abs() < 0.08 ? 0 : v;
      });
    } catch (_) {
      // Jiroskop yoksa sessizce geç (web/masaüstü).
    }
  }

  Future<void> _handleGameOver(int distance, int coins) async {
    _game.gasHeld = false;
    _game.brakeHeld = false;
    _game.steerInput = 0;
    final earned = await GameStore.instance
        .registerRun(distance: distance, coins: coins);
    await AdService.instance.notifyGameOverAndMaybeShow();
    if (!mounted) return;
    setState(() {
      _gameOver = true;
      _finalDistance = distance;
      _finalCoins = coins;
      _earned = earned;
    });
  }

  void _restart() {
    setState(() {
      _gameOver = false;
      _startGame();
    });
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _focus.dispose();
    super.dispose();
  }

  // ---- Klavye (web/masaüstü test) ----
  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      _keys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _keys.remove(event.logicalKey);
    }
    _applyKeys();
  }

  void _applyKeys() {
    bool any(List<LogicalKeyboardKey> k) => k.any(_keys.contains);
    _game.gasHeld = any([LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW]);
    _game.brakeHeld =
        any([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS]);
    final left =
        any([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA]);
    final right =
        any([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD]);
    _game.steerInput = (right ? 1.0 : 0) + (left ? -1.0 : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            GameWidget(game: _game),
            if (!_gameOver) _buildHud(),
            if (!_gameOver) _buildControls(),
            if (_gameOver) _buildGameOver(),
          ],
        ),
      ),
    );
  }

  // ---- HUD (üst bar + alt köşe hız) ----
  Widget _buildHud() {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pill(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _game.distanceMeters,
                    builder: (_, v, _) => Text('$v m',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const Spacer(),
                _pill(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _game.coinsCollected,
                    builder: (_, v, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on,
                            color: Color(0xFFFFD54F), size: 16),
                        const SizedBox(width: 4),
                        Text('$v',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Alt köşe hız göstergesi.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ValueListenableBuilder<double>(
                valueListenable: _game.speedFrac,
                builder: (_, frac, _) => ValueListenableBuilder<int>(
                  valueListenable: _game.speedKmh,
                  builder: (_, kmh, _) =>
                      SpeedometerGauge(frac: frac, kmh: kmh, size: 88),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Kontrol overlay'leri ----
  Widget _buildControls() {
    final store = GameStore.instance;
    final gasRight = store.gasOnRight;
    final gasAlign = gasRight ? Alignment.bottomRight : Alignment.bottomLeft;
    final steerAlign = gasRight ? Alignment.bottomLeft : Alignment.bottomRight;

    return SafeArea(
      child: Stack(
        children: [
          // Gaz + fren kümesi.
          Align(
            alignment: gasAlign,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HoldButton(
                    icon: Icons.keyboard_double_arrow_up,
                    color: const Color(0xFF43A047),
                    label: 'GAZ',
                    onDown: () => _game.gasHeld = true,
                    onUp: () => _game.gasHeld = false,
                  ),
                  const SizedBox(height: 12),
                  HoldButton(
                    icon: Icons.stop_circle_outlined,
                    color: const Color(0xFFE53935),
                    label: 'FREN',
                    size: 66,
                    onDown: () => _game.brakeHeld = true,
                    onUp: () => _game.brakeHeld = false,
                  ),
                ],
              ),
            ),
          ),
          // Yön kümesi (moda göre).
          Align(
            alignment: steerAlign,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _buildSteering(store.steerMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteering(SteerMode mode) {
    switch (mode) {
      case SteerMode.buttons:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HoldButton(
              icon: Icons.arrow_back,
              color: const Color(0xFF1E88E5),
              onDown: () => _game.steerInput = -1,
              onUp: () => _game.steerInput = 0,
            ),
            const SizedBox(width: 14),
            HoldButton(
              icon: Icons.arrow_forward,
              color: const Color(0xFF1E88E5),
              onDown: () => _game.steerInput = 1,
              onUp: () => _game.steerInput = 0,
            ),
          ],
        );
      case SteerMode.wheel:
        return SteeringWheel(
          size: 128,
          onSteer: (v) => _game.steerInput = v,
        );
      case SteerMode.gyro:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.screen_rotation, color: Colors.white70),
              const SizedBox(height: 4),
              Text('Telefonu eğ',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        );
    }
  }

  Widget _pill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  // ---- Oyun sonu ----
  Widget _buildGameOver() {
    final isBest =
        _finalDistance >= GameStore.instance.bestDistance && _finalDistance > 0;
    return Container(
      color: Colors.black.withValues(alpha: 0.74),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBest ? 'YENİ REKOR!' : 'ÇARPTIN!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color:
                      isBest ? const Color(0xFFFFD54F) : const Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 16),
              _statRow('Mesafe', '$_finalDistance m'),
              _statRow('Toplanan para', '$_finalCoins'),
              const Divider(height: 22),
              _statRow('Kazanılan', '+$_earned', highlight: true),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleBtn(
                    icon: Icons.home,
                    color: const Color(0xFF546E7A),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 18),
                  _circleBtn(
                    icon: Icons.refresh,
                    color: const Color(0xFFE53935),
                    big: true,
                    onTap: _restart,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(width: 40),
          Text(value,
              style: TextStyle(
                  fontSize: highlight ? 20 : 15,
                  fontWeight: FontWeight.bold,
                  color:
                      highlight ? const Color(0xFFFFD54F) : Colors.white)),
        ],
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool big = false,
  }) {
    final s = big ? 68.0 : 52.0;
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
            width: s, height: s, child: Icon(icon, size: big ? 34 : 26)),
      ),
    );
  }
}
