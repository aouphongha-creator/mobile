import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../state/app_state.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'plan_screen.dart';

/// Hosts the three tabs and the white rounded bottom bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openTrip(String tripId) {
    AppScope.read(context).selectTrip(tripId);
    setState(() => _index = 1);
  }

  @override
  Widget build(BuildContext context) {
    final error = AppScope.of(context).takeSyncError();
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenTrip: _openTrip),
          PlanScreen(onBack: () => setState(() => _index = 0)),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.explore, 'Detail'),
    (Icons.addchart_rounded, 'History'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final (i, (icon, label)) in _items.indexed)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 26,
                          color: i == index ? AppColors.blue : AppColors.navy,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: i == index ? AppColors.blue : AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
