import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(JournyApp(state: AppState()));
}

class JournyApp extends StatefulWidget {
  const JournyApp({super.key, required this.state, this.splashDuration = const Duration(milliseconds: 1500)});

  final AppState state;
  final Duration splashDuration;

  @override
  State<JournyApp> createState() => _JournyAppState();
}

class _JournyAppState extends State<JournyApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Show the splash for at least [splashDuration] while data loads.
    Future.wait([
      widget.state.load(),
      Future<void>.delayed(widget.splashDuration),
    ]).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'JORNY OG',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _ready ? const MainShell() : const SplashScreen(),
        ),
      ),
    );
  }
}
