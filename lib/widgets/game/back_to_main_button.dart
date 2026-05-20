import 'package:flutter/material.dart';

import '../../pages/main_page.dart';
import '../../theme.dart';

class BackToMainButton extends StatelessWidget {
  const BackToMainButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
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
}
