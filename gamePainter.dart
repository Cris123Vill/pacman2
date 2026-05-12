import 'dart:math';
import 'package:flutter/material.dart';
import 'game_constants.dart';
import 'game_models.dart';
import 'game_service.dart';

class GamePainter extends CustomPainter {
  final GameService game;
  final int tick;

  GamePainter({required this.game, required this.tick});

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawStars(canvas);
    _drawMap(canvas);
    _drawParticles(canvas);
    if (game.state != GameState.respawning || tick % 6 < 4) {
      _drawPlayer(canvas);
    }
    _drawGhosts(canvas);
    _drawFloatTexts(canvas);
    if (game.frightTimer > 0) _drawPowerBar(canvas, size);
  }

  // ─── FUNDO ESPACIAL ──────────────────────────────────────────────────────

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = kColorBg,
    );
  }

  void _drawStars(Canvas canvas) {
    for (final s in game.stars) {
      final phase = s.twinklePhase + tick * s.twinkleSpeed;
      final brightness = (s.brightness * (0.5 + 0.5 * sin(phase))).clamp(0.1, 1.0);
      canvas.drawCircle(
        Offset(s.x, s.y),
        s.size,
        Paint()..color = Color.fromRGBO(200, 220, 255, brightness),
      );
    }
  }

  // ─── MAPA ────────────────────────────────────────────────────────────────

  void _drawMap(Canvas canvas) {
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        final cell = game.map[r][c];
        final x = c * kCell;
        final y = r * kCell;

        if (cell == kWall) {
          _drawWall(canvas, r, c, x, y);
        } else if (cell == kDot) {
          _drawDot(canvas, x, y);
        } else if (cell == kPower) {
          _drawPowerPellet(canvas, x, y);
        }
      }
    }
  }

  void _drawWall(Canvas canvas, int r, int c, double x, double y) {
    // Preenchimento da parede
    canvas.drawRect(
      Rect.fromLTWH(x, y, kCell, kCell),
      Paint()..color = kColorWall,
    );

    // Brilho nas bordas expostas (estilo neon)
    final glowPaint = Paint()
      ..color = kColorWallGlow.withOpacity(0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Borda superior
    if (r > 0 && game.map[r - 1][c] != kWall) {
      canvas.drawLine(Offset(x, y), Offset(x + kCell, y), glowPaint);
    }
    // Borda inferior
    if (r < kRows - 1 && game.map[r + 1][c] != kWall) {
      canvas.drawLine(Offset(x, y + kCell), Offset(x + kCell, y + kCell), glowPaint);
    }
    // Borda esquerda
    if (c > 0 && game.map[r][c - 1] != kWall) {
      canvas.drawLine(Offset(x, y), Offset(x, y + kCell), glowPaint);
    }
    // Borda direita
    if (c < kCols - 1 && game.map[r][c + 1] != kWall) {
      canvas.drawLine(Offset(x + kCell, y), Offset(x + kCell, y + kCell), glowPaint);
    }
  }

  void _drawDot(Canvas canvas, double x, double y) {
    final cx = x + kCell / 2;
    final cy = y + kCell / 2;

    // Brilho
    canvas.drawCircle(
      Offset(cx, cy),
      3.5,
      Paint()
        ..color = kColorDot.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = kColorDot);
  }

  void _drawPowerPellet(Canvas canvas, double x, double y) {
    final cx = x + kCell / 2;
    final cy = y + kCell / 2;
    final pulse = 0.6 + 0.4 * sin(tick * 0.18);
    final r = 5.0 * pulse;

    // Halo
    canvas.drawCircle(
      Offset(cx, cy),
      r + 4,
      Paint()
        ..color = kColorPower.withOpacity(0.2 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Núcleo
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = kColorPower);
    // Brilho central
    canvas.drawCircle(
      Offset(cx - r * 0.3, cy - r * 0.3),
      r * 0.35,
      Paint()..color = Colors.white.withOpacity(0.7),
    );
  }

  // ─── PLAYER (NAVE ESPACIAL) ──────────────────────────────────────────────

  void _drawPlayer(Canvas canvas) {
    final p = game.player;
    final cx = p.c * kCell + kCell / 2;
    final cy = p.r * kCell + kCell / 2;
    final r = kCell / 2 - 2;
    final ma = p.mouthAngle * (pi / 180);

    // Rotação baseada na direção
    double baseAngle = 0;
    switch (p.direction) {
      case Direction.right: baseAngle = 0; break;
      case Direction.left: baseAngle = pi; break;
      case Direction.up: baseAngle = -pi / 2; break;
      case Direction.down: baseAngle = pi / 2; break;
      default: baseAngle = 0;
    }

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(baseAngle);

    // Glow exterior
    canvas.drawCircle(
      Offset.zero,
      r + 3,
      Paint()
        ..color = kColorPlayerGlow.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Corpo (fatia de pizza)
    final startA = ma;
    final endA = 2 * pi - ma;
    final path = Path()
      ..moveTo(0, 0)
      ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r), startA, endA - startA, false)
      ..close();

    canvas.drawPath(path, Paint()..color = kColorPlayer);

    // Detalhe interior (motor)
    canvas.drawCircle(
      Offset(r * 0.15, 0),
      r * 0.25,
      Paint()..color = kColorPlayerGlow.withOpacity(0.8),
    );

    // Brilho superior
    canvas.drawArc(
      Rect.fromCircle(center: Offset(-r * 0.1, -r * 0.1), radius: r * 0.55),
      pi + 0.3,
      pi - 0.6,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  // ─── ALIENS (FANTASMAS) ──────────────────────────────────────────────────

  void _drawGhosts(Canvas canvas) {
    for (final g in game.ghosts) {
      _drawGhost(canvas, g);
    }
  }

  void _drawGhost(Canvas canvas, Ghost g) {
    final flashing = game.frightTimer in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] &&
        game.frightTimer > 0 &&
        (tick ~/ 4) % 2 == 0;

    Color bodyColor;
    if (g.frightened) {
      bodyColor = flashing ? kColorFrightenedFlash : kColorFrightened;
    } else {
      bodyColor = g.color;
    }

    final cx = g.c * kCell + kCell / 2;
    final cy = g.r * kCell + kCell / 2;
    final s = kCell - 2;
    final left = cx - s / 2;
    final top = cy - s / 2;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy - s * 0.1),
      s * 0.55,
      Paint()
        ..color = bodyColor.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Corpo principal
    final path = Path();
    path.moveTo(left, top + s);
    path.lineTo(left, top + s * 0.45);
    path.arcToPoint(
      Offset(left + s, top + s * 0.45),
      radius: Radius.circular(s * 0.5),
      clockwise: false,
    );
    path.lineTo(left + s, top + s);

    // Fundo ondulado (tentáculos)
    const waves = 3;
    final ww = s / waves;
    final animOffset = sin(tick * 0.15 + g.index) * 2;
    for (int i = waves - 1; i >= 0; i--) {
      final wx = left + i * ww;
      final peakY = top + s - (i % 2 == 0 ? 5 : 2) + animOffset;
      path.quadraticBezierTo(wx + ww * 0.5, peakY, wx, top + s);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = bodyColor);

    if (!g.frightened) {
      // Olhos brancos
      final eyeY = top + s * 0.38;
      final eyeR = s * 0.16;
      canvas.drawCircle(Offset(left + s * 0.3, eyeY), eyeR, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(left + s * 0.7, eyeY), eyeR, Paint()..color = Colors.white);

      // Pupilas (olham para player)
      final dr = game.player.r - g.r;
      final dc = game.player.c - g.c;
      final len = sqrt(dr * dr + dc * dc).clamp(0.01, double.infinity);
      final px = (dc / len) * eyeR * 0.55;
      final py = (dr / len) * eyeR * 0.55;
      canvas.drawCircle(Offset(left + s * 0.3 + px, eyeY + py), eyeR * 0.55, Paint()..color = Colors.blue.shade900);
      canvas.drawCircle(Offset(left + s * 0.7 + px, eyeY + py), eyeR * 0.55, Paint()..color = Colors.blue.shade900);

      // Antena (alien!)
      final antX = cx;
      final antY = top - 1;
      canvas.drawLine(Offset(antX, antY), Offset(antX, antY - 5), Paint()..color = g.color..strokeWidth = 1.5);
      canvas.drawCircle(Offset(antX, antY - 6), 2, Paint()..color = g.color.withOpacity(0.8));
    } else {
      // Cara assustada
      final paint = Paint()
        ..color = flashing ? Colors.red : Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final y = cy + s * 0.1;
      final mPath = Path()
        ..moveTo(cx - s * 0.28, y)
        ..lineTo(cx - s * 0.14, y - 4)
        ..lineTo(cx, y)
        ..lineTo(cx + s * 0.14, y - 4)
        ..lineTo(cx + s * 0.28, y);
      canvas.drawPath(mPath, paint);
      canvas.drawCircle(Offset(cx - s * 0.2, y - s * 0.2), 2.5, Paint()..color = (flashing ? Colors.red : Colors.white));
      canvas.drawCircle(Offset(cx + s * 0.2, y - s * 0.2), 2.5, Paint()..color = (flashing ? Colors.red : Colors.white));
    }
  }

  // ─── PARTÍCULAS ──────────────────────────────────────────────────────────

  void _drawParticles(Canvas canvas) {
    for (final p in game.particles) {
      canvas.drawCircle(
        p.pos,
        p.size * p.life,
        Paint()..color = p.color.withOpacity(p.life.clamp(0.0, 1.0)),
      );
    }
  }

  // ─── TEXTOS FLUTUANTES ───────────────────────────────────────────────────

  void _drawFloatTexts(Canvas canvas) {
    for (final f in game.floatTexts) {
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            color: f.color.withOpacity(f.life.clamp(0.0, 1.0)),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: f.color, blurRadius: 6)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, f.pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  // ─── BARRA DE PODER ──────────────────────────────────────────────────────

  void _drawPowerBar(Canvas canvas, Size size) {
    final pct = game.frightTimer / kFrightDuration;
    final h = 5.0;
    final y = size.height - h;

    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, h),
      Paint()..color = Colors.white.withOpacity(0.1),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width * pct, h),
      Paint()..color = kColorPower.withOpacity(0.85),
    );
  }

  @override
  bool shouldRepaint(GamePainter old) => true;
}