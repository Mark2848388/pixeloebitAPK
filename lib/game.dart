import 'dart:math';
import 'package:flutter/material.dart';
import 'content.dart';
import 'pixel.dart';

enum EK { player, enemy, enemy2, boss, bullet, ebullet, spark, loot, rival }

class Ent {
  EK kind;
  double x, y, vx, vy, hp, maxHp, r, age;
  bool dead;
  int phase;
  Ent({
    required this.kind,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.hp = 1,
    this.maxHp = 1,
    this.r = 14,
    this.age = 0,
    this.dead = false,
    this.phase = 1,
  });
}

class GameWorld extends ChangeNotifier {
  final double w;
  double h;
  final rng = Random();

  late Ent player;
  final ents = <Ent>[];
  final stars = <Offset>[];

  int score = 0;
  double hp = 3; // fractional for regen
  double maxHp = 3;
  int wave = 0;
  bool gameOver = false, victory = false;
  double shake = 0, spawnT = 0.4, fireCd = 0;
  double dashCd = 0, ultCd = 0, dashT = 0, shieldT = 0;
  String banner = '';
  double bannerT = 0;
  int tick = 0;

  String mode, heroId, weapon;
  int worldId, wavesGoal;
  double fireRateMul, damageMul, speedMul, bossHpBonus;
  double dmgUp, rateUp, dashMul, ultMul, regenPerSec;
  double? tx, ty; // free 2D target

  // scale for bigger sprites
  static const shipScale = 4.2;
  static const enemyScale = 3.6;
  static const bossScale = 4.0;

  GameWorld({
    required this.w,
    required this.h,
    this.mode = 'classic',
    this.worldId = 0,
    this.wavesGoal = 0,
    this.bossHpBonus = 0,
    this.fireRateMul = 1,
    this.damageMul = 1,
    this.speedMul = 1,
    this.heroId = 'rex',
    this.weapon = 'pulse',
    this.dmgUp = 1,
    this.rateUp = 1,
    this.dashMul = 1,
    this.ultMul = 1,
    this.regenPerSec = 0,
    int bonusLives = 0,
  }) {
    maxHp = 3.0 + bonusLives;
    hp = maxHp;
    player = Ent(kind: EK.player, x: w / 2, y: h * 0.72, r: 18);
    for (var i = 0; i < 60; i++) {
      stars.add(Offset(rng.nextDouble() * w, rng.nextDouble() * h));
    }
    if (mode == 'arena') {
      ents.add(Ent(kind: EK.rival, x: w / 2, y: 100, hp: 16, maxHp: 16, r: 20));
      _ban('АРЕНА');
    } else {
      _wave(first: true);
    }
  }

  void resize(double nh) {
    if (nh <= 10) return;
    h = nh;
    player.y = player.y.clamp(40.0, h - 40.0);
  }

  void tryDash() {
    if (dashCd > 0 || gameOver) return;
    dashCd = 3.0 * dashMul;
    dashT = 0.2;
    shieldT = max(shieldT, 0.3);
    if (tx != null && ty != null) {
      final dx = tx! - player.x;
      final dy = ty! - player.y;
      final len = sqrt(dx * dx + dy * dy) + 0.01;
      player.x += dx / len * 70;
      player.y += dy / len * 70;
    } else {
      player.y -= 50;
    }
    player.x = player.x.clamp(24.0, w - 24.0);
    player.y = player.y.clamp(40.0, h - 40.0);
    _spark(player.x, player.y, 10);
    _ban('РЫВОК');
  }

