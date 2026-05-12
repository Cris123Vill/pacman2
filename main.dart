import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_page.dart';
 
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpacePacmanApp());
}
 
class SpacePacmanApp extends StatelessWidget {
  const SpacePacmanApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Space Pac-Man',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000010),
        textTheme: GoogleFonts.pressStart2pTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const GamePage(),
    );
  }
}
 