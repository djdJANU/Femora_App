import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

/// Greeting header widget for the home screen
/// Shows user's name and welcome message with profile avatar
class GreetingHeader extends StatelessWidget {
  final String userName;
  final String? avatarImagePath;
  final VoidCallback? onAvatarTap;

  const GreetingHeader({
    super.key,
    required this.userName,
    this.avatarImagePath,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey, $userName',
                style: FemoraTextStyles.headlineLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: FemoraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome to Femora',
                style: FemoraTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color: FemoraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Right side: Profile avatar
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: FemoraColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: FemoraColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarImagePath != null
                  ? Image.asset(
                      avatarImagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FemoraColors.primary.withValues(alpha: 0.8),
            FemoraColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: FemoraTextStyles.headlineLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