  void tryUlt() {
    if (ultCd > 0 || gameOver) return;
    ultCd = 8.5 * ultMul;
    _ban('УЛЬТА');
    switch (heroId) {
      case 'nova':
        for (var i = -4; i <= 4; i++) {
          ents.add(Ent(kind: EK.bullet, x: player.x, y: player.y - 20, vx: i * 55.0, vy: -400, r: 4));
        }
      case 'aegis':
        shieldT = 4.5;
      case 'bolt':
        dashT = 0.55;
        shieldT = 2.2;
        speedMul *= 1.05;
      case 'shadow':
        shieldT = 2.8;
        for (var i = 0; i < 4; i++) {
          ents.add(Ent(kind: EK.bullet, x: player.x, y: player.y - 18, vy: -520.0 - i * 40, r: 3));
        }
      default:
        for (var i = 0; i < 6; i++) {
          ents.add(Ent(kind: EK.bullet, x: player.x + (i - 2.5) * 12, y: player.y - 16, vx: (i - 2.5) * 20, vy: -360 - i * 15.0, r: 5));
        }
    }
  }

  void update(double dt) {
    if (gameOver) {
      notifyListeners();
      return;
    }
    dt = dt.clamp(0.0, 0.05);
    if (dt <= 0) dt = 1 / 60;
    tick++;
    shake = (shake - dt * 8).clamp(0.0, 6.0);
    if (bannerT > 0) bannerT -= dt;
    dashCd = (dashCd - dt).clamp(0.0, 99);
    ultCd = (ultCd - dt).clamp(0.0, 99);
    if (dashT > 0) dashT -= dt;
    if (shieldT > 0) shieldT -= dt;

    // regen
    if (regenPerSec > 0 && hp < maxHp && shieldT <= 0) {
      hp = (hp + regenPerSec * dt).clamp(0.0, maxHp);
    }

    // free 2D move
    if (tx != null && ty != null) {
      final dx = tx! - player.x;
      final dy = ty! - player.y;
      final mul = speedMul * (dashT > 0 ? 2.4 : 1);
      player.x += (dx * 12 * mul * dt).clamp(-420 * mul * dt, 420 * mul * dt);
      player.y += (dy * 12 * mul * dt).clamp(-420 * mul * dt, 420 * mul * dt);
    }
    player.x = player.x.clamp(24.0, w - 24.0);
    player.y = player.y.clamp(48.0, h - 48.0);

    fireCd -= dt;
    final rate = (0.15 * fireRateMul * rateUp).clamp(0.06, 0.4);
    if (fireCd <= 0 && dashT <= 0) {
      fireCd = rate;
      _shot();
    }

    if (mode == 'arena') {
      _arena(dt);
    } else {
      final has = ents.any((e) => !e.dead && (e.kind == EK.enemy || e.kind == EK.enemy2 || e.kind == EK.boss));
      if (!has) {
        spawnT -= dt;
        if (spawnT <= 0) {
          spawnT = mode == 'endless' ? 0.35 : 0.7;
          _wave();
        }
      }
    }

    for (final e in ents) {
      if (e.dead) continue;
      e.age += dt;
      e.x += e.vx * dt;
      e.y += e.vy * dt;
      if (e.kind == EK.enemy || e.kind == EK.enemy2) {
        if (e.x < 20) {
          e.x = 20;
          e.vx = e.vx.abs();
        } else if (e.x > w - 20) {
          e.x = w - 20;
          e.vx = -e.vx.abs();
        }
        if (e.y > h + 50) e.dead = true;
        if (rng.nextDouble() < 0.008) {
          ents.add(Ent(kind: EK.ebullet, x: e.x, y: e.y + 12, vy: 180 + wave * 8.0, r: 4));
        }
      }
      if (e.kind == EK.boss) _boss(e, dt);
      if (e.kind == EK.bullet && (e.y < -40 || e.x < -30 || e.x > w + 30)) e.dead = true;
      if (e.kind == EK.ebullet && (e.y > h + 30 || e.y < -40)) e.dead = true;
      if (e.kind == EK.spark && e.age > 0.35) e.dead = true;
      if (e.kind == EK.loot && e.y > h + 20) e.dead = true;
    }

    for (final b in ents.where((e) => !e.dead && e.kind == EK.bullet)) {
      for (final en in ents.where((e) => !e.dead && (e.kind == EK.enemy || e.kind == EK.enemy2 || e.kind == EK.boss || e.kind == EK.rival))) {
        if (_hit(b, en)) {
          b.dead = true;
          en.hp -= damageMul * dmgUp;
          _spark(en.x, en.y);
          if (en.hp <= 0) {
            en.dead = true;
            _kill(en);
          }
          break;
        }
      }
    }

    for (final L in ents.where((e) => !e.dead && e.kind == EK.loot)) {
      if (_hit(L, player)) {
        L.dead = true;
        score += 25;
        _spark(player.x, player.y, 4);
      }
    }

    if (shieldT <= 0) {
      for (final e in ents.where((e) => !e.dead && (e.kind == EK.ebullet || e.kind == EK.enemy || e.kind == EK.enemy2 || e.kind == EK.boss || e.kind == EK.rival))) {
        if (_hit(e, player)) {
          if (e.kind == EK.ebullet) e.dead = true;
          hp -= 1;
          shake = 5;
          shieldT = 1.1;
          _spark(player.x, player.y, 12);
          if (e.kind != EK.ebullet && e.kind != EK.boss) e.y = -60;
          if (hp <= 0) {
            hp = 0;
            gameOver = true;
            _ban('GAME OVER');
          }
          break;
        }
      }
    }

    if (mode == 'campaign' && !victory && wavesGoal > 0) {
      final has = ents.any((e) => !e.dead && (e.kind == EK.enemy || e.kind == EK.enemy2 || e.kind == EK.boss));
      if (wave >= wavesGoal && !has) {
        victory = true;
        gameOver = true;
        score += 150 + worldId * 50;
        _ban('ПОБЕДА');
      }
    }
    if (mode == 'arena' && !gameOver && !ents.any((e) => !e.dead && e.kind == EK.rival)) {
      victory = true;
      gameOver = true;
      score += 220;
      _ban('ПОБЕДА АРЕНЫ');
    }

    ents.removeWhere((e) => e.dead);
    for (var i = 0; i < stars.length; i++) {
      var ny = stars[i].dy + 35 * dt;
      if (ny > h) ny -= h;
      stars[i] = Offset(stars[i].dx, ny);
    }
    notifyListeners();
  }

