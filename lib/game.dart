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
  bool paused = false;
  double shake = 0;
  final List<Offset> stars = [];

  double? targetX;
  bool firing = true;
  int tick = 0;

  GameWorld({required this.w, required this.h}) {
    player = Entity(
      kind: EntityKind.player,
      x: w / 2,
      y: h - 80,
      radius: 12,
      hp: 1,
    );
    for (var i = 0; i < 48; i++) {
      stars.add(Offset(rng.nextDouble() * w, rng.nextDouble() * h));
    }
    _nextWave(first: true);
  }

  void resize(double nh) {
    if (nh <= 0 || (nh - h).abs() < 1) return;
    h = nh;
    if (player.y > h - 40) player.y = h - 80;
  }

  void _nextWave({bool first = false}) {
    wave++;
    final count = first ? 4 : 3 + wave;
    for (var i = 0; i < count; i++) {
      final elite = wave > 2 && rng.nextDouble() < 0.25;
      // First wave: start on-screen so motion is obvious immediately
      final startY = first
          ? (40.0 + i * 36.0)
          : (-20.0 - rng.nextDouble() * 100.0);
      entities.add(Entity(
        kind: elite ? EntityKind.enemy2 : EntityKind.enemy,
        x: 40 + rng.nextDouble() * (w - 80),
        y: startY,
        vy: 70 + wave * 8 + rng.nextDouble() * 40,
        vx: (rng.nextDouble() - 0.5) * 50,
        hp: elite ? 3 : 1,
        radius: elite ? 14 : 12,
      ));
    }
    if (wave > 0 && wave % 5 == 0) {
      entities.add(Entity(
        kind: EntityKind.boss,
        x: w / 2,
        y: -50,
        vy: 30,
        hp: 18.0 + wave * 3,
        radius: 22,
      ));
    }
  }

  void update(double dt) {
    if (gameOver || paused) return;
    if (dt <= 0) dt = 1 / 60;
    if (dt > 0.05) dt = 0.05;
    tick++;
    shake = (shake - dt * 8).clamp(0.0, 5.0);

    if (targetX != null) {
      final dx = targetX! - player.x;
      final step = (dx * 14 * dt).clamp(-450 * dt, 450 * dt);
      player.x += step;
    }
    player.x = player.x.clamp(20.0, w - 20.0);

    fireCooldown -= dt;
    if (firing && fireCooldown <= 0) {
      fireCooldown = 0.16;
      entities.add(Entity(
        kind: EntityKind.bullet,
        x: player.x,
        y: player.y - 18,
        vy: -480,
        radius: 3,
      ));
    }

    // next wave when field clear
    final hasEnemy = entities.any((e) =>
        !e.dead &&
        (e.kind == EntityKind.enemy ||
            e.kind == EntityKind.enemy2 ||
            e.kind == EntityKind.boss));
    if (!hasEnemy) {
      spawnTimer -= dt;
      if (spawnTimer <= 0) {
        spawnTimer = 0.8;
        _nextWave();
      }
    }

    for (final e in entities) {
      if (e.dead) continue;
      e.age += dt;
      e.x += e.vx * dt;
      e.y += e.vy * dt;

      if (e.kind == EntityKind.enemy || e.kind == EntityKind.enemy2) {
        if (e.x < 18) {
          e.x = 18;
          e.vx = e.vx.abs();
        } else if (e.x > w - 18) {
          e.x = w - 18;
          e.vx = -e.vx.abs();
        }
        if (e.y > h + 40) e.dead = true;
        if (rng.nextDouble() < 0.006 + wave * 0.0006) {
          entities.add(Entity(
            kind: EntityKind.ebullet,
            x: e.x,
            y: e.y + 12,
            vy: 170 + wave * 10,
            radius: 3,
          ));
        }
      }

      if (e.kind == EntityKind.boss) {
        e.x += sin(e.age * 2.2) * 55 * dt;
        if (e.y < 90) e.y += 20 * dt;
        if (rng.nextDouble() < 0.025) {
          entities.add(Entity(
            kind: EntityKind.ebullet,
            x: e.x + (rng.nextDouble() - 0.5) * 40,
            y: e.y + 18,
            vy: 190,
            vx: (rng.nextDouble() - 0.5) * 90,
            radius: 4,
          ));
        }
      }

      if (e.kind == EntityKind.bullet && e.y < -30) e.dead = true;
      if (e.kind == EntityKind.ebullet && e.y > h + 30) e.dead = true;
      if (e.kind == EntityKind.spark && e.age > 0.3) e.dead = true;
    }

    // bullets vs enemies
    for (final b in entities) {
      if (b.dead || b.kind != EntityKind.bullet) continue;
      for (final en in entities) {
        if (en.dead) continue;
        if (en.kind != EntityKind.enemy &&
            en.kind != EntityKind.enemy2 &&
            en.kind != EntityKind.boss) {
          continue;
        }
        if (_hit(b, en)) {
          b.dead = true;
          en.hp -= 1;
          _spark(en.x, en.y);
          if (en.hp <= 0) {
            en.dead = true;
            score += en.kind == EntityKind.boss
                ? 250
                : en.kind == EntityKind.enemy2
                    ? 40
                    : 15;
            shake = 3;
          }
          break;
        }
      }
    }

    // damage to player
    for (final e in entities) {
      if (e.dead) continue;
      if (e.kind != EntityKind.ebullet &&
          e.kind != EntityKind.enemy &&
          e.kind != EntityKind.enemy2 &&
          e.kind != EntityKind.boss) {
        continue;
      }
      if (_hit(e, player)) {
        if (e.kind == EntityKind.ebullet) e.dead = true;
        lives -= 1;
        shake = 5;
        _spark(player.x, player.y);
        if (e.kind != EntityKind.ebullet) {
          e.y = -60;
          e.x = rng.nextDouble() * w;
        }
        if (lives <= 0) {
          lives = 0;
          gameOver = true;
        }
        break;
      }
    }

    entities.removeWhere((e) => e.dead);

    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      var ny = s.dy + 45 * dt;
      if (ny > h) ny -= h;
      stars[i] = Offset(s.dx, ny);
    }

    notifyListeners();
  }

  bool _hit(Entity a, Entity b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final r = a.radius + b.radius;
    return dx * dx + dy * dy < r * r;
  }

  void _spark(double x, double y) {
    for (var i = 0; i < 5; i++) {
      entities.add(Entity(
        kind: EntityKind.spark,
        x: x,
        y: y,
        vx: (rng.nextDouble() - 0.5) * 140,
        vy: (rng.nextDouble() - 0.5) * 140,
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
      canvas.translate(
        (rng.nextDouble() - 0.5) * shake * 2,
        (rng.nextDouble() - 0.5) * shake * 2,
      );
    }

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = PO.bg);

    final starPaint = Paint()..color = const Color(0xFF8A9AB8);
    for (final s in stars) {
      canvas.drawRect(
        Rect.fromCenter(center: s, width: 2, height: 2),
        starPaint,
      );
    }

    for (final e in entities) {
      switch (e.kind) {
        case EntityKind.bullet:
          canvas.drawRect(
            Rect.fromCenter(center: Offset(e.x, e.y), width: 3, height: 9),
            Paint()..color = const Color(0xFF80D0FF),
          );
          break;
        case EntityKind.ebullet:
          canvas.drawRect(
            Rect.fromCenter(center: Offset(e.x, e.y), width: 4, height: 4),
            Paint()..color = const Color(0xFFFF6080),
          );
          break;
        case EntityKind.spark:
          canvas.drawRect(
            Rect.fromCenter(center: Offset(e.x, e.y), width: 3, height: 3),
            Paint()..color = PO.gold,
          );
          break;
        case EntityKind.enemy:
          enemySprite.paint(canvas, Offset(e.x, e.y), 2.2);
          break;
        case EntityKind.enemy2:
          enemy2Sprite.paint(canvas, Offset(e.x, e.y), 2.2);
          break;
        case EntityKind.boss:
          bossSprite.paint(canvas, Offset(e.x, e.y), 2.4);
          break;
        case EntityKind.player:
          break;
      }
    }

    shipSprite.paint(canvas, Offset(player.x, player.y), 2.6);

    // simple HUD without emoji TextPainter cost
    final hudPaint = Paint()..color = const Color(0xFFE8EEFF);
    final hp = lives.clamp(0, 3);
    for (var i = 0; i < 3; i++) {
      final r = Rect.fromLTWH(10.0 + i * 14, 10, 10, 10);
      canvas.drawRect(
        r,
        Paint()..color = i < hp ? const Color(0xFFFF4A6A) : const Color(0xFF3A2030),
      );
    }
    _drawHudText(canvas, 'SCORE $score', 60, 12);
    _drawHudText(canvas, 'WAVE $wave', 180, 12);
    _drawHudText(canvas, 'T$tick', 300, 12);

    if (gameOver) {
      final box =
          Rect.fromCenter(center: Offset(w / 2, h / 2), width: 220, height: 100);
      drawPanel(canvas, box);
      _drawHudText(canvas, 'GAME OVER', w / 2 - 50, h / 2 - 24);
      _drawHudText(canvas, 'Score $score', w / 2 - 40, h / 2);
      _drawHudText(canvas, 'Tap = menu', w / 2 - 44, h / 2 + 22);
    }

    canvas.restore();
  }

  void _drawHudText(Canvas canvas, String text, double x, double y) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Color(0xFFE8EEFF),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }
}
