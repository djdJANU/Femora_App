// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../femi/femi_screen.dart';
import '../reproductive/reproductive_health_screen.dart';
import 'widgets/greeting_header.dart';
import 'widgets/period_tracker_card.dart';
import 'widgets/mental_wellbeing_section.dart';
import 'widgets/pregnancy_section.dart';
import 'widgets/bottom_nav_bar.dart';
import 'dummy_pages/wellbeing_screen.dart';
import '../wellbeing/mood_tracker_screen.dart';
import 'dummy_pages/community_screen.dart';
import 'dummy_pages/sos_screen.dart';
import 'dummy_pages/profile_screen.dart';

/// Main Home Screen - landing page after authentication
/// Features:
/// - Greeting header with user's name and avatar
/// - Period tracker card with CTA
/// - Mental wellbeing mood selector
/// - Custom bottom navigation bar
/// - Page switching via IndexedStack
class HomeScreen extends StatefulWidget {
  final String? userName;

  const HomeScreen({super.key, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
  }

  Future<void> _loadAvatarUrl() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final response = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      final url = response?['avatar_url'] as String?;
      if (mounted) {
        setState(() {
          _avatarUrl = url;
        });
      }
    } catch (_) {}
  }

  void _onNavTap(int index) {
    if (index == 0 && _currentIndex != 0) {
      _loadAvatarUrl();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAvatarTap() {
    // Navigate to profile
    setState(() {
      _currentIndex = 4;
    });
  }

  void _onPeriodTrackerTap() {
    // Navigate to Period tab in Reproductive Health screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReproductiveHealthScreen(initialTab: 0),
      ),
    );
  }

  void _onViewMorePeriodTracker() {
    // Navigate to Period tab in Reproductive Health screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReproductiveHealthScreen(initialTab: 0),
      ),
    );
  }

  void _onViewMoreWellbeing() {
    // Navigate to wellbeing screen
    setState(() {
      _currentIndex = 2;
    });
  }

  void _onGetStartedPregnancy() {
    // Navigate to Pregnancy tab in Reproductive Health screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReproductiveHealthScreen(initialTab: 1),
      ),
    );
  }

  void _onViewMorePregnancy() {
    // Navigate to Pregnancy tab in Reproductive Health screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReproductiveHealthScreen(initialTab: 1),
      ),
    );
  }

  void _onMoodSelected(dynamic mood) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MoodTrackerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          const CommunityScreen(),
          const WellbeingScreen(),
          const SosScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  /// Builds the main home page content
  Widget _buildHomePage() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Greeting Header ──────────────────────────────────────
              GreetingHeader(
                userName: widget.userName ?? 'Dilakna',
                avatarUrl: _avatarUrl,
                onAvatarTap: _onAvatarTap,
              ),

              const SizedBox(height: 32),

              // ── Femi (Lumi) greeting card ────────────────────────────
              _buildLumiGreetingCard(),

              const SizedBox(height: 24),

              // ── Period Tracker Section ───────────────────────────────
              _buildSectionHeader(
                title: AppLocalizations.of(context)?.homeSectionPeriod ??
                    'Period Tracker',
                onViewMore: _onViewMorePeriodTracker,
              ),

              const SizedBox(height: 16),

              PeriodTrackerCard(
                onGetStarted: _onPeriodTrackerTap,
                imageAsset: 'assets/images/lumi/lumi_period.png',
              ),

              const SizedBox(height: 32),

              // ── Mental Wellbeing Section ─────────────────────────────
              _buildSectionHeader(
                title: AppLocalizations.of(context)?.wellbeingTabTitle ??
                    'Mental Wellbeing',
                onViewMore: _onViewMoreWellbeing,
              ),

              const SizedBox(height: 16),

              MentalWellbeingSection(
                happyEmojiAsset: 'assets/images/mood/Happy.png',
                neutralEmojiAsset: 'assets/images/mood/Angry.png',
                sadEmojiAsset: 'assets/images/mood/Sad.png',
                onMoodSelected: _onMoodSelected,
              ),

              const SizedBox(height: 32),

              // ── Pregnancy Section ───────────────────────────────────
              _buildSectionHeader(
                title: AppLocalizations.of(context)?.homeSectionPregnancy ??
                    'Pregnancy',
                onViewMore: _onViewMorePregnancy,
              ),

              const SizedBox(height: 16),

              PregnancySection(
                onGetStarted: _onGetStartedPregnancy,
                onViewMore: _onViewMorePregnancy,
                imageAsset: 'assets/images/lumi/lumi_pregnancy.png',
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the tappable Femi/Lumi greeting card
  Widget _buildLumiGreetingCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FemiScreen()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card background — left padding reserves space for Lumi
          Container(
            padding: const EdgeInsets.fromLTRB(124, 16, 16, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9B59F5), Color(0xFFA66CFF)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA66CFF).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.homeFemiTitle ??
                      'Talk to Femi 💜',
                  style: FemoraTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.homeFemiSubtitle ??
                      'Your AI wellness companion — ask me anything about your health, mood, or cycle.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FemoraTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.88),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.homeFemiButton ??
                        'Chat now →',
                    style: FemoraTextStyles.caption.copyWith(
                      color: FemoraColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lumi overflows 20px above the card top, 10px gap at bottom
          Positioned(
            left: 4,
            top: -20,
            bottom: 10,
            width: 132,
            child: Image.asset(
              'assets/images/lumi/lumi_wave.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, _, _) =>
                  const Text('💜', style: TextStyle(fontSize: 50)),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a section header with title and "view more" link
  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewMore,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: FemoraTextStyles.headlineMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: FemoraColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onViewMore,
          child: Text(
            AppLocalizations.of(context)?.homeViewMore ?? 'view more',
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
