// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Femora';

  @override
  String get continueButton => 'Continue';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get backButton => 'Back';

  @override
  String get yesButton => 'Yes';

  @override
  String get noButton => 'No';

  @override
  String get doneButton => 'Done';

  @override
  String get skipButton => 'Skip';

  @override
  String get retryButton => 'Try Again';

  @override
  String get languageSelectionTitle => 'Choose Your Language';

  @override
  String get languageSelectionSubtitle =>
      'You can change this anytime in Settings';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSinhala => 'සිංහල';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get wellbeingTabTitle => 'Mental Wellbeing';

  @override
  String get wellbeingDashboardGreeting => 'How are you feeling today?';

  @override
  String get wellbeingDashboardSubtitle =>
      'Your mental health matters. We\'re here for you.';

  @override
  String get phq2ScreenTitle => 'Quick Check-In';

  @override
  String get phq2Instruction =>
      'Over the last 2 weeks, how often have you been bothered by the following?';

  @override
  String get phq2Q1 => 'Little interest or pleasure in doing things';

  @override
  String get phq2Q2 => 'Feeling down, depressed, or hopeless';

  @override
  String get phq2Option0 => 'Not at all';

  @override
  String get phq2Option1 => 'Several days';

  @override
  String get phq2Option2 => 'More than half the days';

  @override
  String get phq2Option3 => 'Nearly every day';

  @override
  String get phq2ResultLow =>
      'You seem to be doing well. Keep taking care of yourself.';

  @override
  String get phq2ResultMild =>
      'It looks like things have been a bit difficult lately. The tools below may help.';

  @override
  String get phq2ResultHigh =>
      'It sounds like you\'ve been struggling. Please know you are not alone — support is available.';

  @override
  String get phq2RetakePrompt =>
      'It\'s been 2 weeks. Would you like to do a quick check-in?';

  @override
  String get phq2Badge => 'Wellness Check';

  @override
  String get moodTrackerTitle => 'Today\'s Mood';

  @override
  String get moodTrackerPrompt => 'How are you feeling right now?';

  @override
  String get moodTrackerNoteHint => 'Add a note (optional)';

  @override
  String get moodTrackerSaved => 'Mood logged ✓';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodAnxious => 'Anxious';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodAngry => 'Angry';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodInsightsTitle => 'Your Mood This Week';

  @override
  String get moodInsightsNoData =>
      'Log your mood for 7 days to see patterns here.';

  @override
  String moodInsightFrequent(String mood) {
    return 'You\'ve been feeling $mood most this week.';
  }

  @override
  String get breathingTitle => 'Breathing Exercise';

  @override
  String get breathingSubtitle => '4-7-8 Technique';

  @override
  String get breathingInhale => 'Inhale';

  @override
  String get breathingHold => 'Hold';

  @override
  String get breathingExhale => 'Exhale';

  @override
  String get breathingInhaleSeconds => 'Breathe in for 4 seconds';

  @override
  String get breathingHoldSeconds => 'Hold for 7 seconds';

  @override
  String get breathingExhaleSeconds => 'Breathe out for 8 seconds';

  @override
  String get breathingStart => 'Begin';

  @override
  String get breathingStop => 'Stop';

  @override
  String get breathingComplete =>
      'Well done. Take a moment to notice how you feel.';

  @override
  String breathingRounds(int count) {
    return '$count rounds';
  }

  @override
  String get musicTitle => 'Calm Music';

  @override
  String get musicSubtitle => 'Curated playlists for your wellbeing';

  @override
  String get musicCategorySleep => 'Sleep';

  @override
  String get musicCategoryAnxiety => 'Anxiety Relief';

  @override
  String get musicCategoryFocus => 'Focus';

  @override
  String get musicCategoryMeditation => 'Meditation';

  @override
  String get musicOpenLink => 'Open in YouTube';

  @override
  String get libraryTitle => 'Library';

  @override
  String get librarySearchHint => 'Search articles...';

  @override
  String get librarySave => 'Save';

  @override
  String get librarySaved => 'Saved';

  @override
  String get libraryShare => 'Share';

  @override
  String get libraryRelatedTopics => 'Related Topics';

  @override
  String get libraryCategories => 'Categories';

  @override
  String get libraryCategoryMentalHealth => 'Mental Health';

  @override
  String get libraryCategoryRelationships => 'Relationships';

  @override
  String get libraryCategorySelfCare => 'Self Care';

  @override
  String get libraryCategoryNutrition => 'Nutrition';

  @override
  String get libraryCategoryFitness => 'Fitness';

  @override
  String get sleepTitle => 'Sleep Tracker';

  @override
  String get sleepQualityPrompt => 'How did you sleep last night?';

  @override
  String get sleepQuality1 => 'Very Poor';

  @override
  String get sleepQuality2 => 'Poor';

  @override
  String get sleepQuality3 => 'Fair';

  @override
  String get sleepQuality4 => 'Good';

  @override
  String get sleepQuality5 => 'Excellent';

  @override
  String get sleepHoursHint => 'Hours slept (e.g. 7.5)';

  @override
  String get sleepNoteHint => 'Any notes about your sleep?';

  @override
  String get sleepSaved => 'Sleep log saved ✓';

  @override
  String sleepAverage(String hours) {
    return '7-day average: $hours hrs';
  }

  @override
  String get crisisTitle => 'Need Support?';

  @override
  String get crisisSubtitle =>
      'You are not alone. Trained counsellors are available right now.';

  @override
  String get crisisCallButton => 'Call Now';

  @override
  String get crisisNIMHName => 'NIMH Sri Lanka';

  @override
  String get crisisNIMHNumber => '1926';

  @override
  String get crisisNIMHDescription =>
      'National Institute of Mental Health — free, 24/7';

  @override
  String get crisisSahanayaName => 'Sahanaya';

  @override
  String get crisisSahanayaNumber => '011-2696666';

  @override
  String get crisisSahanayaDescription => 'Counselling and emotional support';

  @override
  String get crisisBannerMild => 'Feeling overwhelmed? You\'re not alone.';

  @override
  String get crisisBannerHigh =>
      'It looks like you may need some support. Please reach out.';

  @override
  String get crisisBannerLink => 'See support resources →';

  @override
  String get crisisEncouragement =>
      'Reaching out is a sign of strength, not weakness.';

  @override
  String get crisisPrivacyNote =>
      'These calls are confidential. Your safety and privacy matter.';
}