  void _shot() {
    void b(double ox, double oy, double vx, double vy, [double r = 4]) =>
        ents.add(Ent(kind: EK.bullet, x: player.x + ox, y: player.y + oy, vx: vx, vy: vy, r: r));
    switch (weapon) {
      case 'spread':
        b(-12, -18, -50, -400);
        b(0, -22, 0, -430);
        b(12, -18, 50, -400);
      case 'beam':
        b(0, -20, 0, -520, 5);
        b(0, -8, 0, -520, 4);
      case 'rail':
        b(0, -20, 0, -620, 3);
      default:
        b(0, -20, 0, -460);
    }
  }

  void _wave({bool first = false}) {
    wave++;
    final n = first ? 4 : 3 + min(wave, 10);
    for (var i = 0; i < n; i++) {
      final elite = wave > 2 && rng.nextDouble() < 0.3;
      ents.add(Ent(
        kind: elite ? EK.enemy2 : EK.enemy,
        x: 40 + rng.nextDouble() * (w - 80),
        y: first ? 50.0 + i * 40 : -30.0 - rng.nextDouble() * 80,
        vy: 55 + wave * 6.0 + rng.nextDouble() * 30,
        vx: (rng.nextDouble() - 0.5) * 50,
        hp: elite ? 4 : 1,
        maxHp: elite ? 4 : 1,
        r: elite ? 22 : 18,
      ));
    }
    if (wave % 4 == 0 || (mode == 'campaign' && wave == wavesGoal)) {
      final hp0 = (bossHpBonus > 0 ? bossHpBonus : 35 + wave * 10).toDouble();
      ents.add(Ent(kind: EK.boss, x: w / 2, y: -40, vy: 24, hp: hp0, maxHp: hp0, r: 32, phase: 1));
      _ban('БОСС');
    }
  }

