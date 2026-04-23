import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
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

  // Pages for bottom navigation
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildHomePage(),
      const CommunityScreen(),
      const WellbeingScreen(),
      const SosScreen(),
      const ProfileScreen(),
    ];
  }

  void _onNavTap(int index) {
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
      body: IndexedStack(index: _currentIndex, children: _pages),
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
                avatarImagePath: 'assets/images/home/Avatar.png',
                onAvatarTap: _onAvatarTap,
              ),

              const SizedBox(height: 32),

              // ── Period Tracker Section ───────────────────────────────
              _buildSectionHeader(
                title: 'Period Tracker',
                onViewMore: _onViewMorePeriodTracker,
              ),

              const SizedBox(height: 16),

              PeriodTrackerCard(
                onGetStarted: _onPeriodTrackerTap,
                imageAsset: 'assets/images/home/Period girl.png',
              ),

              const SizedBox(height: 32),

              // ── Mental Wellbeing Section ─────────────────────────────
              _buildSectionHeader(
                title: 'Mental Wellbeing',
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
                title: 'Pregnancy',
                onViewMore: _onViewMorePregnancy,
              ),

              const SizedBox(height: 16),

              PregnancySection(
                onGetStarted: _onGetStartedPregnancy,
                onViewMore: _onViewMorePregnancy,
                imageAsset: 'assets/images/home/pregnancypic_home.png',
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
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
            'view more',
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
