import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Femora'**
  String get appName;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @yesButton.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesButton;

  /// No description provided for @noButton.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noButton;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retryButton;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get languageSelectionTitle;

  /// No description provided for @languageSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings'**
  String get languageSelectionSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSinhala.
  ///
  /// In en, this message translates to:
  /// **'සිංහල'**
  String get languageSinhala;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// No description provided for @wellbeingTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Mental Wellbeing'**
  String get wellbeingTabTitle;

  /// No description provided for @wellbeingDashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get wellbeingDashboardGreeting;

  /// No description provided for @wellbeingDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your mental health matters. We\'re here for you.'**
  String get wellbeingDashboardSubtitle;

  /// No description provided for @phq2ScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Check-In'**
  String get phq2ScreenTitle;

  /// No description provided for @phq2Instruction.
  ///
  /// In en, this message translates to:
  /// **'Over the last 2 weeks, how often have you been bothered by the following?'**
  String get phq2Instruction;

  /// No description provided for @phq2Q1.
  ///
  /// In en, this message translates to:
  /// **'Little interest or pleasure in doing things'**
  String get phq2Q1;

  /// No description provided for @phq2Q2.
  ///
  /// In en, this message translates to:
  /// **'Feeling down, depressed, or hopeless'**
  String get phq2Q2;

  /// No description provided for @phq2Option0.
  ///
  /// In en, this message translates to:
  /// **'Not at all'**
  String get phq2Option0;

  /// No description provided for @phq2Option1.
  ///
  /// In en, this message translates to:
  /// **'Several days'**
  String get phq2Option1;

  /// No description provided for @phq2Option2.
  ///
  /// In en, this message translates to:
  /// **'More than half the days'**
  String get phq2Option2;

  /// No description provided for @phq2Option3.
  ///
  /// In en, this message translates to:
  /// **'Nearly every day'**
  String get phq2Option3;

  /// No description provided for @phq2ResultLow.
  ///
  /// In en, this message translates to:
  /// **'You seem to be doing well. Keep taking care of yourself.'**
  String get phq2ResultLow;

  /// No description provided for @phq2ResultMild.
  ///
  /// In en, this message translates to:
  /// **'It looks like things have been a bit difficult lately. The tools below may help.'**
  String get phq2ResultMild;

  /// No description provided for @phq2ResultHigh.
  ///
  /// In en, this message translates to:
  /// **'It sounds like you\'ve been struggling. Please know you are not alone — support is available.'**
  String get phq2ResultHigh;

  /// No description provided for @phq2RetakePrompt.
  ///
  /// In en, this message translates to:
  /// **'It\'s been 2 weeks. Would you like to do a quick check-in?'**
  String get phq2RetakePrompt;

  /// No description provided for @phq2Badge.
  ///
  /// In en, this message translates to:
  /// **'Wellness Check'**
  String get phq2Badge;

  /// No description provided for @moodTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Mood'**
  String get moodTrackerTitle;

  /// No description provided for @moodTrackerPrompt.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling right now?'**
  String get moodTrackerPrompt;

  /// No description provided for @moodTrackerNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get moodTrackerNoteHint;

  /// No description provided for @moodTrackerSaved.
  ///
  /// In en, this message translates to:
  /// **'Mood logged ✓'**
  String get moodTrackerSaved;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodCalm;

  /// No description provided for @moodAnxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get moodAnxious;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get moodAngry;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodTired;

  /// No description provided for @moodInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Mood This Week'**
  String get moodInsightsTitle;

  /// No description provided for @moodInsightsNoData.
  ///
  /// In en, this message translates to:
  /// **'Log your mood for 7 days to see patterns here.'**
  String get moodInsightsNoData;

  /// No description provided for @moodInsightFrequent.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been feeling {mood} most this week.'**
  String moodInsightFrequent(String mood);

  /// No description provided for @breathingTitle.
  ///
  /// In en, this message translates to:
  /// **'Breathing Exercise'**
  String get breathingTitle;

  /// No description provided for @breathingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'4-7-8 Technique'**
  String get breathingSubtitle;

  /// No description provided for @breathingInhale.
  ///
  /// In en, this message translates to:
  /// **'Inhale'**
  String get breathingInhale;

  /// No description provided for @breathingHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get breathingHold;

  /// No description provided for @breathingExhale.
  ///
  /// In en, this message translates to:
  /// **'Exhale'**
  String get breathingExhale;

  /// No description provided for @breathingInhaleSeconds.
  ///
  /// In en, this message translates to:
  /// **'Breathe in for 4 seconds'**
  String get breathingInhaleSeconds;

  /// No description provided for @breathingHoldSeconds.
  ///
  /// In en, this message translates to:
  /// **'Hold for 7 seconds'**
  String get breathingHoldSeconds;

  /// No description provided for @breathingExhaleSeconds.
  ///
  /// In en, this message translates to:
  /// **'Breathe out for 8 seconds'**
  String get breathingExhaleSeconds;

  /// No description provided for @breathingStart.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get breathingStart;

  /// No description provided for @breathingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get breathingStop;

  /// No description provided for @breathingComplete.
  ///
  /// In en, this message translates to:
  /// **'Well done. Take a moment to notice how you feel.'**
  String get breathingComplete;

  /// No description provided for @breathingRounds.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String breathingRounds(int count);

  /// No description provided for @musicTitle.
  ///
  /// In en, this message translates to:
  /// **'Calm Music'**
  String get musicTitle;

  /// No description provided for @musicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Curated playlists for your wellbeing'**
  String get musicSubtitle;

  /// No description provided for @musicCategorySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get musicCategorySleep;

  /// No description provided for @musicCategoryAnxiety.
  ///
  /// In en, this message translates to:
  /// **'Anxiety Relief'**
  String get musicCategoryAnxiety;

  /// No description provided for @musicCategoryFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get musicCategoryFocus;

  /// No description provided for @musicCategoryMeditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get musicCategoryMeditation;

  /// No description provided for @musicOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open in YouTube'**
  String get musicOpenLink;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles...'**
  String get librarySearchHint;

  /// No description provided for @librarySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get librarySave;

  /// No description provided for @librarySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get librarySaved;

  /// No description provided for @libraryShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get libraryShare;

  /// No description provided for @libraryRelatedTopics.
  ///
  /// In en, this message translates to:
  /// **'Related Topics'**
  String get libraryRelatedTopics;

  /// No description provided for @libraryCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get libraryCategories;

  /// No description provided for @libraryCategoryMentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get libraryCategoryMentalHealth;

  /// No description provided for @libraryCategoryRelationships.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get libraryCategoryRelationships;

  /// No description provided for @libraryCategorySelfCare.
  ///
  /// In en, this message translates to:
  /// **'Self Care'**
  String get libraryCategorySelfCare;

  /// No description provided for @libraryCategoryNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get libraryCategoryNutrition;

  /// No description provided for @libraryCategoryFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get libraryCategoryFitness;

  /// No description provided for @sleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep Tracker'**
  String get sleepTitle;

  /// No description provided for @sleepQualityPrompt.
  ///
  /// In en, this message translates to:
  /// **'How did you sleep last night?'**
  String get sleepQualityPrompt;

  /// No description provided for @sleepQuality1.
  ///
  /// In en, this message translates to:
  /// **'Very Poor'**
  String get sleepQuality1;

  /// No description provided for @sleepQuality2.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get sleepQuality2;

  /// No description provided for @sleepQuality3.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get sleepQuality3;

  /// No description provided for @sleepQuality4.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get sleepQuality4;

  /// No description provided for @sleepQuality5.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get sleepQuality5;

  /// No description provided for @sleepHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Hours slept (e.g. 7.5)'**
  String get sleepHoursHint;

  /// No description provided for @sleepNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Any notes about your sleep?'**
  String get sleepNoteHint;

  /// No description provided for @sleepSaved.
  ///
  /// In en, this message translates to:
  /// **'Sleep log saved ✓'**
  String get sleepSaved;

  /// No description provided for @sleepAverage.
  ///
  /// In en, this message translates to:
  /// **'7-day average: {hours} hrs'**
  String sleepAverage(String hours);

  /// No description provided for @crisisTitle.
  ///
  /// In en, this message translates to:
  /// **'Need Support?'**
  String get crisisTitle;

  /// No description provided for @crisisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are not alone. Trained counsellors are available right now.'**
  String get crisisSubtitle;

  /// No description provided for @crisisCallButton.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get crisisCallButton;

  /// No description provided for @crisisNIMHName.
  ///
  /// In en, this message translates to:
  /// **'NIMH Sri Lanka'**
  String get crisisNIMHName;

  /// No description provided for @crisisNIMHNumber.
  ///
  /// In en, this message translates to:
  /// **'1926'**
  String get crisisNIMHNumber;

  /// No description provided for @crisisNIMHDescription.
  ///
  /// In en, this message translates to:
  /// **'National Institute of Mental Health — free, 24/7'**
  String get crisisNIMHDescription;

  /// No description provided for @crisisSahanayaName.
  ///
  /// In en, this message translates to:
  /// **'Sahanaya'**
  String get crisisSahanayaName;

  /// No description provided for @crisisSahanayaNumber.
  ///
  /// In en, this message translates to:
  /// **'011-2696666'**
  String get crisisSahanayaNumber;

  /// No description provided for @crisisSahanayaDescription.
  ///
  /// In en, this message translates to:
  /// **'Counselling and emotional support'**
  String get crisisSahanayaDescription;

  /// No description provided for @crisisBannerMild.
  ///
  /// In en, this message translates to:
  /// **'Feeling overwhelmed? You\'re not alone.'**
  String get crisisBannerMild;

  /// No description provided for @crisisBannerHigh.
  ///
  /// In en, this message translates to:
  /// **'It looks like you may need some support. Please reach out.'**
  String get crisisBannerHigh;

  /// No description provided for @crisisBannerLink.
  ///
  /// In en, this message translates to:
  /// **'See support resources →'**
  String get crisisBannerLink;

  /// No description provided for @crisisEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Reaching out is a sign of strength, not weakness.'**
  String get crisisEncouragement;

  /// No description provided for @crisisPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'These calls are confidential. Your safety and privacy matter.'**
  String get crisisPrivacyNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
