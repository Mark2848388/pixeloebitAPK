import 'dart:math';
import 'package:flutter/material.dart';
import 'content.dart';
import 'pixel.dart';

enum EntityKind {
  player,
  enemy,
  enemy2,
  boss,
  bullet,
  ebullet,
  spark,
  lootCoin,
  lootGem,
  lootScrap,
  allyBullet,
}

class Entity {
  EntityKind kind;
  double x, y, vx, vy, hp, radius, age, maxHp;
  bool dead;
  int phase; // boss
  Entity({
    required this.kind,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.hp = 1,
    this.maxHp = 1,
    this.radius = 10,
    this.age = 0,
    this.dead = false,
    this.phase = 1,
  });
}

class GameWorld extends ChangeNotifier {
  final double w;
  double h;
  final Random rng = Random();

  late Entity player;
  final List<Entity> entities = [];
  int score = 0;
  int lives = 3;
  int wave = 0;
  double spawnTimer = 0;
  double fireCooldown = 0;
  bool gameOver = false;
  bool victory = false;
  double shake = 0;
  final List<Offset> stars = [];

  String mode; // classic | endless | campaign | arena
  int worldId;
  int wavesGoal;
  double bossHpBonus;
  double fireRateMul;
  double damageMul;
  double speedMul;
  int bonusLives;
  String heroId;
  String weapon;
  double dmgUpgrade;
  double rateUpgrade;
  double dashCdMul;
  double ultCdMul;

  // abilities
  double dashCd = 0;
  double ultCd = 0;
  double dashTimer = 0; // active dash
  double shieldTimer = 0;
  double ultTimer = 0;
  bool invisible = false;

  // arena AI
  Entity? rival;
  double rivalFire = 0;

