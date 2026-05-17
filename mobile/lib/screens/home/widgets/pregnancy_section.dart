import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Pregnancy section widget for the home screen
/// Shows pregnancy tracking information with an image and CTA button
class PregnancySection extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onViewMore;
  final String? imageAsset;

  const PregnancySection({
    super.key,
    required this.onGetStarted,
    required this.onViewMore,
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
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120,
                width: 100,
                decoration: BoxDecoration(
                  color: FemoraColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pregnant_woman_rounded,
                  color: FemoraColors.primary,
                  size: 45,
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: 100,
              decoration: BoxDecoration(
                color: FemoraColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pregnant_woman_rounded,
                color: FemoraColors.primary,
                size: 45,
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
                  AppLocalizations.of(context)?.homePregnancyDescription ??
                      'Track your pregnancy period with Femora',
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
                        AppLocalizations.of(context)?.homeGetStarted ??
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
