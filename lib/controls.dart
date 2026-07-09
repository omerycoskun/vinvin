import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Basılı tutuldukça [onDown], bırakılınca [onUp] tetikleyen yuvarlak buton.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onDown,
    required this.onUp,
    this.size = 78,
    this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final double size;
  final String? label;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  bool _pressed = false;

  void _down() {
    setState(() => _pressed = true);
    widget.onDown();
  }

  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onUp();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _down(),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _pressed ? 0.95 : 0.7),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: widget.size * 0.42, color: Colors.white),
              if (widget.label != null)
                Text(widget.label!,
                    style: TextStyle(
                        fontSize: widget.size * 0.14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Çevrildikçe [onSteer] (-1..1) veren direksiyon simidi. Bırakılınca sıfıra
/// döner.
class SteeringWheel extends StatefulWidget {
  const SteeringWheel({super.key, required this.onSteer, this.size = 130});

  final ValueChanged<double> onSteer;
  final double size;

  @override
  State<SteeringWheel> createState() => _SteeringWheelState();
}

class _SteeringWheelState extends State<SteeringWheel>
    with SingleTickerProviderStateMixin {
  static const double _maxAngle = 2.6; // rad, tam kilit
  double _angle = 0;
  double _lastPointer = 0;

  double _pointerAngle(Offset local) {
    final c = widget.size / 2;
    return math.atan2(local.dy - c, local.dx - c);
  }

  void _start(Offset local) {
    _lastPointer = _pointerAngle(local);
  }

  void _update(Offset local) {
    final a = _pointerAngle(local);
    var d = a - _lastPointer;
    if (d > math.pi) d -= 2 * math.pi;
    if (d < -math.pi) d += 2 * math.pi;
    _lastPointer = a;
    setState(() {
      _angle = (_angle + d).clamp(-_maxAngle, _maxAngle);
    });
    widget.onSteer((_angle / _maxAngle).clamp(-1.0, 1.0));
  }

  void _end() {
    setState(() => _angle = 0);
    widget.onSteer(0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _start(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: Transform.rotate(
        angle: _angle,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _WheelPainter(),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Dış lastik.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22
        ..color = const Color(0xFF222327),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    // Göbek.
    canvas.drawCircle(c, r * 0.28, Paint()..color = const Color(0xFF33363B));
    // Kollar (3 kol).
    final arm = Paint()
      ..color = const Color(0xFF33363B)
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    for (final a in [math.pi / 2, math.pi / 2 + 2.09, math.pi / 2 + 4.18]) {
      canvas.drawLine(
          c, Offset(c.dx + math.cos(a) * r * 0.85, c.dy + math.sin(a) * r * 0.85), arm);
    }
    // Üst işaret.
    canvas.drawCircle(Offset(c.dx, c.dy - r * 0.88), r * 0.06,
        Paint()..color = const Color(0xFFE53935));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Alt köşe için dijital + yaylı hız göstergesi.
class SpeedometerGauge extends StatelessWidget {
  const SpeedometerGauge({
    super.key,
    required this.frac,
    required this.kmh,
    this.size = 96,
  });

  final double frac;
  final int kmh;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpeedoPainter(frac.clamp(0, 1)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$kmh',
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text('km/s',
                  style: TextStyle(
                      fontSize: size * 0.11,
                      color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedoPainter extends CustomPainter {
  _SpeedoPainter(this.frac);
  final double frac;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    // Zemin.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.45),
    );
    // Dolu.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep * frac,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(const Color(0xFF43A047), const Color(0xFFE53935), frac)!,
    );
    // İbre.
    final a = start + sweep * frac;
    canvas.drawLine(
      c,
      Offset(c.dx + math.cos(a) * r * 0.8, c.dy + math.sin(a) * r * 0.8),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedoPainter old) => old.frac != frac;
}
