import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_store.dart';

class _StyleParams {
  const _StyleParams({
    required this.widthF,
    required this.roofWF,
    required this.glassTop,
    required this.glassBot,
  });
  final double widthF;
  final double roofWF;
  final double glassTop;
  final double glassBot;
}

_StyleParams _paramsFor(BodyStyle b) => switch (b) {
      BodyStyle.hatchback =>
        const _StyleParams(widthF: .80, roofWF: .72, glassTop: .14, glassBot: .40),
      BodyStyle.sedan =>
        const _StyleParams(widthF: .82, roofWF: .64, glassTop: .12, glassBot: .34),
      BodyStyle.coupe =>
        const _StyleParams(widthF: .82, roofWF: .58, glassTop: .16, glassBot: .46),
      BodyStyle.sport =>
        const _StyleParams(widthF: .92, roofWF: .54, glassTop: .18, glassBot: .44),
    };

/// Bir arabayı [rect] içine "arkadan" görünümle, [config]'deki gövde stili +
/// tüm modifiyelerle (renk/jant/tampon/kanat/neon) çizer.
void paintCar(
  Canvas canvas,
  Rect rect,
  CarConfig config, {
  bool brake = false,
  bool shadow = true,
}) {
  final p = _paramsFor(config.car.body);
  final color = config.bodyColor;
  final roof = config.car.roof;
  final w = rect.width;
  final h = rect.height;
  final cx = rect.center.dx;

  final bodyW = w * p.widthF;
  final left = cx - bodyW / 2;
  final right = cx + bodyW / 2;
  final bodyTop = rect.top + h * 0.12;
  final bodyBot = rect.bottom - h * 0.10;

  // ---- Neon (gövdenin altında parlama) ----
  final neon = config.neon.color;
  if (neon != null) {
    canvas.drawOval(
      Rect.fromLTWH(left - w * 0.04, bodyBot - h * 0.04, bodyW + w * 0.08, h * 0.20),
      Paint()
        ..color = neon.withValues(alpha: 0.75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.06),
    );
  }

  if (shadow) {
    canvas.drawOval(
      Rect.fromLTWH(left, bodyBot - h * 0.06, bodyW, h * 0.16),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  // ---- Tekerlekler (jantlar) ----
  final wheelW = bodyW * 0.20;
  final wheelH = h * 0.30;
  final wheelY = bodyBot - wheelH * 0.9;
  _drawWheel(canvas,
      Rect.fromLTWH(left - wheelW * 0.35, wheelY, wheelW, wheelH), config.rim);
  _drawWheel(canvas,
      Rect.fromLTWH(right - wheelW * 0.65, wheelY, wheelW, wheelH), config.rim);

  // ---- Arka tampon ----
  _drawBumper(canvas, rect, left, right, bodyBot, bodyW, h, config.bumper);

  // ---- Kanat / spoiler ----
  _drawSpoiler(canvas, config.spoilerStyle, cx, bodyTop, bodyW, w, h, color);

  // ---- Gövde ----
  final body = Path()
    ..moveTo(left + bodyW * 0.03, bodyTop)
    ..lineTo(right - bodyW * 0.03, bodyTop)
    ..lineTo(right, bodyBot - h * 0.04)
    ..quadraticBezierTo(right, bodyBot, right - bodyW * 0.06, bodyBot)
    ..lineTo(left + bodyW * 0.06, bodyBot)
    ..quadraticBezierTo(left, bodyBot, left, bodyBot - h * 0.04)
    ..close();
  canvas.drawPath(
    body,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, 0.28)!,
          color,
          Color.lerp(color, Colors.black, 0.28)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect),
  );

  // ---- Greenhouse (tavan + arka cam) ----
  final gTop = rect.top + h * p.glassTop;
  final gBot = rect.top + h * p.glassBot;
  final roofHalf = bodyW * p.roofWF / 2;
  final glass = Path()
    ..moveTo(cx - roofHalf * 0.9, gTop)
    ..lineTo(cx + roofHalf * 0.9, gTop)
    ..lineTo(cx + roofHalf, gBot)
    ..lineTo(cx - roofHalf, gBot)
    ..close();
  canvas.drawPath(
    glass,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(roof, Colors.white, 0.15)!,
          Color.lerp(roof, Colors.black, 0.35)!,
        ],
      ).createShader(Rect.fromLTRB(left, gTop, right, gBot)),
  );
  canvas.drawLine(
    Offset(cx - roofHalf * 0.6, gTop + (gBot - gTop) * 0.2),
    Offset(cx + roofHalf * 0.2, gBot - (gBot - gTop) * 0.2),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = h * 0.02,
  );

  // ---- Stop lambaları ----
  final lampColor = brake ? const Color(0xFFFF5252) : const Color(0xFFC62828);
  for (final isLeft in [true, false]) {
    final lx = isLeft ? left + bodyW * 0.10 : right - bodyW * 0.26;
    final lampRect = Rect.fromLTWH(lx, bodyBot - h * 0.18, bodyW * 0.16, h * 0.07);
    if (brake) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(lampRect.inflate(2.5), const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFFFF5252).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(lampRect, const Radius.circular(2)),
      Paint()..color = lampColor,
    );
  }
}

