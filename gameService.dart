import 'dart:math';
import 'package:flutter/material.dart';
import 'game_constants.dart';
import 'game_models.dart';

// ─── ESTADO DO JOGO ───────────────────────────────────────────────────────────
enum GameState { menu, playing, paused, respawning, levelUp, gameOver, victory }

class GameService extends ChangeNotifier {
  // Estado
  GameState state = GameState.menu;
  late List<List<int>> map;
  late Player player;
  late List<Ghost> ghosts;
  int score = 0;
  int highScore = 0;
  int lives = kLives;
  int level = 1;
  int frightTimer = 0;
  int dotsRemaining = 0;
  int tick = 0;
  int comboCount = 0; // fantasmas comidos durante 1 power pellet

  // Efeitos visuais
  List<Particle> particles = [];
  List<FloatText> floatTexts = [];
  List<Star> stars = [];

  final Random _rng = Random();

  GameService() {
    _generateStars();
    _initGame();
  }

  // ─── INICIALIZAÇÃO ─────────────────────────────────────────────────────────

  void _generateStars() {
    stars = List.generate(60, (_) => Star(
      x: _rng.nextDouble() * (kCols * kCell),
      y: _rng.nextDouble() * (kRows * kCell),
      size: _rng.nextDouble() * 1.8 + 0.3,
      brightness: _rng.nextDouble(),
      twinkleSpeed: _rng.nextDouble() * 0.08 + 0.02,
      twinklePhase: _rng.nextDouble() * 2 * pi,
    ));
  }

  void _initGame() {
    _buildMap();
    player = Player();
    _buildGhosts();
    score = 0;
    lives = kLives;
    level = 1;
    frightTimer = 0;
    tick = 0;
    particles.clear();
    floatTexts.clear();
  }

