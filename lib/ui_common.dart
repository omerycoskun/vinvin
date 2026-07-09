import 'package:flutter/material.dart';

import 'car_painter.dart';
import 'game_store.dart';

/// Sağ üstte para göstergesi.
class MoneyBadge extends StatelessWidget {
  const MoneyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameStore.instance,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on,
                  color: Color(0xFFFFD54F), size: 20),
              const SizedBox(width: 6),
              Text(
                '${GameStore.instance.money}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bir arabayı (arkadan görünüm) kutu içinde çizen önizleme.
class CarPreview extends StatelessWidget {
  const CarPreview({super.key, required this.config, this.size = 120});

  final CarConfig config;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: CustomPaint(painter: _CarPreviewPainter(config)),
    );
  }
}

class _CarPreviewPainter extends CustomPainter {
  _CarPreviewPainter(this.config);
  final CarConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.10,
      size.height * 0.05,
      size.width * 0.80,
      size.height * 0.9,
    );
    paintCar(canvas, rect, config);
  }

  @override
  bool shouldRepaint(covariant _CarPreviewPainter old) =>
      old.config.bodyColor != config.bodyColor ||
      old.config.car.id != config.car.id ||
      old.config.rimIndex != config.rimIndex ||
      old.config.bumperIndex != config.bumperIndex;
}

/// Büyük yuvarlak menü butonu.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1..5 hız sınıfı yıldızları.
class SpeedStars extends StatelessWidget {
  const SpeedStars({super.key, required this.value, this.max = 5});
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        max,
        (i) => Icon(
          i < value ? Icons.star : Icons.star_border,
          size: 16,
          color: const Color(0xFFFFD54F),
        ),
      ),
    );
  }
}