  void _boss(Ent e, double dt) {
    final ratio = e.hp / e.maxHp;
    final ph = ratio > 0.66 ? 1 : ratio > 0.33 ? 2 : 3;
    if (ph != e.phase) {
      e.phase = ph;
      _ban('ФАЗА $ph');
      shake = 4;
    }
    if (e.y < 90) e.y += 20 * dt;
    e.x += sin(e.age * (1.4 + e.phase * 0.5)) * (40 + e.phase * 18) * dt;
    e.x = e.x.clamp(50.0, w - 50.0);
    if (rng.nextDouble() < 0.02 + e.phase * 0.012) {
      for (var i = 0; i < e.phase; i++) {
        ents.add(Ent(kind: EK.ebullet, x: e.x + (i - e.phase / 2) * 14, y: e.y + 20, vy: 150 + e.phase * 35.0, vx: (rng.nextDouble() - 0.5) * 50 * e.phase, r: 5));
      }
    }
  }

  void _arena(double dt) {
    for (final e in ents.where((e) => !e.dead && e.kind == EK.rival)) {
      final dx = player.x - e.x;
      final dy = player.y - e.y;
      e.x += dx.sign * 70 * dt;
      e.y += dy.sign * 25 * dt;
      e.x = e.x.clamp(40.0, w - 40.0);
      e.y = e.y.clamp(60.0, h * 0.45);
      if (rng.nextDouble() < 0.025) {
        ents.add(Ent(kind: EK.ebullet, x: e.x, y: e.y + 14, vy: 200, r: 4));
      }
    }
  }

  void _kill(Ent en) {
    score += en.kind == EK.boss ? 320 : en.kind == EK.rival ? 200 : en.kind == EK.enemy2 ? 50 : 20;
    shake = en.kind == EK.boss ? 5 : 2;
    if (rng.nextDouble() < 0.55) {
      ents.add(Ent(kind: EK.loot, x: en.x, y: en.y, vy: 55, r: 10));
    }
  }

  bool _hit(Ent a, Ent b) {
    final dx = a.x - b.x, dy = a.y - b.y, r = a.r + b.r;
    return dx * dx + dy * dy < r * r;
  }

  void _spark(double x, double y, [int n = 6]) {
    for (var i = 0; i < n; i++) {
      ents.add(Ent(kind: EK.spark, x: x, y: y, vx: (rng.nextDouble() - 0.5) * 160, vy: (rng.nextDouble() - 0.5) * 160, r: 3));
    }
  }

  void _ban(String t) {
    banner = t;
    bannerT = 1.3;
  }

  void paint(Canvas c, Size size) {
    final sx = size.width / w, sy = size.height / h;
    c.save();
    c.scale(sx, sy);
    if (shake > 0) c.translate((rng.nextDouble() - 0.5) * shake * 2, (rng.nextDouble() - 0.5) * shake * 2);
    c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = PO.bg);
    final sp = Paint()..color = const Color(0xFF8A9AB8);
    for (final s in stars) {
      c.drawRect(Rect.fromCenter(center: s, width: 2, height: 2), sp);
    }