  void _buildMap() {
    map = kBaseMap.map((row) => [...row]).toList();
    dotsRemaining = 0;
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if (map[r][c] == kDot || map[r][c] == kPower) dotsRemaining++;
      }
    }
  }

  void _buildGhosts() {
    ghosts = List.generate(4, (i) => Ghost(
      index: i,
      r: kGhostStarts[i]['r']!,
      c: kGhostStarts[i]['c']!,
      color: kGhostColors[i],
      name: kGhostNames[i],
      baseSpeed: 7 + i,
    ));
  }

  // ─── CONTROLE ─────────────────────────────────────────────────────────────

  void startGame() {
    _initGame();
    state = GameState.playing;
    notifyListeners();
  }

  void restartFromGameOver() {
    startGame();
  }

  void togglePause() {
    if (state == GameState.playing) {
      state = GameState.paused;
    } else if (state == GameState.paused) {
      state = GameState.playing;
    }
    notifyListeners();
  }

  void setNextDir(Direction d) {
    player.nextDir = d;
  }

  // ─── TICK PRINCIPAL ────────────────────────────────────────────────────────

  void gameTick() {
    if (state != GameState.playing) return;
    tick++;

    // Animação da boca e estrelas
    player.animateMouth();

    // Mover player
    _movePlayer();

    // Mover aliens
    _moveGhosts();

    // Verificar colisões
    _checkCollisions();

    // Decrement fright
    if (frightTimer > 0) {
      frightTimer--;
      if (frightTimer == 0) {
        for (final g in ghosts) g.frightened = false;
      }
    }

    // Atualizar partículas e textos
    particles.removeWhere((p) => p.dead);
    for (final p in particles) p.update();
    floatTexts.removeWhere((f) => f.dead);
    for (final f in floatTexts) f.update();

    notifyListeners();
  }

  // ─── MOVIMENTO DO PLAYER ───────────────────────────────────────────────────

  void _movePlayer() {
    // Tentar mudar de direção
    final nr = player.r + player.nextDir.dr;
    final nc = player.c + player.nextDir.dc;
    if (!_isWall(nr, nc)) {
      player.direction = player.nextDir;
    }

    // Mover
    final mr = player.r + player.direction.dr;
    final mc = player.c + player.direction.dc;

    if (!_isWall(mr, mc)) {
      player.r = mr;
      player.c = mc;

      // Túnel lateral
      if (player.c < 0) player.c = kCols - 1;
      if (player.c >= kCols) player.c = 0;
    }

    // Coletar item
    _collectAt(player.r, player.c);
  }

  void _collectAt(int r, int c) {
    final cell = map[r][c];
    if (cell == kDot) {
      map[r][c] = kEaten;
      score += kScoreDot;
      dotsRemaining--;
      _spawnDotParticles(r, c, kColorDot, 4);
      _checkVictory();
    } else if (cell == kPower) {
      map[r][c] = kEaten;
      score += kScorePower;
      dotsRemaining--;
      frightTimer = kFrightDuration;
      comboCount = 0;
      for (final g in ghosts) {
        g.frightened = true;
        g.eaten = false;
      }
      _spawnDotParticles(r, c, kColorPower, 12);
      _addFloatText('+${kScorePower}', r, c, kColorPower);
      _checkVictory();
    }
  }

  // ─── MOVIMENTO DOS ALIENS ──────────────────────────────────────────────────

  void _moveGhosts() {
    for (int i = 0; i < ghosts.length; i++) {
      final g = ghosts[i];
      g.moveTimer++;
      final speed = _ghostSpeed(g, i);
      if (g.moveTimer < speed) continue;
      g.moveTimer = 0;
      g.animFrame = (g.animFrame + 1) % 4;

      final target = _ghostTarget(g, i);
      final next = g.frightened || g.eaten
          ? _randomNeighbor(g.r, g.c)
          : _bfsMove(g.r, g.c, target.r, target.c);

      g.r = next.r;
      g.c = next.c;

      // Túnel lateral
      if (g.c < 0) g.c = kCols - 1;
      if (g.c >= kCols) g.c = 0;
    }
  }

  int _ghostSpeed(Ghost g, int index) {
    // Mais rápido a cada nível; assustado = mais lento
    final base = g.baseSpeed - (level ~/ 2).clamp(0, 4);
    return g.frightened ? (base + 4).clamp(4, 14) : base.clamp(3, 10);
  }

  ({int r, int c}) _ghostTarget(Ghost g, int index) {
    switch (index) {
      case 0: // Caçador: persegue diretamente
        return (r: player.r, c: player.c);
      case 1: // Emboscador: 3 células à frente do player
        return (
          r: (player.r + player.direction.dr * 3).clamp(0, kRows - 1),
          c: (player.c + player.direction.dc * 3).clamp(0, kCols - 1),
        );
      case 2: // Interceptor: misto com distância
        final dist = (g.r - player.r).abs() + (g.c - player.c).abs();
        return dist > 8
            ? (r: player.r, c: player.c)
            : (r: _rng.nextInt(kRows), c: _rng.nextInt(kCols));
      default: // Errante: aleatório
        return (r: _rng.nextInt(kRows), c: _rng.nextInt(kCols));
    }
  }

  // ─── BFS ──────────────────────────────────────────────────────────────────

  ({int r, int c}) _bfsMove(int fr, int fc, int tr, int tc) {
    if (fr == tr && fc == tc) return (r: fr, c: fc);

    final visited = List.generate(kRows, (_) => List.filled(kCols, false));
    final prev = List.generate(kRows, (_) => List<List<int>?>.filled(kCols, null));
    final queue = <List<int>>[[fr, fc]];
    visited[fr][fc] = true;

    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final nb in _neighbors(cur[0], cur[1])) {
        final nr = nb[0], nc = nb[1];
        if (!visited[nr][nc]) {
          visited[nr][nc] = true;
          prev[nr][nc] = cur;
          if (nr == tr && nc == tc) {
            var step = [nr, nc];
            while (prev[step[0]][step[1]] != null &&
                !(prev[step[0]][step[1]]![0] == fr &&
                    prev[step[0]][step[1]]![1] == fc)) {
              step = prev[step[0]][step[1]]!;
            }
            return (r: step[0], c: step[1]);
          }
          queue.add([nr, nc]);
        }
      }
    }
    return (r: fr, c: fc);
  }

  ({int r, int c}) _randomNeighbor(int r, int c) {
    final n = _neighbors(r, c);
    if (n.isEmpty) return (r: r, c: c);
    final pick = n[_rng.nextInt(n.length)];
    return (r: pick[0], c: pick[1]);
  }

  List<List<int>> _neighbors(int r, int c) {
    return [
      [r - 1, c],
      [r + 1, c],
      [r, c - 1],
      [r, c + 1],
    ].where((p) {
      final nr = p[0], nc = p[1];
      if (nr < 0 || nr >= kRows) return false;
      // Túnel: coluna fora redireciona
      final col = nc < 0 ? kCols - 1 : (nc >= kCols ? 0 : nc);
      return map[nr][col] != kWall;
    }).toList();
  }

  bool _isWall(int r, int c) {
    if (r < 0 || r >= kRows) return true;
    if (c < 0 || c >= kCols) return false; // túnel lateral
    return map[r][c] == kWall;
  }

  // ─── COLISÕES ─────────────────────────────────────────────────────────────

  void _checkCollisions() {
    for (final g in ghosts) {
      if (g.r == player.r && g.c == player.c) {
        if (g.frightened) {
          comboCount++;
          final pts = kScoreGhost * comboCount;
          score += pts;
          g.resetToSpawn();
          _spawnGhostEatenParticles(g.r, g.c, g.color);
          _addFloatText('+$pts', g.r, g.c, g.color);
        } else if (!g.eaten) {
          _playerDied();
          return;
        }
      }
    }
  }

  void _playerDied() {
    lives--;
    _spawnDeathParticles(player.r, player.c);
    if (lives <= 0) {
      if (score > highScore) highScore = score;
      state = GameState.gameOver;
    } else {
      state = GameState.respawning;
      Future.delayed(kRespawnDelay, () {
        if (state == GameState.respawning) {
          player.reset();
          for (final g in ghosts) g.resetToSpawn();
          frightTimer = 0;
          state = GameState.playing;
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  void _checkVictory() {
    if (dotsRemaining <= 0) {
      level++;
      if (score > highScore) highScore = score;
      state = GameState.levelUp;
      Future.delayed(const Duration(milliseconds: 1800), () {
        _buildMap();
        player.reset();
        _buildGhosts();
        frightTimer = 0;
        state = GameState.playing;
        notifyListeners();
      });
      notifyListeners();
    }
  }

  // ─── PARTÍCULAS E EFEITOS ─────────────────────────────────────────────────

  void _spawnDotParticles(int r, int c, Color color, int count) {
    final cx = c * kCell + kCell / 2;
    final cy = r * kCell + kCell / 2;
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 2.5 + 0.5;
      particles.add(Particle(
        pos: Offset(cx, cy),
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        size: _rng.nextDouble() * 3 + 1,
        life: 0.8 + _rng.nextDouble() * 0.3,
      ));
    }
  }

  void _spawnGhostEatenParticles(int r, int c, Color color) {
    final cx = c * kCell + kCell / 2;
    final cy = r * kCell + kCell / 2;
    for (int i = 0; i < 20; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 4 + 1;
      particles.add(Particle(
        pos: Offset(cx, cy),
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        color: i % 2 == 0 ? color : Colors.white,
        size: _rng.nextDouble() * 5 + 2,
        life: 1.0,
      ));
    }
  }

  void _spawnDeathParticles(int r, int c) {
    final cx = c * kCell + kCell / 2;
    final cy = r * kCell + kCell / 2;
    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * 2 * pi;
      final speed = _rng.nextDouble() * 5 + 2;
      particles.add(Particle(
        pos: Offset(cx, cy),
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        color: i % 3 == 0 ? kColorPlayer : kColorPlayerGlow,
        size: _rng.nextDouble() * 6 + 2,
        life: 1.2,
      ));
    }
  }

  void _addFloatText(String text, int r, int c, Color color) {
    floatTexts.add(FloatText(
      text: text,
      pos: Offset(c * kCell + kCell / 2, r * kCell),
      color: color,
    ));
  }
}