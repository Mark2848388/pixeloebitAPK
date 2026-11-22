import 'dart:math';
import 'package:flutter/material.dart';
import 'pixel.dart';

enum EntityKind { player, enemy, enemy2, boss, bullet, ebullet, spark }

class Entity {
  EntityKind kind;
  double x, y;
  double vx, vy;
  double hp;
  double radius;
  double age;
  bool dead;

  Entity({
    required this.kind,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.hp = 1,
    this.radius = 10,
    this.age = 0,
    this.dead = false,
  });
}

class GameWorld {
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
  bool paused = false;
  double shake = 0;
  final List<Offset> stars = [];

  // touch / hold to move
  double? targetX;
  bool firing = true;

  GameWorld({required this.w, required this.h}) {
    player = Entity(kind: EntityKind.player, x: w / 2, y: h - 70, radius: 12, hp: 1);
    for (var i = 0; i < 40; i++) {
      stars.add(Offset(rng.nextDouble() * w, rng.nextDouble() * h));
    }
    _nextWave();
  }

  void resize(double nh) {
    h = nh;
    if (player.y > h - 40) player.y = h - 70;
  }

  void _nextWave() {
    wave++;
    final count = 3 + wave;
    for (var i = 0; i < count; i++) {
      final elite = wave > 2 && rng.nextDouble() < 0.25;
      entities.add(Entity(
        kind: elite ? EntityKind.enemy2 : EntityKind.enemy,
        x: 30 + rng.nextDouble() * (w - 60),
        y: -20 - rng.nextDouble() * 120,
        vy: 40 + wave * 6 + rng.nextDouble() * 30,
        vx: (rng.nextDouble() - 0.5) * 40,
        hp: elite ? 3 : 1,
        radius: elite ? 14 : 12,
      ));
    }
    if (wave % 5 == 0) {
      entities.add(Entity(
        kind: EntityKind.boss,
        x: w / 2,
        y: -40,
        vy: 25,
        hp: 20 + wave * 3,
        radius: 22,
      ));
    }
  }