  double? targetX;
  bool firing = true;
  int tick = 0;
  String banner = '';
  double bannerT = 0;

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
    this.bonusLives = 0,
    this.heroId = 'rex',
    this.weapon = 'pulse',
    this.dmgUpgrade = 1,
    this.rateUpgrade = 1,
    this.dashCdMul = 1,
    this.ultCdMul = 1,
  }) {
    lives = 3 + bonusLives;
    player = Entity(kind: EntityKind.player, x: w / 2, y: h - 80, radius: 12, hp: 1, maxHp: 1);
    for (var i = 0; i < 55; i++) {
      stars.add(Offset(rng.nextDouble() * w, rng.nextDouble() * h));
    }
    if (mode == 'arena') {
      rival = Entity(kind: EntityKind.enemy2, x: w / 2, y: 80, radius: 14, hp: 12, maxHp: 12, vy: 0);
      entities.add(rival!);
      banner = 'АРЕНА';
      bannerT = 2;
    } else {
      _nextWave(first: true);
    }
  }

  void resize(double nh) {
    if (nh <= 0 || (nh - h).abs() < 1) return;
    h = nh;
    if (player.y > h - 40) player.y = h - 80;
  }

  void tryDash() {
    if (dashCd > 0 || gameOver) return;
    dashCd = 3.2 * dashCdMul;
    dashTimer = 0.22;
    // invuln brief
    shieldTimer = max(shieldTimer, 0.25);
    // move toward target or up
    final dir = targetX != null ? (targetX! - player.x).sign : 0.0;
    player.x += dir * 55;
    player.x = player.x.clamp(20.0, w - 20.0);
    _spark(player.x, player.y, n: 8);
    banner = 'РЫВОК';
    bannerT = 0.6;
  }

  void tryUlt() {
    if (ultCd > 0 || gameOver) return;
    ultCd = 9.0 * ultCdMul;
    ultTimer = 0.5;
    banner = () { final xs = heroes.where((e) => e.id == heroId).toList(); return xs.isEmpty ? null : xs.first.ultName; }() ?? 'УЛЬТА';
    bannerT = 1.0;
    switch (heroId) {
      case 'nova':
        for (var i = -3; i <= 3; i++) {
          entities.add(Entity(
            kind: EntityKind.bullet,
            x: player.x,
            y: player.y - 16,
            vx: i * 70.0,
            vy: -420,
            radius: 3,
            hp: 1,
          ));
        }
      case 'bolt':
        dashTimer = 0.5;
        shieldTimer = 2.0;
        speedMul *= 1.0; // visual only; dash active
      case 'aegis':
        shieldTimer = 4.0;
      case 'shadow':
        invisible = true;
        ultTimer = 3.0;
        damageMul *= 1.0;
      default: // rex rockets
        for (var i = 0; i < 5; i++) {
          entities.add(Entity(
            kind: EntityKind.bullet,
            x: player.x + (i - 2) * 10,
            y: player.y - 12,
            vy: -380 - i * 20,
            vx: (i - 2) * 25.0,
            radius: 4,
            hp: 2,
          ));
        }
    }
  }

  void _nextWave({bool first = false}) {
    wave++;
    final count = first ? 4 : 3 + wave;
    for (var i = 0; i < count; i++) {
      final elite = wave > 2 && rng.nextDouble() < 0.28;
      final startY = first ? (30.0 + i * 32.0) : (-20.0 - rng.nextDouble() * 90);
      entities.add(Entity(
        kind: elite ? EntityKind.enemy2 : EntityKind.enemy,
        x: 36 + rng.nextDouble() * (w - 72),
        y: startY,
        vy: 65 + wave * 7 + rng.nextDouble() * 35,
        vx: (rng.nextDouble() - 0.5) * 55,
        hp: elite ? 3 : 1,
        maxHp: elite ? 3 : 1,
        radius: elite ? 14 : 12,
      ));
    }
    if (wave % 4 == 0 || (mode == 'campaign' && wave == wavesGoal)) {
      final hp = (bossHpBonus > 0 ? bossHpBonus : 30 + wave * 8).toDouble();
      entities.add(Entity(
        kind: EntityKind.boss,
        x: w / 2,
        y: -50,
        vy: 28,
        hp: hp,
        maxHp: hp,
        radius: 24,
        phase: 1,
      ));
      banner = 'БОСС';
      bannerT = 1.5;
    }
  }

  void update(double dt) {
    if (gameOver) return;
    if (dt <= 0) dt = 1 / 60;
    if (dt > 0.05) dt = 0.05;
    tick++;
    shake = (shake - dt * 8).clamp(0.0, 6.0);
    if (bannerT > 0) bannerT -= dt;
    dashCd = (dashCd - dt).clamp(0.0, 99);
    ultCd = (ultCd - dt).clamp(0.0, 99);
    if (dashTimer > 0) dashTimer -= dt;
    if (shieldTimer > 0) shieldTimer -= dt;
    if (ultTimer > 0) {
      ultTimer -= dt;
      if (ultTimer <= 0) invisible = false;
    }

    // move
    if (targetX != null) {
      final dx = targetX! - player.x;
      final mul = speedMul * (dashTimer > 0 ? 2.2 : 1);
      player.x += (dx * 14 * mul * dt).clamp(-480 * mul * dt, 480 * mul * dt);
    }
    player.x = player.x.clamp(18.0, w - 18.0);

    // fire
    fireCooldown -= dt;
    final rate = 0.16 * fireRateMul * rateUpgrade;
    if (firing && fireCooldown <= 0 && dashTimer <= 0) {
      fireCooldown = rate.clamp(0.06, 0.4);
      _playerShot();
    }

    if (mode == 'arena') {
      _updateArena(dt);
    } else {
      final hasEnemy = entities.any((e) =>
          !e.dead &&
          (e.kind == EntityKind.enemy || e.kind == EntityKind.enemy2 || e.kind == EntityKind.boss));
      if (!hasEnemy) {
        spawnTimer -= dt;
        if (spawnTimer <= 0) {
          spawnTimer = mode == 'endless' ? 0.4 : 0.75;
          _nextWave();
        }
      }
      if (mode == 'endless' && tick % 90 == 0) {
        entities.add(Entity(
          kind: EntityKind.enemy,
          x: 40 + rng.nextDouble() * (w - 80),
          y: -20,
          vy: 90 + wave * 8,
          vx: (rng.nextDouble() - 0.5) * 50,
          hp: 1,
          maxHp: 1,
          radius: 12,
        ));
      }
    }

    for (final e in entities) {
      if (e.dead) continue;
      e.age += dt;
      e.x += e.vx * dt;
      e.y += e.vy * dt;

      if (e.kind == EntityKind.enemy || e.kind == EntityKind.enemy2) {
        if (e.x < 16) {
          e.x = 16;
          e.vx = e.vx.abs();
        } else if (e.x > w - 16) {
          e.x = w - 16;
          e.vx = -e.vx.abs();
        }
        if (e.y > h + 40) e.dead = true;
        if (rng.nextDouble() < 0.007 + wave * 0.0005) {
          entities.add(Entity(kind: EntityKind.ebullet, x: e.x, y: e.y + 10, vy: 170 + wave * 8, radius: 3));
        }
      }

      if (e.kind == EntityKind.boss) {
        _updateBoss(e, dt);
      }

      if (e.kind == EntityKind.bullet && (e.y < -40 || e.x < -20 || e.x > w + 20)) e.dead = true;
      if (e.kind == EntityKind.ebullet && e.y > h + 30) e.dead = true;
      if (e.kind == EntityKind.spark && e.age > 0.35) e.dead = true;
      if ((e.kind == EntityKind.lootCoin || e.kind == EntityKind.lootGem || e.kind == EntityKind.lootScrap) && e.y > h + 20) {
        e.dead = true;
      }
    }

    // collisions bullets -> enemies
    for (final b in entities.where((e) => !e.dead && e.kind == EntityKind.bullet)) {
      for (final en in entities.where((e) =>
          !e.dead &&
          (e.kind == EntityKind.enemy || e.kind == EntityKind.enemy2 || e.kind == EntityKind.boss))) {
        if (_hit(b, en)) {
          b.dead = true;
          final dmg = (damageMul * dmgUpgrade) * (invisible ? 1.5 : 1) * (b.hp > 1 ? 2 : 1);
          en.hp -= dmg;
          _spark(en.x, en.y);
          if (en.hp <= 0) {
            en.dead = true;
            _onKill(en);
          }
          break;
        }
      }
    }

    // loot pickup
    for (final L in entities.where((e) =>
        !e.dead &&
        (e.kind == EntityKind.lootCoin || e.kind == EntityKind.lootGem || e.kind == EntityKind.lootScrap))) {
      if (_hit(L, player)) {
        L.dead = true;
        if (L.kind == EntityKind.lootCoin) score += 15;
        if (L.kind == EntityKind.lootGem) score += 40;
        if (L.kind == EntityKind.lootScrap) score += 10;
        _spark(player.x, player.y, n: 3);
      }
    }

    // damage to player
    if (shieldTimer <= 0 && !invisible) {
      for (final e in entities.where((e) =>
          !e.dead &&
          (e.kind == EntityKind.ebullet ||
              e.kind == EntityKind.enemy ||
              e.kind == EntityKind.enemy2 ||
              e.kind == EntityKind.boss))) {
        if (_hit(e, player)) {
          if (e.kind == EntityKind.ebullet) e.dead = true;
          lives -= 1;
          shake = 5;
          shieldTimer = 1.0;
          _spark(player.x, player.y, n: 10);
          if (e.kind != EntityKind.ebullet && e.kind != EntityKind.boss) {
            e.y = -50;
          }
          if (lives <= 0) {
            lives = 0;
            gameOver = true;
            banner = mode == 'arena' ? 'ПОРАЖЕНИЕ' : 'GAME OVER';
            bannerT = 3;
          }
          break;
        }
      }
    }

    // campaign win
    if (mode == 'campaign' && !victory && wavesGoal > 0) {
      final hasEnemy = entities.any((e) =>
          !e.dead &&
          (e.kind == EntityKind.enemy || e.kind == EntityKind.enemy2 || e.kind == EntityKind.boss));
      if (wave >= wavesGoal && !hasEnemy) {
        victory = true;
        gameOver = true;
        score += 150 + worldId * 60;
        banner = 'ПОБЕДА';
        bannerT = 3;
      }
    }

    // arena win
    if (mode == 'arena' && rival != null && rival!.dead && !gameOver) {
      victory = true;
      gameOver = true;
      score += 200;
      banner = 'ПОБЕДА АРЕНЫ';
      bannerT = 3;
    }

    entities.removeWhere((e) => e.dead);

    for (var i = 0; i < stars.length; i++) {
      var ny = stars[i].dy + 40 * dt;
      if (ny > h) ny -= h;
      stars[i] = Offset(stars[i].dx, ny);
    }

    notifyListeners();
  }

  void _playerShot() {
    void bolt(double ox, double oy, double vx, double vy, {double r = 3}) {
      entities.add(Entity(kind: EntityKind.bullet, x: player.x + ox, y: player.y + oy, vx: vx, vy: vy, radius: r));
    }

    switch (weapon) {
      case 'spread':
        bolt(-8, -14, -40, -400);
        bolt(0, -16, 0, -420);
        bolt(8, -14, 40, -400);
      case 'beam':
        bolt(0, -18, 0, -520, r: 4);
        bolt(0, -8, 0, -520, r: 3);
      case 'rail':
        bolt(0, -16, 0, -600, r: 2);
      default:
        bolt(0, -16, 0, -450);
    }
  }

  void _updateBoss(Entity e, double dt) {
    // phases at 66% and 33%
    final ratio = e.hp / e.maxHp;
    final newPhase = ratio > 0.66 ? 1 : ratio > 0.33 ? 2 : 3;
    if (newPhase != e.phase) {
      e.phase = newPhase;
      banner = 'ФАЗА ${e.phase}';
      bannerT = 1.2;
      shake = 4;
    }
    if (e.y < 70) e.y += 22 * dt;
    e.x += sin(e.age * (1.5 + e.phase * 0.4)) * (35 + e.phase * 20) * dt;
    e.x = e.x.clamp(40.0, w - 40.0);
    final shootChance = 0.018 + e.phase * 0.012;
    if (rng.nextDouble() < shootChance) {
      final n = e.phase;
      for (var i = 0; i < n; i++) {
        entities.add(Entity(
          kind: EntityKind.ebullet,
          x: e.x + (i - n / 2) * 12,
          y: e.y + 18,
          vy: 160 + e.phase * 30,
          vx: (rng.nextDouble() - 0.5) * 40 * e.phase,
          radius: 3.0 + e.phase * 0.5,
        ));
      }
    }
  }

  void _updateArena(double dt) {
    if (rival == null || rival!.dead) return;
    // AI tracks player x
    final dx = player.x - rival!.x;
    rival!.x += (dx.sign) * 90 * dt;
    rival!.x = rival!.x.clamp(30.0, w - 30.0);
    rivalFire -= dt;
    if (rivalFire <= 0) {
      rivalFire = 0.45;
      entities.add(Entity(kind: EntityKind.ebullet, x: rival!.x, y: rival!.y + 12, vy: 220, radius: 3));
      if (rng.nextDouble() < 0.3) {
        entities.add(Entity(kind: EntityKind.ebullet, x: rival!.x - 10, y: rival!.y + 12, vy: 200, vx: -30, radius: 3));
        entities.add(Entity(kind: EntityKind.ebullet, x: rival!.x + 10, y: rival!.y + 12, vy: 200, vx: 30, radius: 3));
      }
    }
  }

  void _onKill(Entity en) {
    final pts = en.kind == EntityKind.boss
        ? 300
        : en.kind == EntityKind.enemy2
            ? 45
            : 18;
    score += pts;
    shake = en.kind == EntityKind.boss ? 5 : 2;
    // loot
    final drop = rng.nextDouble();
    if (drop < 0.45) {
      entities.add(Entity(kind: EntityKind.lootCoin, x: en.x, y: en.y, vy: 60, radius: 8));
    } else if (drop < 0.6) {
      entities.add(Entity(kind: EntityKind.lootScrap, x: en.x, y: en.y, vy: 55, radius: 8));
    } else if (drop < 0.7) {
      entities.add(Entity(kind: EntityKind.lootGem, x: en.x, y: en.y, vy: 50, radius: 8));
    }
  }

  bool _hit(Entity a, Entity b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final r = a.radius + b.radius;
    return dx * dx + dy * dy < r * r;
  }

  void _spark(double x, double y, {int n = 5}) {
    for (var i = 0; i < n; i++) {
      entities.add(Entity(
        kind: EntityKind.spark,
        x: x,
        y: y,
        vx: (rng.nextDouble() - 0.5) * 150,
        vy: (rng.nextDouble() - 0.5) * 150,
        radius: 2,
      ));
    }
  }

  void paint(Canvas canvas, Size size) {
    final sx = size.width / w;
    final sy = size.height / h;
    canvas.save();
    canvas.scale(sx, sy);
    if (shake > 0) {
      canvas.translate((rng.nextDouble() - 0.5) * shake * 2, (rng.nextDouble() - 0.5) * shake * 2);
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = PO.bg);

    final starPaint = Paint()..color = const Color(0xFF8A9AB8);
    for (final s in stars) {
      canvas.drawRect(Rect.fromCenter(center: s, width: 2, height: 2), starPaint);
    }

    for (final e in entities) {
      switch (e.kind) {
        case EntityKind.bullet:
          canvas.drawRect(Rect.fromCenter(center: Offset(e.x, e.y), width: 3, height: 9), Paint()..color = const Color(0xFF80D0FF));
        case EntityKind.ebullet:
          canvas.drawRect(Rect.fromCenter(center: Offset(e.x, e.y), width: 4, height: 4), Paint()..color = const Color(0xFFFF6080));
        case EntityKind.spark:
          canvas.drawRect(Rect.fromCenter(center: Offset(e.x, e.y), width: 3, height: 3), Paint()..color = PO.gold);
        case EntityKind.enemy:
          enemySprite.paint(canvas, Offset(e.x, e.y), 2.1);
        case EntityKind.enemy2:
          enemy2Sprite.paint(canvas, Offset(e.x, e.y), 2.1);
        case EntityKind.boss:
          final sp = e.phase >= 3 ? bossPhase3 : e.phase == 2 ? bossPhase2 : bossPhase1;
          sp.paint(canvas, Offset(e.x, e.y), 2.3);
          // hp bar
          final bw = 60.0;
          canvas.drawRect(Rect.fromLTWH(e.x - bw / 2, e.y - 36, bw, 5), Paint()..color = const Color(0xFF301018));
          canvas.drawRect(Rect.fromLTWH(e.x - bw / 2, e.y - 36, bw * (e.hp / e.maxHp).clamp(0, 1), 5), Paint()..color = PO.danger);
        case EntityKind.lootCoin:
          lootCoin.paint(canvas, Offset(e.x, e.y), 2.5);
        case EntityKind.lootGem:
          lootGem.paint(canvas, Offset(e.x, e.y), 2.5);
        case EntityKind.lootScrap:
          lootBox.paint(canvas, Offset(e.x, e.y), 2.2);
        default:
          break;
      }
    }

    // player
    final flash = shieldTimer > 0 && (tick % 4 < 2) ? Colors.white24 : null;
    if (!invisible || tick % 6 < 4) {
      heroSprite(heroId).paint(canvas, Offset(player.x, player.y), 2.5, flash: flash);
    }

    // HUD
    for (var i = 0; i < 3 + bonusLives && i < 6; i++) {
      canvas.drawRect(
        Rect.fromLTWH(10.0 + i * 14, 10, 10, 10),
        Paint()..color = i < lives ? const Color(0xFFFF4A6A) : const Color(0xFF3A2030),
      );
    }
    _txt(canvas, 'SCORE $score', 70, 11);
    _txt(canvas, mode == 'arena' ? 'ARENA' : 'W$wave', 200, 11);
    // ability CDs
    _ability(canvas, 10, h - 36, 'DASH', dashCd, 3.2 * dashCdMul);
    _ability(canvas, 90, h - 36, 'ULT', ultCd, 9.0 * ultCdMul);

    if (bannerT > 0 && banner.isNotEmpty) {
      final box = Rect.fromCenter(center: Offset(w / 2, h * 0.28), width: 200, height: 36);
      drawPanel(canvas, box, border: PO.gold);
      _txt(canvas, banner, w / 2 - banner.length * 4.0, h * 0.28 - 7);
    }

    if (gameOver) {
      final box = Rect.fromCenter(center: Offset(w / 2, h / 2), width: 240, height: 110);
      drawPanel(canvas, box, border: victory ? PO.gold : PO.danger);
      _txt(canvas, victory ? 'ПОБЕДА' : 'GAME OVER', w / 2 - 48, h / 2 - 28);
      _txt(canvas, 'Score $score', w / 2 - 40, h / 2);
      _txt(canvas, 'Tap = меню', w / 2 - 44, h / 2 + 26);
    }
    canvas.restore();
  }

  void _ability(Canvas c, double x, double y, String name, double cd, double max) {
    final r = Rect.fromLTWH(x, y, 70, 22);
    drawPanel(c, r, fill: PO.panel2, border: cd > 0 ? PO.border : PO.ok);
    final ready = cd <= 0;
    _txt(c, ready ? name : '${name} ${cd.toStringAsFixed(1)}', x + 6, y + 5);
  }

  void _txt(Canvas canvas, String text, double x, double y) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFE8EEFF), fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }
}
