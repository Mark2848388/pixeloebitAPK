import 'package:flutter/material.dart';

class PixSprite {
  final List<String> rows;
  final Map<String, Color> palette;
  const PixSprite(this.rows, this.palette);
  int get w => rows.isEmpty ? 0 : rows[0].length;
  int get h => rows.length;

  void paint(Canvas c, Offset center, double scale, {Color? flash}) {
    c.save();
    c.translate(center.dx, center.dy);
    final ox = -w * scale / 2;
    final oy = -h * scale / 2;
    final paint = Paint()..isAntiAlias = false;
    for (var j = 0; j < rows.length; j++) {
      final row = rows[j];
      for (var i = 0; i < row.length; i++) {
        final ch = row[i];
        if (ch == '.') continue;
        final col = flash ?? palette[ch];
        if (col == null) continue;
        paint.color = col;
        c.drawRect(Rect.fromLTWH(ox + i * scale, oy + j * scale, scale + 0.2, scale + 0.2), paint);
      }
    }
    c.restore();
  }
}

class PO {
  static const bg = Color(0xFF050818);
  static const panel = Color(0xFF0C1220);
  static const panel2 = Color(0xFF141C2E);
  static const border = Color(0xFF3A4A6A);
  static const accent = Color(0xFF5B8CFF);
  static const gold = Color(0xFFFFD34A);
  static const danger = Color(0xFFFF4A6A);
  static const ok = Color(0xFF4AFF9A);
  static const text = Color(0xFFE8EEFF);
  static const muted = Color(0xFF8A96B0);
}

TextStyle pixText({double size = 14, Color color = PO.text, FontWeight weight = FontWeight.w600}) =>
    TextStyle(fontFamily: 'monospace', fontSize: size, color: color, fontWeight: weight, letterSpacing: 0.4, height: 1.15);

void drawPanel(Canvas c, Rect r, {Color fill = PO.panel, Color border = PO.border, double thick = 2}) {
  final p = Paint()..isAntiAlias = false;
  p.color = fill;
  c.drawRect(r, p);
  p
    ..color = border
    ..style = PaintingStyle.stroke
    ..strokeWidth = thick;
  c.drawRect(r.deflate(1), p);
}

final shipRex = PixSprite([
  '....c....',
  '...ccc...',
  '..cwbwc..',
  '.cwwwwwc.',
  'ccwwwwwcc',
  'c.w...w.c',
  '..f...f..',
  '...f.f...',
], {'c': Color(0xFF4A7AFF), 'w': Color(0xFFD0E4FF), 'b': Color(0xFF1A2A4A), 'f': Color(0xFFFF8A3A)});

final shipNova = PixSprite([
  '....p....', '...ppp...', '..pwwp...', '.pwxxwp.', 'ppwwwwwpp', 'p.w...w.p', '..m...m..', '...m.m...',
], {'p': Color(0xFFFF60C0), 'w': Color(0xFFFFE0F4), 'x': Color(0xFF401030), 'm': Color(0xFFFF80FF)});

final shipBolt = PixSprite([
  '....y....', '...yyy...', '..ywwy...', '.ywwwwy..', 'yywzzwyy.', 'y.w...w.y', '..o...o..', '...o.o...',
], {'y': Color(0xFFFFB020), 'w': Color(0xFFFFF0C0), 'z': Color(0xFFFF6020), 'o': Color(0xFFFF4010)});

final shipAegis = PixSprite([
  '....g....', '...ggg...', '..gwwg...', '.gwwwwg..', 'ggwbbwgg.', 'g.w...w.g', '..s...s..', '...s.s...',
], {'g': Color(0xFF30C070), 'w': Color(0xFFE0FFE8), 'b': Color(0xFF104028), 's': Color(0xFF80FFC0)});

final shipShadow = PixSprite([
  '....v....', '...vvv...', '..vwwv...', '.vwxxwv.', 'vvwwwwwvv', 'v.w...w.v', '..d...d..', '...d.d...',
], {'v': Color(0xFF8A40E0), 'w': Color(0xFFE8D0FF), 'x': Color(0xFF201038), 'd': Color(0xFFC060FF)});

final enemySprite = PixSprite([
  '..rrrr..', '.rryyrr.', 'rryxxyrr', 'ryxxxxyr', '.rxxxxr.', '..r..r..', '.y....y.',
], {'r': Color(0xFFE04060), 'y': Color(0xFFFFB040), 'x': Color(0xFF2A1020)});

final enemy2Sprite = PixSprite([
  '...gg...', '..gwwg..', '.gwxxwg.', 'ggwxxwgg', '.gwwwwg.', '..g..g..', '.o....o.',
], {'g': Color(0xFF40C070), 'w': Color(0xFFE8FFE8), 'x': Color(0xFF103020), 'o': Color(0xFFFFA020)});

final bossP1 = PixSprite([
  '....RRRR....', '...RRYYRR...', '..RRYXXYRR..', '.RRYXXXXYRR.', 'RRYXXXXXXYRR', 'RYXXWBBWXXYR', '.RYXX..XXYR.', '..R.F..F.R..', '...F....F...',
], {'R': Color(0xFFB02040), 'Y': Color(0xFFFFD040), 'X': Color(0xFF301018), 'W': Color(0xFFFF6688), 'B': Color(0xFF80D0FF), 'F': Color(0xFFFF6020)});

final bossP2 = PixSprite([
  '...YYYYYY...', '..YYRRRRYY..', '.YYRXXXXRYY.', 'YYRXXXXXXRYY', 'YRXXWBBWXXRY', '.YRXX..XXRY.', '..Y.FF.FF.Y.', '...F....F...',
], {'Y': Color(0xFFFF4040), 'R': Color(0xFFFF8080), 'X': Color(0xFF400010), 'W': Color(0xFFFFFFFF), 'B': Color(0xFFFF2060), 'F': Color(0xFFFFA000)});

final bossP3 = PixSprite([
  '..WWWWWWWW..', '.WWRRRRRRWW.', 'WWRXXXXXXRWW', 'WRXXXXXXXXRW', 'WRXWW..WWXRW', '.WRX....XRW.', '..W.FFFF.W..', '...F....F...',
], {'W': Color(0xFFFFD040), 'R': Color(0xFFFF2060), 'X': Color(0xFF301000), 'F': Color(0xFFFFFFFF)});

PixSprite heroSprite(String id) {
  switch (id) {
    case 'nova': return shipNova;
    case 'bolt': return shipBolt;
    case 'aegis': return shipAegis;
    case 'shadow': return shipShadow;
    default: return shipRex;
  }
}
