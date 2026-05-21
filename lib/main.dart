import 'package:bullpen/pages/main_page.dart';
import 'package:bullpen/theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BullpenApp());
}

class BullpenApp extends StatelessWidget {
  const BullpenApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
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
