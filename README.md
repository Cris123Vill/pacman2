🚀 Space Pac-Man
Jogo Pac-Man com tema espacial feito em Flutter para trabalho escolar.

📁 Estrutura dos arquivos
space_pacman/
├── pubspec.yaml
└── lib/
    ├── main.dart           ← Entrada do app
    ├── game_constants.dart ← Todas as constantes (cores, mapa, velocidades)
    ├── game_models.dart    ← Modelos de dados (Player, Ghost, Partícula, Estrela)
    ├── game_service.dart   ← Lógica completa do jogo (movimento, IA, colisão)
    ├── game_painter.dart   ← Desenho 2D com CustomPainter (visual espacial)
    └── game_page.dart      ← Interface: HUD, controles, overlays

▶️ Como rodar no VS Code
1. Pré-requisitos

Flutter SDK instalado (https://flutter.dev/docs/get-started/install)
VS Code com extensão Flutter e Dart instaladas
Um dispositivo conectado ou emulador Android/iOS aberto

2. Criar o projeto
bashflutter create space_pacman
cd space_pacman
3. Substituir os arquivos
Copie todos os arquivos da pasta lib/ e o pubspec.yaml para dentro do projeto criado.
4. Instalar dependências
bashflutter pub get
5. Rodar
bashflutter run
Ou pressione F5 no VS Code com o projeto aberto.

🎮 Como jogar
ControleAção← ↑ ↓ →Mover a naveWASDMover a naveSwipe na telaMover (mobile)Botões na telaMover (touch)P ou ESCPausar/ContinuarBotão pausePausar/Continuar

✨ Funcionalidades

Cenário espacial: fundo negro com estrelas piscando, paredes com brilho neon azul
Nave animada: boca abre/fecha, rotaciona conforme direção, olho e motor visíveis
4 Aliens (fantasmas) com IA diferente:

🔴 Caçador — persegue diretamente com BFS
🩷 Emboscador — antecipa 3 células à frente
🩵 Interceptor — persegue se longe, aleatório se perto
🟠 Errante — movimento aleatório


Power Pellets (⚡): assusta todos os aliens por alguns segundos
Barra de poder: mostra tempo restante do efeito
Combo de aliens: comer vários aliens seguidos vale mais pontos
Partículas visuais: explosões coloridas ao comer pontos, aliens e ao morrer
Textos flutuantes: pontuação aparece no local do evento
HUD neon: pontos, recorde pessoal e número de vidas
Pausa com botão e teclado
Sistema de níveis: ao limpar o mapa, próximo nível com aliens mais rápidos
Game Over com placar final e recorde salvo
Tela de menu com explicação dos controles e elementos
Swipe para mobile
Túnel lateral: atravessa de um lado ao outro do mapa


🛠️ Dependências
yamlgoogle_fonts: ^6.1.0   # Fonte "Press Start 2P" (estilo arcade)