void _drawSpoiler(Canvas canvas, int style, double cx, double bodyTop,
    double bodyW, double w, double h, Color color) {
  if (style == 0) return;
  final dark = Color.lerp(color, Colors.black, 0.4)!;
  if (style == 1) {
    // Lip: gövde arkasında ince kabartma.
    final sw = bodyW * 0.9;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - sw / 2, bodyTop - h * 0.015, sw, h * 0.03),
          const Radius.circular(2)),
      Paint()..color = dark,
    );
    return;
  }
  // Orta kanat (2) veya GT kanat (3): ayaklı kanat.
  final big = style == 3;
  final sw = bodyW * (big ? 1.02 : 0.9);
  final sx = cx - sw / 2;
  final barH = h * (big ? 0.06 : 0.045);
  final legH = h * (big ? 0.10 : 0.06);
  final sy = bodyTop - legH - barH * 0.5;
  // ayaklar
  for (final fx in [cx - sw * 0.30, cx + sw * 0.30]) {
    canvas.drawRect(
      Rect.fromLTWH(fx - w * 0.012, sy + barH, w * 0.024, legH),
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
  }
  // kanat çıtası
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(sx, sy, sw, barH), const Radius.circular(3)),
    Paint()..color = dark,
  );
}

void _drawWheel(Canvas canvas, Rect r, RimOption rim) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.35)),
    Paint()..color = const Color(0xFF171717),
  );
  final hub = Rect.fromCenter(
      center: r.center, width: r.width * 0.72, height: r.height * 0.6);
  canvas.drawOval(hub, Paint()..color = rim.color);
  canvas.drawOval(
    hub,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.black.withValues(alpha: 0.4),
  );
  final c = r.center;
  final rx = hub.width / 2;
  final ry = hub.height / 2;
  final spokePaint = Paint()
    ..color = Color.lerp(rim.color, Colors.black, 0.45)!
    ..strokeWidth = 1.1;
  for (var i = 0; i < rim.spokes; i++) {
    final a = (i / rim.spokes) * math.pi * 2;
    canvas.drawLine(
        c, Offset(c.dx + math.cos(a) * rx, c.dy + math.sin(a) * ry), spokePaint);
  }
  canvas.drawCircle(c, r.width * 0.10, Paint()..color = const Color(0xFF444444));
}

void _drawBumper(Canvas canvas, Rect rect, double left, double right,
    double bodyBot, double bodyW, double h, BumperOption bumper) {
  final wide = bumper.style == 4;
  final bw = bodyW * (wide ? 1.08 : 1.02);
  final bx = rect.center.dx - bw / 2;
  final by = bodyBot - h * 0.02;
  final bh = h * (wide ? 0.12 : 0.10);
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(4)),
    Paint()..color = const Color(0xFF2A2A2A),
  );

  switch (bumper.style) {
    case 1: // spor kırmızı şerit
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(bx + bw * 0.1, by + bh * 0.55, bw * 0.8, bh * 0.3),
            const Radius.circular(2)),
        Paint()..color = const Color(0xFF9E1B1B),
      );
      break;
    case 2: // difüzör fin'ler
    case 4: // geniş difüzör
      final fins = wide ? 7 : 5;
      final finPaint = Paint()..color = const Color(0xFF555555);
      for (var i = 0; i < fins; i++) {
        final fx = bx + bw * (0.14 + i * (0.72 / (fins - 1)));
        canvas.drawRect(
            Rect.fromLTWH(fx, by + bh * 0.25, bw * 0.028, bh * 0.7), finPaint);
      }
      break;
    case 3: // çift egzoz
      final ePaint = Paint()..color = const Color(0xFFB0BEC5);
      for (final ex in [bx + bw * 0.30, bx + bw * 0.62]) {
        canvas.drawOval(
            Rect.fromLTWH(ex, by + bh * 0.35, bw * 0.09, bh * 0.4), ePaint);
        canvas.drawOval(
            Rect.fromLTWH(ex, by + bh * 0.35, bw * 0.09, bh * 0.4),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Colors.black54);
      }
      break;
  }
}
