import 'package:flutter/material.dart';

import '../app/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.splash,
      body: Center(
        child: Image(image: AssetImage('assets/images/logo.png'), width: 110),
      ),
    );
  }
}
