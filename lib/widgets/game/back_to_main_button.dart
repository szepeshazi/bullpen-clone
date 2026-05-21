import 'package:bullpen/pages/main_page.dart';
import 'package:bullpen/theme.dart';
import 'package:flutter/material.dart';

class BackToMainButton extends StatelessWidget {
  const BackToMainButton({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
      onPressed: () => Navigator.of(context).pushReplacement(MainPage.route()),
      icon: const Icon(Icons.arrow_back, size: 18),
      label: const Text('Back to Main Page'),
      style: TextButton.styleFrom(
        foregroundColor: bullpenAccentColor,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
}
