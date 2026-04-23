import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

/// Period tracker card widget for the home screen
/// Shows period tracking information with an image and CTA button
class PeriodTrackerCard extends StatelessWidget {
  final VoidCallback onGetStarted;
  final String? imageAsset;

  const PeriodTrackerCard({
    super.key,
    required this.onGetStarted,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FemoraColors.lavenderWhisper,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side: Image
          if (imageAsset != null)
            Image.asset(
              imageAsset!,
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 110,
                width: 90,
                decoration: BoxDecoration(
                  color: FemoraColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: FemoraColors.primary,
                  size: 40,
                ),
              ),
            )
          else
            Container(
              height: 110,
              width: 90,
              decoration: BoxDecoration(
                color: FemoraColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: FemoraColors.primary,
                size: 40,
              ),
            ),

          const SizedBox(width: 16),

          // Right side: Text and Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Track your cycle and get personalized insights',
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: FemoraColors.textPrimary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Gradient button
                GestureDetector(
                  onTap: onGetStarted,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD689FF), Color(0xFF9667E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9667E0).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Get started',
                        style: FemoraTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
