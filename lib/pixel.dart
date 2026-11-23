import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Tiny pixel-map sprite. Digits 0-9 map into [palette]; `.` = empty.
class PixSprite {
  final List<String> rows;
  final Map<String, Color> palette;
  const PixSprite(this.rows, this.palette);

  int get w => rows.isEmpty ? 0 : rows[0].length;
  int get h => rows.length;

  void paint(Canvas c, Offset center, double scale, {Color? flash}) {
    final pw = w * scale;
    final ph = h * scale;
    final ox = center.dx - pw / 2;
    final oy = center.dy - ph / 2;
    final paint = Paint()..isAntiAlias = false;
    for (var j = 0; j < rows.length; j++) {
      final row = rows[j];
      for (var i = 0; i < row.length; i++) {
        final ch = row[i];
        if (ch == '.') continue;
        final col = flash ?? palette[ch];
        if (col == null) continue;
        paint.color = col;
        c.drawRect(
          Rect.fromLTWH(ox + i * scale, oy + j * scale, scale + 0.2, scale + 0.2),
          paint,
        );
      }
    }
  }
}

/// Shared 16-bit-ish palette
class PO {
  static const bg = Color(0xFF050818);
  static const panel = Color(0xFF0E1528);
  static const border = Color(0xFF3A4A6A);
  static const accent = Color(0xFF5B8CFF);
  static const gold = Color(0xFFFFD34A);
  static const danger = Color(0xFFFF4A6A);
  static const ok = Color(0xFF4AFF9A);
  static const text = Color(0xFFE8EEFF);
  static const muted = Color(0xFF8A96B0);
}

final shipSprite = PixSprite(
  const [
    '....c....',
    '...ccc...',
    '..cwbwc..',
    '.cwwwwwc.',
    'ccwwwwwcc',
    'c.w...w.c',
    '..f...f..',
    '...f.f...',
  ],
  {
    'c': Color(0xFF4A7AFF),
    'w': Color(0xFFD0E4FF),
    'b': Color(0xFF1A2A4A),
    'f': Color(0xFFFF8A3A),
  },
);

final enemySprite = PixSprite(
  const [
    '..rrrr..',
    '.rryyrr.',
    'rryxxyrr',
    'ryxxxxyr',
    '.rxxxxr.',
    '..r..r..',
    '.y....y.',
  ],
  {
    'r': Color(0xFFE04060),
    'y': Color(0xFFFFB040),
    'x': Color(0xFF2A1020),
  },
);

final enemy2Sprite = PixSprite(
  const [
    '...gg...',
    '..gwwg..',
    '.gwxxwg.',
    'ggwxxwgg',
    '.gwwwwg.',
    '..g..g..',
    '.o....o.',
  ],
  {
    'g': Color(0xFF40C070),
    'w': Color(0xFFE8FFE8),
    'x': Color(0xFF103020),
    'o': Color(0xFFFFA020),
  },
);

final bossSprite = PixSprite(
  const [
    '....RRRR....',
    '...RRYYRR...',
    '..RRYXXYRR..',
    '.RRYXXXXYRR.',
    'RRYXXXXXXYRR',
    'RYXXWBBWXXYR',
    '.RYXX..XXYR.',
    '..R.F..F.R..',
    '...F....F...',
  ],
  {
    'R': Color(0xFFB02040),
    'Y': Color(0xFFFFD040),
    'X': Color(0xFF301018),
    'W': Color(0xFFFF6688),
    'B': Color(0xFF80D0FF),
    'F': Color(0xFFFF6020),
  },
);

final starSprite = PixSprite(
  const ['.w.', 'www', '.w.'],
  {'w': Color(0xFFAAB8E0)},
);

/// Pixel-looking text via monospace + slight tracking.
TextStyle pixText({
  double size = 14,
  Color color = PO.text,
  FontWeight weight = FontWeight.w600,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: 0.6,
    height: 1.1,
  );
}

void drawPanel(Canvas c, Rect r, {Color fill = PO.panel, Color border = PO.border}) {
  final p = Paint()..isAntiAlias = false;
  p.color = fill;
  c.drawRect(r, p);
  p
    ..color = border
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  c.drawRect(r.deflate(1), p);
  // corner pixels
  p.style = PaintingStyle.fill;
  p.color = PO.accent.withOpacity(0.5);
  const s = 3.0;
  c.drawRect(Rect.fromLTWH(r.left, r.top, s, s), p);
  c.drawRect(Rect.fromLTWH(r.right - s, r.top, s, s), p);
  c.drawRect(Rect.fromLTWH(r.left, r.bottom - s, s, s), p);
  c.drawRect(Rect.fromLTWH(r.right - s, r.bottom - s, s, s), p);
}

/// Scale UI to a logical 360-wide pixel stage.
Size stageSize(Size screen) {
  const designW = 360.0;
  final scale = screen.width / designW;
  return Size(designW, screen.height / scale);
}

ui.Image? cachedNoise;

Future<void> ensureNoise() async {
  // optional later
}
