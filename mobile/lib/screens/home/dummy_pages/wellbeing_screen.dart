import 'package:flutter/material.dart';
import '../../wellbeing/wellbeing_dashboard.dart';

/// Wellbeing screen — now points to the real dashboard
class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WellbeingDashboard();
  }
}
