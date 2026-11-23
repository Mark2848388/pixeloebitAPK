import 'dart:math';
import 'package:flutter/material.dart';

/// Vector (geometric) ships / enemies — cleaner look than pure pixel maps.
class VDraw {
  static Path _shipBody(double s) {
    final p = Path();
    // nose up
    p.moveTo(0, -s);
    p.lineTo(s * 0.55, s * 0.15);
    p.lineTo(s * 0.28, s * 0.2);
    p.lineTo(s * 0.35, s * 0.65);
    p.lineTo(0, s * 0.35);
    p.lineTo(-s * 0.35, s * 0.65);
    p.lineTo(-s * 0.28, s * 0.2);
    p.lineTo(-s * 0.55, s * 0.15);
    p.close();
    return p;
  }

  static void ship(Canvas c, Offset o, double s, Color body, {Color? glow, bool engine = true}) {
    c.save();
    c.translate(o.dx, o.dy);
    if (glow != null) {
      c.drawCircle(Offset.zero, s * 1.15, Paint()..color = glow.withOpacity(0.18));
    }
    final fill = Paint()
      ..color = body
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    final path = _shipBody(s);
    c.drawPath(path, fill);
    c.drawPath(path, stroke);
    // cockpit
    c.drawCircle(Offset(0, -s * 0.15), s * 0.18, Paint()..color = Colors.white.withOpacity(0.85));
    c.drawCircle(Offset(0, -s * 0.15), s * 0.1, Paint()..color = const Color(0xFF80D0FF));
    if (engine) {
      final flame = Path()
        ..moveTo(-s * 0.12, s * 0.45)
        ..lineTo(0, s * 0.85 + Random().nextDouble() * s * 0.15)
        ..lineTo(s * 0.12, s * 0.45)
        ..close();
      c.drawPath(flame, Paint()..color = const Color(0xFFFF8A3A));
      c.drawPath(flame, Paint()..color = const Color(0xFFFFE080)..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    c.restore();
  }

  static void enemy(Canvas c, Offset o, double s, Color body) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(pi); // face down
    final p = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.7, -s * 0.2)
      ..lineTo(s * 0.5, s * 0.5)
      ..lineTo(0, s * 0.25)
      ..lineTo(-s * 0.5, s * 0.5)
      ..lineTo(-s * 0.7, -s * 0.2)
      ..close();
    c.drawPath(p, Paint()..color = body);
    c.drawPath(p, Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.2);
    c.drawCircle(Offset(0, -s * 0.15), s * 0.2, Paint()..color = const Color(0xFFFFEE88));
    c.drawCircle(Offset(0, -s * 0.15), s * 0.1, Paint()..color = const Color(0xFFFF4040));
    c.restore();
  }

  static void elite(Canvas c, Offset o, double s, Color body) {
    c.save();
    c.translate(o.dx, o.dy);
    // hex body
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3;
      final pt = Offset(cos(a) * s, sin(a) * s * 0.85);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    c.drawPath(p, Paint()..color = body);
    c.drawPath(p, Paint()..color = Colors.white30..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset.zero, s * 0.28, Paint()..color = const Color(0xFF103020));
    c.drawCircle(Offset.zero, s * 0.14, Paint()..color = const Color(0xFF80FFC0));
    c.restore();
  }

  static void boss(Canvas c, Offset o, double s, int phase) {
    c.save();
    c.translate(o.dx, o.dy);
    final colors = [
      const Color(0xFFB02040),
      const Color(0xFFFF4040),
      const Color(0xFFFFD040),
    ];
    final col = colors[(phase - 1).clamp(0, 2)];
    // layered diamond
    for (var ring = 3; ring >= 1; ring--) {
      final rs = s * (0.45 + ring * 0.25);
      final p = Path()
        ..moveTo(0, -rs)
        ..lineTo(rs * 0.85, 0)
        ..lineTo(0, rs * 0.7)
        ..lineTo(-rs * 0.85, 0)
        ..close();
      c.drawPath(
        p,
        Paint()
          ..color = col.withOpacity(0.35 + ring * 0.2)
          ..style = ring == 1 ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // core
    c.drawCircle(Offset.zero, s * 0.22, Paint()..color = Colors.white.withOpacity(0.9));
    c.drawCircle(Offset.zero, s * 0.12, Paint()..color = col);
    // wings
    final wing = Paint()..color = col.withOpacity(0.8);
    c.drawPath(
      Path()
        ..moveTo(-s * 0.2, 0)
        ..lineTo(-s * 1.2, -s * 0.3)
        ..lineTo(-s * 0.9, s * 0.2)
        ..close(),
      wing,
    );
    c.drawPath(
      Path()
        ..moveTo(s * 0.2, 0)
        ..lineTo(s * 1.2, -s * 0.3)
        ..lineTo(s * 0.9, s * 0.2)
        ..close(),
      wing,
    );
    c.restore();
  }

  static void bullet(Canvas c, Offset o, {bool enemy = false}) {
    final col = enemy ? const Color(0xFFFF6080) : const Color(0xFF80E0FF);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: o, width: enemy ? 7 : 5, height: enemy ? 7 : 14),
        const Radius.circular(2),
      ),
      Paint()..color = col,
    );
    if (!enemy) {
      c.drawCircle(o + const Offset(0, 4), 3, Paint()..color = col.withOpacity(0.35));
    }
  }

  static void loot(Canvas c, Offset o, double t) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(t * 2);
    final p = Path()
      ..moveTo(0, -8)
      ..lineTo(8, 0)
      ..lineTo(0, 8)
      ..lineTo(-8, 0)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFFFFD34A));
    c.drawPath(p, Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 1);
    c.restore();
  }
}
