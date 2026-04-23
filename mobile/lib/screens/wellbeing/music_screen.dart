// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Music & Calm Screen
/// ────────────────────
/// Curated YouTube playlist links organised by category.
/// No API, no auth — simple and reliable.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  String _selectedCategory = 'sleep';

  // ── Curated playlist data ─────────────────────────────────────────────────
  static const _playlists = {
    'sleep': [
      _Track(
        title: 'Peaceful Sleep Music',
        description: '3 hours of calming sounds for deep sleep',
        emoji: '🌙',
        url: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
        duration: '3 hr',
      ),
      _Track(
        title: 'Rain Sounds for Sleep',
        description: 'Gentle rain to help you drift off',
        emoji: '🌧️',
        url: 'https://www.youtube.com/watch?v=q76bMs-NwRk',
        duration: '8 hr',
      ),
      _Track(
        title: 'Soft Piano Sleep Music',
        description: 'Relaxing piano melodies for bedtime',
        emoji: '🎹',
        url: 'https://www.youtube.com/watch?v=APKbCfL_Rao',
        duration: '2 hr',
      ),
    ],
    'anxiety': [
      _Track(
        title: 'Anxiety Relief Music',
        description: 'Calming frequencies to ease worry',
        emoji: '🌊',
        url: 'https://www.youtube.com/watch?v=WHPEKLQID4U',
        duration: '1 hr',
      ),
      _Track(
        title: 'Nature Sounds for Calm',
        description: 'Forest birds and flowing water',
        emoji: '🌿',
        url: 'https://www.youtube.com/watch?v=eKFTSSKCzWA',
        duration: '3 hr',
      ),
      _Track(
        title: 'Stress Relief Meditation',
        description: 'Guided sounds to release tension',
        emoji: '✨',
        url: 'https://www.youtube.com/watch?v=inpok4MKVLM',
        duration: '45 min',
      ),
    ],
    'focus': [
      _Track(
        title: 'Deep Focus Music',
        description: 'Lo-fi beats to help you concentrate',
        emoji: '🎧',
        url: 'https://www.youtube.com/watch?v=5qap5aO4i9A',
        duration: 'Live',
      ),
      _Track(
        title: 'Study with Me — Calm Piano',
        description: 'Peaceful background music for work',
        emoji: '📖',
        url: 'https://www.youtube.com/watch?v=sjkrrmBnpGE',
        duration: '3 hr',
      ),
      _Track(
        title: 'Brown Noise for Focus',
        description: 'Steady noise to block distractions',
        emoji: '🔇',
        url: 'https://www.youtube.com/watch?v=RqzGzwTY-6w',
        duration: '10 hr',
      ),
    ],
    'meditation': [
      _Track(
        title: 'Morning Meditation Music',
        description: 'Gentle tones to start your day',
        emoji: '☀️',
        url: 'https://www.youtube.com/watch?v=rqG8tOi74SE',
        duration: '30 min',
      ),
      _Track(
        title: 'Tibetan Singing Bowls',
        description: 'Ancient healing frequencies',
        emoji: '🎵',
        url: 'https://www.youtube.com/watch?v=XqZsoesa55w',
        duration: '1 hr',
      ),
      _Track(
        title: 'Chakra Healing Music',
        description: 'Balancing frequencies for inner peace',
        emoji: '🌸',
        url: 'https://www.youtube.com/watch?v=Jyy0ra2WcQQ',
        duration: '3 hr',
      ),
    ],
  };

  static const _categories = [
    _Category(key: 'sleep',      emoji: '🌙'),
    _Category(key: 'anxiety',    emoji: '🌊'),
    _Category(key: 'focus',      emoji: '🎧'),
    _Category(key: 'meditation', emoji: '🌸'),
  ];

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link. Please try again.'),
            backgroundColor: FemoraColors.error,
          ),
        );
      }
    }
  }

  String _categoryLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'sleep':      return l10n.musicCategorySleep;
      case 'anxiety':    return l10n.musicCategoryAnxiety;
      case 'focus':      return l10n.musicCategoryFocus;
      case 'meditation': return l10n.musicCategoryMeditation;
      default:           return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tracks = _playlists[_selectedCategory] ?? [];

    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _buildHeader(l10n),

            // ── Category chips ───────────────────────────────────
            _buildCategoryChips(context),

            // ── Track list ───────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: tracks.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _buildTrackCard(tracks[i], l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FemoraColors.lightBackgroundTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: FemoraColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.musicTitle,
                  style: FemoraTextStyles.titleLarge.copyWith(
                    color: FemoraColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.musicSubtitle,
                  style: FemoraTextStyles.caption.copyWith(
                    color: FemoraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ]),
          Container(
            margin: const EdgeInsets.only(top: 14),
            height: 1,
            color: FemoraColors.lavenderWhisper,
          ),
        ],
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────

  Widget _buildCategoryChips(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((cat) {
            final selected = _selectedCategory == cat.key;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = cat.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? FemoraColors.primary
                        : FemoraColors.lightBackgroundTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? FemoraColors.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(children: [
                    Text(cat.emoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      _categoryLabel(context, cat.key),
                      style: FemoraTextStyles.caption.copyWith(
                        color: selected
                            ? Colors.white
                            : FemoraColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Track card ────────────────────────────────────────────────────────────

  Widget _buildTrackCard(_Track track, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Emoji icon
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: FemoraColors.lavenderWhisper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(track.emoji,
                style: const TextStyle(fontSize: 24)),
          ),
        ),

        const SizedBox(width: 14),

        // Title + description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                track.description,
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              // Duration chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FemoraColors.lightBackgroundTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  track.duration,
                  style: FemoraTextStyles.caption.copyWith(
                    color: FemoraColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Open button
        GestureDetector(
          onTap: () => _openLink(track.url),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FemoraColors.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: FemoraColors.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _Track {
  final String title;
  final String description;
  final String emoji;
  final String url;
  final String duration;

  const _Track({
    required this.title,
    required this.description,
    required this.emoji,
    required this.url,
    required this.duration,
  });
}

class _Category {
  final String key;
  final String emoji;

  const _Category({required this.key, required this.emoji});
}
