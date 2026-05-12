import 'package:flutter/material.dart';

// ─── GRID ────────────────────────────────────────────────────────────────────
const int kCols = 19;
const int kRows = 21;
const double kCell = 22.0;

// ─── CÉLULAS ─────────────────────────────────────────────────────────────────
const int kEmpty = 0;
const int kWall = 1;
const int kDot = 2;
const int kPower = 3;
const int kEaten = 4;
const int kTunnel = 5; // túnel lateral

// ─── CORES ESPACIAIS ─────────────────────────────────────────────────────────
const Color kColorBg = Color(0xFF000010);
const Color kColorWall = Color(0xFF0D0D6B);
const Color kColorWallGlow = Color(0xFF3333FF);
const Color kColorDot = Color(0xFF88CCFF);
const Color kColorPower = Color(0xFF00FFFF);
const Color kColorPlayer = Color(0xFFFFE000);
const Color kColorPlayerGlow = Color(0xFFFFAA00);
const Color kColorHUD = Color(0xFF00FFFF);
const Color kColorScore = Color(0xFFFFE000);
const Color kColorFrightened = Color(0xFF0000CC);
const Color kColorFrightenedFlash = Color(0xFFFFFFFF);

// Cores dos aliens (fantasmas)
const List<Color> kGhostColors = [
  Color(0xFFFF3333), // Vermelho - Alienígena Caçador
  Color(0xFFFF88FF), // Rosa    - Alienígena Emboscador
  Color(0xFF00FFFF), // Ciano   - Alienígena Interceptor
  Color(0xFFFFAA00), // Laranja - Alienígena Errante
];

const List<String> kGhostNames = [
  'CAÇADOR',
  'EMBOSCADOR',
  'INTERCEPTOR',
  'ERRANTE',
];

// ─── POSIÇÕES INICIAIS DOS ALIENS ─────────────────────────────────────────────
const List<Map<String, int>> kGhostStarts = [
  {'r': 9, 'c': 8},
  {'r': 9, 'c': 9},
  {'r': 9, 'c': 10},
  {'r': 10, 'c': 9},
];

// ─── MAPA BASE (0=vazio,1=parede,2=ponto,3=power,4=comido,5=túnel) ───────────
const List<List<int>> kBaseMap = [
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,2,2,2,2,2,2,2,2,1,2,2,2,2,2,2,2,2,1],
  [1,3,1,1,2,1,1,1,2,1,2,1,1,1,2,1,1,3,1],
  [1,2,1,1,2,1,1,1,2,1,2,1,1,1,2,1,1,2,1],
  [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
  [1,2,1,1,2,1,2,1,1,1,1,1,2,1,2,1,1,2,1],
  [1,2,2,2,2,1,2,2,2,1,2,2,2,1,2,2,2,2,1],
  [1,1,1,1,2,1,1,1,0,0,0,1,1,1,2,1,1,1,1],
  [1,1,1,1,2,1,0,0,0,0,0,0,0,1,2,1,1,1,1],
  [5,5,5,5,2,0,0,1,0,0,0,1,0,0,2,5,5,5,5],
  [5,5,5,5,2,0,0,1,0,0,0,1,0,0,2,5,5,5,5],
  [1,1,1,1,2,0,0,1,1,1,1,1,0,0,2,1,1,1,1],
  [1,1,1,1,2,0,0,0,0,0,0,0,0,0,2,1,1,1,1],
  [1,1,1,1,2,1,0,1,1,1,1,1,0,1,2,1,1,1,1],
  [1,2,2,2,2,2,2,2,2,1,2,2,2,2,2,2,2,2,1],
  [1,2,1,1,2,1,1,1,2,1,2,1,1,1,2,1,1,2,1],
  [1,3,2,1,2,2,2,2,2,0,2,2,2,2,2,1,2,3,1],
  [1,1,2,1,2,1,2,1,1,1,1,1,2,1,2,1,2,1,1],
  [1,2,2,2,2,1,2,2,2,1,2,2,2,1,2,2,2,2,1],
  [1,2,1,1,1,1,1,1,2,1,2,1,1,1,1,1,1,2,1],
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
];

// ─── GAMEPLAY ─────────────────────────────────────────────────────────────────
const int kLives = 3;
const int kScoreDot = 10;
const int kScorePower = 50;
const int kScoreGhost = 200;
const int kFrightDuration = 38; // ticks
const Duration kTickRate = Duration(milliseconds: 75);
const Duration kRespawnDelay = Duration(milliseconds: 1200);