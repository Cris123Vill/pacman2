import 'package:flutter/material.dart';
import 'game_constants.dart';

// ─── DIREÇÃO ─────────────────────────────────────────────────────────────────
enum Direction { right, left, up, down, none }

extension DirectionExt on Direction {
  int get dr {
    switch (this) {
      case Direction.up: return -1;
      case Direction.down: return 1;
      default: return 0;
    }
  }

  int get dc {
    switch (this) {
      case Direction.left: return -1;
      case Direction.right: return 1;
      default: return 0;
    }
  }
}

// ─── PLAYER ──────────────────────────────────────────────────────────────────
class Player {
  int r;
  int c;
  Direction direction;
  Direction nextDir;
  double mouthAngle;
  int mouthDir;

  Player({
    this.r = 16,
    this.c = 9,
    this.direction = Direction.none,
    this.nextDir = Direction.right,
    this.mouthAngle = 0,
    this.mouthDir = 1,
  });

  void reset() {
    r = 16; c = 9;
    direction = Direction.none;
    nextDir = Direction.right;
    mouthAngle = 0;
    mouthDir = 1;
  }

  // Animação da boca
  void animateMouth() {
    mouthAngle += 4.0 * mouthDir;
    if (mouthAngle >= 38) mouthDir = -1;
    if (mouthAngle <= 0) mouthDir = 1;
  }

  // Offset visual do corpo em pixels
  Offset get pixelPos => Offset(c * kCell + kCell / 2, r * kCell + kCell / 2);
}

// ─── GHOST (ALIEN) ───────────────────────────────────────────────────────────
class Ghost {
  int index;
  int r;
  int c;
  Color color;
  String name;
  bool frightened;
  bool eaten;
  int moveTimer;
  int baseSpeed; // ticks entre movimentos (menor = mais rápido)
  int animFrame;

  Ghost({
    required this.index,
    required this.r,
    required this.c,
    required this.color,
    required this.name,
    this.frightened = false,
    this.eaten = false,
    this.moveTimer = 0,
    this.baseSpeed = 7,
    this.animFrame = 0,
  });

  void resetToSpawn() {
    r = kGhostStarts[index]['r']!;
    c = kGhostStarts[index]['c']!;
    frightened = false;
    eaten = false;
    moveTimer = 0;
  }

  Offset get pixelPos => Offset(c * kCell + kCell / 2, r * kCell + kCell / 2);
}

// ─── PARTÍCULA VISUAL ────────────────────────────────────────────────────────
class Particle {
  Offset pos;
  Offset vel;
  double life; // 0..1
  Color color;
  double size;

  Particle({
    required this.pos,
    required this.vel,
    required this.color,
    this.life = 1.0,
    this.size = 4.0,
  });

  void update() {
    pos += vel;
    vel = Offset(vel.dx * 0.92, vel.dy * 0.92);
    life -= 0.045;
  }

  bool get dead => life <= 0;
}

// ─── FLOATING TEXT (pontuação flutuante) ─────────────────────────────────────
class FloatText {
  String text;
  Offset pos;
  double life;
  Color color;

  FloatText({
    required this.text,
    required this.pos,
    required this.color,
    this.life = 1.0,
  });

  void update() {
    pos = Offset(pos.dx, pos.dy - 1.2);
    life -= 0.04;
  }

  bool get dead => life <= 0;
}

// ─── ESTRELA DE FUNDO ────────────────────────────────────────────────────────
class Star {
  double x;
  double y;
  double size;
  double brightness;
  double twinkleSpeed;
  double twinklePhase;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinklePhase,
  });
}