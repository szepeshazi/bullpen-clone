import 'package:flutter/material.dart';

import '../widgets/main/bullpen_title.dart';
import '../widgets/main/size_selector.dart';
import '../widgets/main/start_button.dart';
import 'game_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  /// Route that re-enters the main page (used after game completion or back).
  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => const MainPage(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedSize = 8;

  void _startGame() {
    Navigator.of(context).pushReplacement(GamePage.route(_selectedSize));
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.height < 700;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: compact ? 24 : 48),
            BullpenTitle(compact: compact),
            SizedBox(height: compact ? 20 : 40),
            Expanded(
              child: SizeSelector(
                selectedSize: _selectedSize,
                onSizeChanged: (size) => setState(() => _selectedSize = size),
              ),
            ),
            SizedBox(height: compact ? 12 : 24),
            StartButton(onPressed: _startGame),
            SizedBox(height: compact ? 24 : 48),
          ],
        ),
      ),
    );
  }
}
