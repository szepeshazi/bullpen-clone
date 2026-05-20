import 'package:flutter/material.dart';

import 'pages/main_page.dart';
import 'theme.dart';

void main() {
  runApp(const BullpenApp());
}

class BullpenApp extends StatelessWidget {
  const BullpenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bullpen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: bullpenBgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: bullpenAccentColor,
          surface: bullpenBgColor,
        ),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}
