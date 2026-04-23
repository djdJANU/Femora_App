import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          gradient: LinearGradient(
            colors: [Color(0xFFD689FF), Color(0xFF9667E0)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: FemoraColors.textLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
