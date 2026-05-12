import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_constants.dart';
import 'game_models.dart';
import 'game_service.dart';
import 'game_painter.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late GameService _game;
  Timer? _timer;
  int _tick = 0;

  // Animações de overlay
  late AnimationController _overlayAnim;
  late AnimationController _hudPulse;

  @override
  void initState() {
    super.initState();
    _game = GameService();

    _overlayAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _hudPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _startLoop();
  }

  void _startLoop() {
    _timer = Timer.periodic(kTickRate, (_) {
      _tick++;
      _game.gameTick();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _overlayAnim.dispose();
    _hudPulse.dispose();
    super.dispose();
  }

  // ─── INPUT TECLADO ────────────────────────────────────────────────────────

  void _handleKey(KeyEvent e) {
    if (e is! KeyDownEvent) return;
    if (_game.state == GameState.playing || _game.state == GameState.respawning) {
      if (e.logicalKey == LogicalKeyboardKey.arrowUp || e.logicalKey == LogicalKeyboardKey.keyW) {
        _game.setNextDir(Direction.up);
      } else if (e.logicalKey == LogicalKeyboardKey.arrowDown || e.logicalKey == LogicalKeyboardKey.keyS) {
        _game.setNextDir(Direction.down);
      } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft || e.logicalKey == LogicalKeyboardKey.keyA) {
        _game.setNextDir(Direction.left);
      } else if (e.logicalKey == LogicalKeyboardKey.arrowRight || e.logicalKey == LogicalKeyboardKey.keyD) {
        _game.setNextDir(Direction.right);
      } else if (e.logicalKey == LogicalKeyboardKey.escape || e.logicalKey == LogicalKeyboardKey.keyP) {
        _game.togglePause();
      }
    }
  }

  // ─── SWIPE ────────────────────────────────────────────────────────────────

  Offset? _swipeStart;

  void _onPanStart(DragStartDetails d) => _swipeStart = d.globalPosition;

  void _onPanEnd(DragEndDetails d) {
    if (_swipeStart == null) return;
    final vel = d.velocity.pixelsPerSecond;
    if (vel.dx.abs() > vel.dy.abs()) {
      _game.setNextDir(vel.dx > 0 ? Direction.right : Direction.left);
    } else {
      _game.setNextDir(vel.dy > 0 ? Direction.down : Direction.up);
    }
    _swipeStart = null;
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: kColorBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHUD(),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanEnd: _onPanEnd,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildCanvas(),
                        if (_game.state != GameState.playing &&
                            _game.state != GameState.respawning)
                          _buildOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildControls(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HUD ─────────────────────────────────────────────────────────────────

  Widget _buildHUD() {
    return AnimatedBuilder(
      animation: _hudPulse,
      builder: (_, __) {
        final glow = 0.6 + 0.4 * _hudPulse.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: kColorHUD.withOpacity(0.3), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pontuação
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PONTOS', style: _hudLabelStyle),
                  Text(
                    '${_game.score}'.padLeft(6, '0'),
                    style: GoogleFonts.pressStart2p(
                      fontSize: 14,
                      color: kColorScore,
                      shadows: [Shadow(color: kColorScore.withOpacity(glow), blurRadius: 8)],
                    ),
                  ),
                ],
              ),
              // Vidas
              Column(
                children: [
                  Text('NÍVEL ${_game.level}', style: _hudLabelStyle),
                  const SizedBox(height: 2),
                  Row(
                    children: List.generate(
                      _game.lives,
                      (_) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.circle, color: kColorPlayer, size: 10),
                      ),
                    ),
                  ),
                ],
              ),
              // High Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('RECORDE', style: _hudLabelStyle),
                  Text(
                    '${_game.highScore}'.padLeft(6, '0'),
                    style: GoogleFonts.pressStart2p(
                      fontSize: 14,
                      color: kColorHUD,
                      shadows: [Shadow(color: kColorHUD.withOpacity(glow), blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  TextStyle get _hudLabelStyle => GoogleFonts.pressStart2p(
        fontSize: 7,
        color: kColorHUD.withOpacity(0.65),
        letterSpacing: 1,
      );

  // ─── CANVAS ───────────────────────────────────────────────────────────────

  Widget _buildCanvas() {
    final w = kCols * kCell;
    final h = kRows * kCell;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: GamePainter(game: _game, tick: _tick),
        size: Size(w, h),
      ),
    );
  }

  // ─── OVERLAYS ─────────────────────────────────────────────────────────────

  Widget _buildOverlay() {
    switch (_game.state) {
      case GameState.menu:
        return _menuOverlay();
      case GameState.paused:
        return _pauseOverlay();
      case GameState.gameOver:
        return _gameOverOverlay();
      case GameState.levelUp:
        return _levelUpOverlay();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _overlayBase({required Widget child}) {
    return Container(
      width: kCols * kCell,
      height: kRows * kCell,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.82),
        border: Border.all(color: kColorWallGlow.withOpacity(0.5), width: 1.5),
      ),
      child: Center(child: child),
    );
  }

  Widget _menuOverlay() {
    return _overlayBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _glowText('SPACE', 24, kColorHUD),
          _glowText('PAC-MAN', 28, kColorPlayer),
          const SizedBox(height: 20),
          _neonDivider(),
          const SizedBox(height: 16),
          _menuInfo('🚀', 'NAVE AMARELA', 'Você controla'),
          const SizedBox(height: 8),
          _menuInfo('👾', 'ALIENS', '4 inimigos com IA'),
          _menuInfo('⚡', 'POWER PELLET', 'Come os aliens por 3s'),
          _menuInfo('🎯', 'OBJETIVO', 'Coletar todos os pontos'),
          const SizedBox(height: 16),
          _neonDivider(),
          const SizedBox(height: 16),
          _buildNeonButton('INICIAR MISSÃO', _game.startGame),
          const SizedBox(height: 12),
          Text(
            '← ↑ ↓ →  ou  WASD  ou  SWIPE',
            style: GoogleFonts.pressStart2p(fontSize: 6, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _pauseOverlay() {
    return _overlayBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _glowText('PAUSADO', 22, kColorHUD),
          const SizedBox(height: 24),
          _buildNeonButton('CONTINUAR', _game.togglePause),
          const SizedBox(height: 12),
          _buildNeonButton('RECOMEÇAR', _game.startGame, secondary: true),
        ],
      ),
    );
  }

  Widget _gameOverOverlay() {
    return _overlayBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _glowText('GAME OVER', 20, Colors.redAccent),
          const SizedBox(height: 16),
          _neonDivider(),
          const SizedBox(height: 12),
          _statRow('PONTUAÇÃO', '${_game.score}'.padLeft(6, '0'), kColorScore),
          _statRow('RECORDE', '${_game.highScore}'.padLeft(6, '0'), kColorHUD),
          _statRow('NÍVEL', '${_game.level}', Colors.white70),
          const SizedBox(height: 16),
          _neonDivider(),
          const SizedBox(height: 16),
          _buildNeonButton('TENTAR NOVAMENTE', _game.restartFromGameOver),
        ],
      ),
    );
  }

  Widget _levelUpOverlay() {
    return _overlayBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _glowText('NÍVEL', 16, kColorHUD),
          _glowText('COMPLETO!', 22, kColorPlayer),
          const SizedBox(height: 16),
          _glowText('NÍVEL ${_game.level}', 30, kColorPower),
          const SizedBox(height: 8),
          Text(
            'Aliens ficam mais rápidos!',
            style: GoogleFonts.pressStart2p(fontSize: 7, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── CONTROLES TOUCH ──────────────────────────────────────────────────────

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          // Pausa
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dirButton(Icons.keyboard_arrow_up, Direction.up),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (_game.state == GameState.playing || _game.state == GameState.paused) {
                    _game.togglePause();
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    border: Border.all(color: kColorHUD.withOpacity(0.5), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                    color: kColorBg,
                  ),
                  child: Icon(
                    _game.state == GameState.paused ? Icons.play_arrow : Icons.pause,
                    color: kColorHUD,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dirButton(Icons.keyboard_arrow_left, Direction.left),
              const SizedBox(width: 4),
              _dirButton(Icons.keyboard_arrow_down, Direction.down),
              const SizedBox(width: 4),
              _dirButton(Icons.keyboard_arrow_right, Direction.right),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dirButton(IconData icon, Direction dir) {
    final isActive = _game.player.direction == dir;
    return GestureDetector(
      onTap: () => _game.setNextDir(dir),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? kColorWallGlow : kColorWallGlow.withOpacity(0.4),
            width: isActive ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isActive ? kColorWallGlow.withOpacity(0.2) : kColorBg,
          boxShadow: isActive
              ? [BoxShadow(color: kColorWallGlow.withOpacity(0.4), blurRadius: 8)]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? kColorWallGlow : Colors.white54,
          size: 28,
        ),
      ),
    );
  }

  // ─── WIDGETS AUXILIARES ──────────────────────────────────────────────────

  Widget _glowText(String t, double size, Color color) {
    return Text(
      t,
      style: GoogleFonts.pressStart2p(
        fontSize: size,
        color: color,
        shadows: [
          Shadow(color: color.withOpacity(0.8), blurRadius: 12),
          Shadow(color: color.withOpacity(0.4), blurRadius: 24),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _neonDivider() {
    return Container(
      height: 1,
      width: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.transparent,
          kColorWallGlow.withOpacity(0.8),
          Colors.transparent,
        ]),
      ),
    );
  }

  Widget _menuInfo(String emoji, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white70)),
              Text(sub, style: GoogleFonts.pressStart2p(fontSize: 6, color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: GoogleFonts.pressStart2p(fontSize: 7, color: Colors.white38)),
          ),
          Text(value, style: GoogleFonts.pressStart2p(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildNeonButton(String label, VoidCallback onTap, {bool secondary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: secondary ? kColorWallGlow.withOpacity(0.5) : kColorPlayer,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
          color: secondary ? Colors.transparent : kColorPlayer.withOpacity(0.15),
          boxShadow: secondary
              ? null
              : [BoxShadow(color: kColorPlayer.withOpacity(0.3), blurRadius: 12)],
        ),
        child: Text(
          label,
          style: GoogleFonts.pressStart2p(
            fontSize: 9,
            color: secondary ? Colors.white54 : kColorPlayer,
            shadows: secondary
                ? null
                : [Shadow(color: kColorPlayer.withOpacity(0.8), blurRadius: 6)],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}