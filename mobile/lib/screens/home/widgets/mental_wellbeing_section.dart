import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';

enum MoodType { happy, angry, sad }

class MentalWellbeingSection extends StatefulWidget {
  final String? happyEmojiAsset;
  final String? neutralEmojiAsset;
  final String? sadEmojiAsset;
  final Function(MoodType)? onMoodSelected;

  const MentalWellbeingSection({
    super.key,
    this.happyEmojiAsset,
    this.neutralEmojiAsset,
    this.sadEmojiAsset,
    this.onMoodSelected,
  });

  @override
  State<MentalWellbeingSection> createState() => _MentalWellbeingSectionState();
}

class _MentalWellbeingSectionState extends State<MentalWellbeingSection> {
  int _selectedMoodIndex = 0;

  final List<String> _defaultEmojis = ['😊', '😠', '😢'];

  void _selectMood(int index) {
    setState(() {
      _selectedMoodIndex = index;
    });

    if (widget.onMoodSelected != null) {
      final mood = index == 0
          ? MoodType.happy
          : index == 1
          ? MoodType.angry
          : MoodType.sad;
      widget.onMoodSelected!(mood);
    }
  }

  void _onLeftArrow() {
    final newIndex = (_selectedMoodIndex - 1) % 3;
    _selectMood(newIndex < 0 ? 2 : newIndex);
  }

  void _onRightArrow() {
    final newIndex = (_selectedMoodIndex + 1) % 3;
    _selectMood(newIndex);
  }

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
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/lumi/lumi_wellbeing.png',
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(height: 80),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.homeChooseMood ?? 'Choose your mood',
            style: FemoraTextStyles.titleLarge.copyWith(
              color: FemoraColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // FIXED ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _onLeftArrow,
                icon: const Icon(Icons.chevron_left_rounded),
                color: FemoraColors.primary,
                iconSize: 28,
              ),

              // Wrap emojis with Expanded to prevent overflow
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMoodEmoji(0),
                    _buildMoodEmoji(1),
                    _buildMoodEmoji(2),
                  ],
                ),
              ),

              IconButton(
                onPressed: _onRightArrow,
                icon: const Icon(Icons.chevron_right_rounded),
                color: FemoraColors.primary,
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEmoji(int index) {
    final isSelected = index == _selectedMoodIndex;

    return GestureDetector(
      onTap: () => _selectMood(index),
      child: AnimatedScale(
        scale: isSelected ? 1.3 : 1.0, // scale instead of resize
        duration: FemoraAnimations.fast,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isSelected ? 1.0 : 0.5,
          duration: FemoraAnimations.fast,
          child: SizedBox(
            width: 60, // FIXED WIDTH
            height: 60, // FIXED HEIGHT
            child: _buildEmojiContent(index),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiContent(int index) {
    if (index == 0 && widget.happyEmojiAsset != null) {
      return Image.asset(widget.happyEmojiAsset!, fit: BoxFit.contain);
    } else if (index == 1 && widget.neutralEmojiAsset != null) {
      return Image.asset(widget.neutralEmojiAsset!, fit: BoxFit.contain);
    } else if (index == 2 && widget.sadEmojiAsset != null) {
      return Image.asset(widget.sadEmojiAsset!, fit: BoxFit.contain);
    } else {
      return Center(
        child: Text(
          _defaultEmojis[index],
          style: const TextStyle(fontSize: 36),
        ),
      );
    }
  }
}