  void update(double dt) {
    if (gameOver || paused) return;
    dt = dt.clamp(0, 0.05);
    shake = (shake - dt * 8).clamp(0, 5);

    // move player toward touch
    if (targetX != null) {
      final dx = targetX! - player.x;
      player.x += (dx * 12 * dt).clamp(-400 * dt, 400 * dt);
    }
    player.x = player.x.clamp(20, w - 20);

    fireCooldown -= dt;
    if (firing && fireCooldown <= 0) {
      fireCooldown = 0.18;
      entities.add(Entity(
        kind: EntityKind.bullet,
        x: player.x,
        y: player.y - 16,
        vy: -420,
        radius: 3,
      ));
    }

    spawnTimer -= dt;
    if (spawnTimer <= 0) {
      final aliveEnemies = entities.where((e) =>
          !e.dead &&
          (e.kind == EntityKind.enemy ||
              e.kind == EntityKind.enemy2 ||
              e.kind == EntityKind.boss));
      if (aliveEnemies.isEmpty) {
        spawnTimer = 1.2;
        _nextWave();
      }
    }

    for (final e in entities) {
      if (e.dead) continue;
      e.age += dt;
      e.x += e.vx * dt;
      e.y += e.vy * dt;

      if (e.kind == EntityKind.enemy || e.kind == EntityKind.enemy2) {
        if (e.x < 16 || e.x > w - 16) e.vx *= -1;
        if (e.y > h + 30) e.dead = true;
        // shoot occasionally
        if (rng.nextDouble() < 0.004 + wave * 0.0005) {
          entities.add(Entity(
            kind: EntityKind.ebullet,
            x: e.x,
            y: e.y + 10,
            vy: 160 + wave * 8,
            radius: 3,
          ));
        }
      }
      if (e.kind == EntityKind.boss) {
        e.x += sin(e.age * 2) * 40 * dt;
        if (e.y < 80) e.y += e.vy * dt;
        if (rng.nextDouble() < 0.02) {
          entities.add(Entity(
            kind: EntityKind.ebullet,
            x: e.x + (rng.nextDouble() - 0.5) * 30,
            y: e.y + 16,
            vy: 180,
            vx: (rng.nextDouble() - 0.5) * 80,
            radius: 4,
          ));
        }
      }
      if (e.kind == EntityKind.bullet && e.y < -20) e.dead = true;
      if (e.kind == EntityKind.ebullet && e.y > h + 20) e.dead = true;
      if (e.kind == EntityKind.spark && e.age > 0.35) e.dead = true;
    }

    // collisions player bullets vs enemies
    for (final b in entities.where((e) => e.kind == EntityKind.bullet && !e.dead)) {
      for (final en in entities.where((e) =>
          !e.dead &&
          (e.kind == EntityKind.enemy ||
              e.kind == EntityKind.enemy2 ||
              e.kind == EntityKind.boss))) {
        if (_hit(b, en)) {
          b.dead = true;
          en.hp -= 1;
          _spark(en.x, en.y);
          if (en.hp <= 0) {
            en.dead = true;
            final pts = en.kind == EntityKind.boss
                ? 250
                : en.kind == EntityKind.enemy2
                    ? 40
                    : 15;
            score += pts;
            shake = 3;
          }
        }
      }
    }

    // enemy bullets / enemies vs player
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
        _spark(player.x, player.y);
        if (lives <= 0) gameOver = true;
        // brief invuln by nudging enemies away is enough for v1
        if (e.kind != EntityKind.ebullet) e.y = -40;
      }
    }

    entities.removeWhere((e) => e.dead);

    // scroll stars
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      var ny = s.dy + 30 * dt;
      if (ny > h) ny = 0;
      stars[i] = Offset(s.dx, ny);
    }
  }

  bool _hit(Entity a, Entity b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final r = a.radius + b.radius;
    return dx * dx + dy * dy < r * r;
  }

  void _spark(double x, double y) {
    for (var i = 0; i < 4; i++) {
      entities.add(Entity(
        kind: EntityKind.spark,
        x: x,
        y: y,
        vx: (rng.nextDouble() - 0.5) * 120,
        vy: (rng.nextDouble() - 0.5) * 120,
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

    // bg
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = PO.bg);

    final starPaint = Paint()..color = const Color(0xFF8A9AB8);
    for (final s in stars) {
      canvas.drawRect(Rect.fromCenter(center: s, width: 2, height: 2), starPaint);
    }

    // entities
    for (final e in entities) {
      switch (e.kind) {
        case EntityKind.bullet:
          canvas.drawRect(
            Rect.fromCenter(center: Offset(e.x, e.y), width: 3, height: 8),
            Paint()..color = const Color(0xFF80D0FF),
          );
        case EntityKind.ebullet:
          canvas.drawRect(
            Rect.fromCenter(center: Offset(e.x, e.y), width: 4, height: 4),
            Paint()..color = const Color(0xFFFF6080),
          );
        case EntityKind.spark:
          canvas.drawRect(
            Rect.fromCenter(center: Offset(e.x, e.y), width: 3, height: 3),
            Paint()..color = PO.gold,
          );
        case EntityKind.enemy:
          enemySprite.paint(canvas, Offset(e.x, e.y), 2.2);
        case EntityKind.enemy2:
          enemy2Sprite.paint(canvas, Offset(e.x, e.y), 2.2);
        case EntityKind.boss:
          bossSprite.paint(canvas, Offset(e.x, e.y), 2.4);
        default:
          break;
      }
    }

    shipSprite.paint(canvas, Offset(player.x, player.y), 2.4);

    // HUD
    final hud = TextPainter(
      text: TextSpan(
        text: 'HP ${'♥' * lives}${'♡' * (3 - lives)}   SCORE $score   WAVE $wave',
        style: pixText(size: 11, color: PO.text),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 16);
    hud.paint(canvas, const Offset(8, 8));

    if (gameOver) {
      final box = Rect.fromCenter(center: Offset(w / 2, h / 2), width: 220, height: 90);
      drawPanel(canvas, box);
      final t = TextPainter(
        text: TextSpan(
          text: 'GAME OVER\nScore $score\nTap to menu',
          style: pixText(size: 16, color: PO.gold),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 200);
      t.paint(canvas, Offset(w / 2 - t.width / 2, h / 2 - t.height / 2));
    }

    canvas.restore();
  }
}