    for (final e in ents) {
      switch (e.kind) {
        case EK.bullet:
          c.drawRect(Rect.fromCenter(center: Offset(e.x, e.y), width: 4, height: 12), Paint()..color = const Color(0xFF80D0FF));
        case EK.ebullet:
          c.drawRect(Rect.fromCenter(center: Offset(e.x, e.y), width: 6, height: 6), Paint()..color = const Color(0xFFFF6080));
        case EK.spark:
          c.drawRect(Rect.fromCenter(center: Offset(e.x, e.y), width: 4, height: 4), Paint()..color = PO.gold);
        case EK.enemy:
          enemySprite.paint(c, Offset(e.x, e.y), enemyScale);
        case EK.enemy2:
          enemy2Sprite.paint(c, Offset(e.x, e.y), enemyScale);
        case EK.boss:
          final spb = e.phase >= 3 ? bossP3 : e.phase == 2 ? bossP2 : bossP1;
          spb.paint(c, Offset(e.x, e.y), bossScale);
          final bw = 80.0;
          c.drawRect(Rect.fromLTWH(e.x - bw / 2, e.y - 42, bw, 6), Paint()..color = const Color(0xFF301018));
          c.drawRect(Rect.fromLTWH(e.x - bw / 2, e.y - 42, bw * (e.hp / e.maxHp).clamp(0, 1), 6), Paint()..color = PO.danger);
        case EK.rival:
          enemy2Sprite.paint(c, Offset(e.x, e.y), enemyScale + 0.4);
          final bw = 70.0;
          c.drawRect(Rect.fromLTWH(e.x - bw / 2, e.y - 36, bw, 5), Paint()..color = const Color(0xFF201810));
          c.drawRect(Rect.fromLTWH(e.x - bw / 2, e.y - 36, bw * (e.hp / e.maxHp).clamp(0, 1), 5), Paint()..color = PO.gold);
        case EK.loot:
          c.drawRect(Rect.fromCenter(center: Offset(e.x, e.y), width: 12, height: 12), Paint()..color = PO.gold);
        default:
          break;
      }
    }

    final flash = shieldT > 0 && tick % 4 < 2 ? Colors.white24 : null;
    heroSprite(heroId).paint(c, Offset(player.x, player.y), shipScale, flash: flash);

    // === HUD bottom-safe: HP bar top with padding ===
    const hudTop = 36.0;
    drawPanel(c, const Rect.fromLTWH(8, hudTop, 160, 44), fill: PO.panel.withOpacity(0.85), border: PO.border);
    // HP bar
    c.drawRect(const Rect.fromLTWH(16, hudTop + 10, 120, 10), Paint()..color = const Color(0xFF3A2030));
    c.drawRect(Rect.fromLTWH(16, hudTop + 10, 120 * (hp / maxHp).clamp(0, 1), 10), Paint()..color = PO.danger);
    _txt(c, 'HP ${hp.toStringAsFixed(1)}/${maxHp.toStringAsFixed(0)}', 16, hudTop + 26);
    _txt(c, 'SC $score  W$wave', 180, hudTop + 12);
    if (regenPerSec > 0) _txt(c, 'REGEN', 180, hudTop + 28);

    // ability CD bottom
    drawPanel(c, Rect.fromLTWH(8, h - 40, 100, 28), fill: PO.panel2, border: dashCd > 0 ? PO.border : PO.ok);
    _txt(c, dashCd > 0 ? 'DASH ${dashCd.toStringAsFixed(1)}' : 'DASH', 16, h - 32);
    drawPanel(c, Rect.fromLTWH(116, h - 40, 100, 28), fill: PO.panel2, border: ultCd > 0 ? PO.border : PO.ok);
    _txt(c, ultCd > 0 ? 'ULT ${ultCd.toStringAsFixed(1)}' : 'ULT', 124, h - 32);

    if (bannerT > 0) {
      final box = Rect.fromCenter(center: Offset(w / 2, h * 0.22), width: 200, height: 34);
      drawPanel(c, box, border: PO.gold);
      _txt(c, banner, w / 2 - banner.length * 4.2, h * 0.22 - 6);
    }
    if (gameOver) {
      final box = Rect.fromCenter(center: Offset(w / 2, h / 2), width: 250, height: 110);
      drawPanel(c, box, border: victory ? PO.gold : PO.danger);
      _txt(c, victory ? 'ПОБЕДА' : 'GAME OVER', w / 2 - 42, h / 2 - 28);
      _txt(c, 'Score $score', w / 2 - 36, h / 2);
      _txt(c, 'Tap = меню', w / 2 - 40, h / 2 + 26);
    }
    c.restore();
  }

  void _txt(Canvas c, String t, double x, double y) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFE8EEFF), fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x, y));
  }
}
