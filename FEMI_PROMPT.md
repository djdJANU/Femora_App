═══════════════════════════════════════════════════════════
FEMORA — FEMI AI COMPANION — COMPLETE IMPLEMENTATION
═══════════════════════════════════════════════════════════
This is the most important feature of the Femora app.
Read every instruction carefully. Do not skip any step.
Build in order. Show flutter analyze after each file.
PROJECT CONTEXT
───────────────
Flutter app, Supabase backend, Provider state management.
FemoraColors.primary = #A66CFF
FemoraColors.darkBackground = #0F0F14
FemoraColors.darkSurface = #1A1A24
FemoraColors.darkSurfaceRaised = #222232
FemoraColors.darkBorder = #2D2D3A
FemoraColors.darkTextPrimary = #F0F0F5
FemoraColors.darkTextSecondary = #9CA3AF
FemoraColors.darkLavender = #2A2040
FemoraColors.lavenderWhisper = #E9D8FD
FemoraColors.lightBackgroundTint = #F6F0FF
FemoraColors.success = #22C55E
FemoraColors.error = #EF4444
All imports use relative paths.
Supabase accessed via SupabaseConfig.client
ThemeProvider accessed via context.watch<ThemeProvider>()
LocaleProvider accessed via context.watch<LocaleProvider>()
DATABASE TABLE (already created in Supabase):
femi_conversations (id, user_id, role, content, created_at)
LUMI IMAGES (already in assets):
assets/images/lumi/lumi_happy.png
assets/images/lumi/lumi_thinking.png
assets/images/lumi/lumi_caring.png
assets/images/lumi/lumi_surprised.png
.env FILE (already exists at mobile/.env):
Contains GEMINI_API_KEY=<user's key>
Do NOT ask for or print the API key anywhere.
Access it only via dotenv.env['GEMINI_API_KEY']
═══════════════════════════════════════════════════════════
STEP 1 — ADD PACKAGES TO pubspec.yaml
═══════════════════════════════════════════════════════════
Read mobile/pubspec.yaml first.
Add under dependencies:
google_generative_ai: ^0.4.6
flutter_dotenv: ^5.2.1
Add under flutter > assets:

assets/images/lumi/
.env

Run: flutter pub get
Show the output.
═══════════════════════════════════════════════════════════
STEP 2 — UPDATE lib/main.dart
═══════════════════════════════════════════════════════════
Read lib/main.dart first.
Add this import at the very top with other imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
In the main() function, add this line BEFORE runApp():
await dotenv.load(fileName: '.env');
Show the updated main() function after the change.
═══════════════════════════════════════════════════════════
STEP 3 — CREATE lib/services/femi_service.dart
═══════════════════════════════════════════════════════════
Create this file with exact content:
dart// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// FemiService
/// ───────────
/// Handles all Gemini API calls and conversation
/// persistence for the Femi AI companion.
class FemiService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Gemini Model ──────────────────────────────────────────

  GenerativeModel _buildModel() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    return GenerativeModel(
      model: 'gemini-2.5-flash-preview-04-17',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.85,
        maxOutputTokens: 1024,
        topP: 0.95,
      ),
      safetySettings: [
        SafetySetting(
          HarmCategory.harassment,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.hateSpeech,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.medium,
        ),
      ],
    );
  }

  // ── System Prompt ─────────────────────────────────────────

  static const _systemPrompt = '''
You are Femi, the AI wellness companion of Femora — a 
women's health and safety app designed for women in 
Sri Lanka. You are represented by Lumi, a cute friendly 
purple lizard mascot.

YOUR PERSONALITY:
- Warm, caring, and friendly like a trusted older sister
- Occasionally playful and funny — a little joke or emoji 
  can brighten someone's day
- Honest and accurate — never give false hope or sugarcoat 
  serious health information
- Empowering — you help users understand their bodies and 
  make informed decisions
- Never condescending, never cold or clinical

YOUR KNOWLEDGE:
- Women's menstrual health and cycle phases
- Pregnancy week by week development
- Mental health, anxiety, depression, emotional wellbeing
- Nutrition and exercise for women
- Relationships and personal boundaries
- Personal safety and emergency resources
- Sri Lankan cultural context and local healthcare resources

YOUR LIMITS (CRITICAL — ALWAYS FOLLOW THESE):
- You NEVER diagnose medical conditions
- You ALWAYS recommend seeing a real doctor for serious 
  physical symptoms
- You NEVER replace professional mental health care
- When you detect crisis language (self-harm, suicide, 
  extreme distress, danger), you respond with warmth and 
  compassion FIRST, then gently provide these resources:
  * NIMH Helpline: 1926 (free, 24/7)
  * Sahanaya: 011-2696666
  * Women In Need: 011-4718585

LANGUAGE BEHAVIOUR:
- Detect the language the user writes in automatically
- Respond in the SAME language — Sinhala, Tamil, or English
- If the user writes in Sinhala script, respond in Sinhala
- If the user writes in Tamil script, respond in Tamil
- Default to English if unsure

RESPONSE STYLE:
- Keep responses conversational — not essay-length
- Use the user's name naturally when you know it
- Use emojis occasionally but naturally — not every sentence
- When discussing health topics, be accurate but accessible
- If you detect the user is stressed or sad, acknowledge 
  their feelings sincerely before giving any information
- A small relatable joke or light moment is welcome when 
  the situation allows — humour can heal

USER HEALTH CONTEXT:
You will receive a context block at the start of each 
conversation with the user's current health data from 
the Femora app. Use this to give personalised responses.
Never make the user feel monitored — weave context in naturally.
Do not list the context back to the user verbatim.
''';

  // ── Context Builder ───────────────────────────────────────

  String buildUserContext({
    required String userName,
    String? language,
    String? cyclePhase,
    int? cycleDay,
    int? averageCycleLength,
    DateTime? nextPeriodDate,
    bool isPregnant = false,
    int? pregnancyWeek,
    int? latestPhq2Score,
    String? latestMood,
    DateTime? dateOfBirth,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== USER HEALTH CONTEXT ===');
    buffer.writeln('Name: $userName');
    if (language != null) {
      final langName = language == 'si'
          ? 'Sinhala'
          : language == 'ta'
              ? 'Tamil'
              : 'English';
      buffer.writeln('Preferred language: $langName');
    }
    if (dateOfBirth != null) {
      final age = DateTime.now().year - dateOfBirth.year;
      buffer.writeln('Age: approximately $age years old');
    }
    buffer.writeln('');

    if (isPregnant && pregnancyWeek != null) {
      buffer.writeln('STATUS: Currently pregnant');
      buffer.writeln('Pregnancy week: $pregnancyWeek of 40');
      buffer.writeln('');
    } else if (cyclePhase != null) {
      buffer.writeln('MENSTRUAL CYCLE:');
      buffer.writeln('Current phase: $cyclePhase');
      if (cycleDay != null) {
        buffer.writeln('Day of cycle: Day $cycleDay');
      }
      if (averageCycleLength != null) {
        buffer.writeln(
            'Average cycle length: $averageCycleLength days');
      }
      if (nextPeriodDate != null) {
        final daysUntil =
            nextPeriodDate.difference(DateTime.now()).inDays;
        if (daysUntil >= 0) {
          buffer.writeln(
              'Next period expected: in approximately $daysUntil days');
        }
      }
      buffer.writeln('');
    }

    if (latestPhq2Score != null) {
      buffer.writeln('MENTAL WELLBEING:');
      buffer.writeln(
          'Recent PHQ-2 depression screening score: $latestPhq2Score out of 6');
      if (latestPhq2Score >= 3) {
        buffer.writeln(
            'Clinical note: Score suggests possible low mood. '
            'Be especially gentle and supportive.');
      }
      buffer.writeln('');
    }

    if (latestMood != null) {
      buffer.writeln('Most recent mood logged: $latestMood');
      buffer.writeln('');
    }

    buffer.writeln('=== END CONTEXT ===');
    buffer.writeln('');
    buffer.writeln(
        'Use this context to personalise your responses naturally. '
        'Do not repeat this information back to the user directly.');

    return buffer.toString();
  }

  // ── Send Message ──────────────────────────────────────────

  Future<String> sendMessage({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
    required String userContext,
  }) async {
    try {
      final model = _buildModel();

      // Build chat history
      final history = <Content>[];

      // Inject context as opening exchange
      history.add(Content.user([TextPart(userContext)]));
      history.add(Content.model([
        TextPart(
          'I understand your health context. '
          "I'm here and ready to support you! 💜",
        ),
      ]));

      // Add conversation history (up to last 20 messages)
      final recentHistory = conversationHistory.length > 20
          ? conversationHistory.sublist(
              conversationHistory.length - 20)
          : conversationHistory;

      for (final msg in recentHistory) {
        if (msg['role'] == 'user') {
          history.add(
              Content.user([TextPart(msg['content']!)]));
        } else if (msg['role'] == 'assistant') {
          history.add(
              Content.model([TextPart(msg['content']!)]));
        }
      }

      // Start chat and send message
      final chat = model.startChat(history: history);
      final response = await chat.sendMessage(
          Content.user([TextPart(userMessage)]));

      return response.text ?? "I'm here for you! 💜";
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini API error: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('quota') ||
          errorStr.contains('429') ||
          errorStr.contains('rate')) {
        return "I'm a little overwhelmed right now "
            "Give me just a moment and try again! "
            "I'm not going anywhere. 💜";
      }
      if (errorStr.contains('safety')) {
        return "I want to make sure I give you the most "
            "helpful response. Could you rephrase that? 💜";
      }
      return "Oops, something went a bit sideways on my end! "
          "Try sending your message again? 💜";
    } catch (e) {
      debugPrint('FemiService.sendMessage error: $e');
      return "Something unexpected happened! "
          "Please try again in a moment. 💜";
    }
  }

  // ── Conversation Persistence ──────────────────────────────

  Future<List<Map<String, String>>> loadHistory() async {
    try {
      final userId = _userId;
      if (userId == null) return [];

      final response = await _supabase
          .from('femi_conversations')
          .select('role, content')
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(40);

      return List<Map<String, String>>.from(
        (response as List).map((row) => {
              'role': row['role'] as String,
              'content': row['content'] as String,
            }),
      );
    } catch (e) {
      debugPrint('FemiService.loadHistory error: $e');
      return [];
    }
  }

  Future<void> saveMessage({
    required String role,
    required String content,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) return;
      await _supabase.from('femi_conversations').insert({
        'user_id': userId,
        'role': role,
        'content': content,
      });
    } catch (e) {
      debugPrint('FemiService.saveMessage error: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final userId = _userId;
      if (userId == null) return;
      await _supabase
          .from('femi_conversations')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('FemiService.clearHistory error: $e');
    }
  }

  // ── Lumi Emotion Detection ────────────────────────────────

  LumiEmotion detectEmotion(String response) {
    final lower = response.toLowerCase();

    // Crisis response
    if (lower.contains('1926') ||
        lower.contains('sahanaya') ||
        lower.contains('not alone') ||
        lower.contains('reach out') ||
        lower.contains('helpline') ||
        lower.contains('crisis')) {
      return LumiEmotion.caring;
    }

    // Urgent or important medical info
    if (lower.contains('see a doctor') ||
        lower.contains('medical attention') ||
        lower.contains('immediately') ||
        lower.contains('urgent') ||
        lower.contains('important to note')) {
      return LumiEmotion.surprised;
    }

    // Empathy and emotional support
    if (lower.contains('understand') ||
        lower.contains('sounds difficult') ||
        lower.contains('that must be') ||
        lower.contains('sorry to hear') ||
        lower.contains('feel') ||
        lower.contains('💜') ||
        lower.contains('❤️') ||
        lower.contains('here for you')) {
      return LumiEmotion.caring;
    }

    return LumiEmotion.happy;
  }
}

enum LumiEmotion { happy, thinking, caring, surprised }
Run flutter analyze on this file and fix any issues before
moving to the next step.
═══════════════════════════════════════════════════════════
STEP 4 — CREATE lib/screens/femi/femi_screen.dart
═══════════════════════════════════════════════════════════
Create the directory lib/screens/femi/ if it does not exist.
Then create lib/screens/femi/femi_screen.dart with this content:
dart// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../providers/theme_provider.dart';
import '../../services/femi_service.dart';

class FemiScreen extends StatefulWidget {
  const FemiScreen({super.key});

  @override
  State<FemiScreen> createState() => _FemiScreenState();
}

class _FemiScreenState extends State<FemiScreen>
    with TickerProviderStateMixin {
  final _service = FemiService();
  final _supabase = SupabaseConfig.client;
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<_ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  LumiEmotion _lumiEmotion = LumiEmotion.happy;
  String _userName = 'Friend';
  String _userContext = '';

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _lumiSwitchCtrl;
  late Animation<double> _lumiOpacity;

  static const _quickPrompts = [
    '💜 How am I feeling today?',
    '🌺 Tell me about my cycle phase',
    '😴 I\'m feeling tired, is that normal?',
    '🧠 I need someone to talk to',
    '💪 Give me a wellness tip for today',
    '❓ What can you help me with?',
  ];

  @override
  void initState() {
    super.initState();

    // Lumi gentle bob animation
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
          parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    // Lumi emotion switch animation
    _lumiSwitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _lumiOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _lumiSwitchCtrl, curve: Curves.easeIn),
    );

    _loadData();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _lumiSwitchCtrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Load user data and conversation history ───────────────

  Future<void> _loadData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Profile
      final profile = await _supabase
          .from('profiles')
          .select('full_name, date_of_birth, language')
          .eq('id', userId)
          .maybeSingle();

      _userName = (profile?['full_name'] as String?)?.isNotEmpty == true
          ? profile!['full_name'] as String
          : 'Friend';
      final language = profile?['language'] as String? ?? 'en';
      DateTime? dob;
      if (profile?['date_of_birth'] != null) {
        dob = DateTime.tryParse(
            profile!['date_of_birth'] as String);
      }

      // Period cycle
      String? cyclePhase;
      int? cycleDay;
      int? avgCycleLen;
      DateTime? nextPeriod;
      try {
        final cycles = await _supabase
            .from('period_cycles')
            .select('start_date, cycle_length')
            .eq('user_id', userId)
            .order('start_date', ascending: false)
            .limit(3);
        if ((cycles as List).isNotEmpty) {
          final latest = cycles[0];
          final startDate = DateTime.tryParse(
              latest['start_date'] as String? ?? '');
          if (startDate != null) {
            cycleDay =
                DateTime.now().difference(startDate).inDays + 1;
            final lengths = cycles
                .where((c) => c['cycle_length'] != null)
                .map((c) => (c['cycle_length'] as num).toInt())
                .toList();
            if (lengths.isNotEmpty) {
              avgCycleLen =
                  (lengths.reduce((a, b) => a + b) / lengths.length)
                      .round();
              nextPeriod =
                  startDate.add(Duration(days: avgCycleLen));
            }
            if (cycleDay <= 5) {
              cyclePhase = 'Menstrual phase';
            } else if (cycleDay <= 13) {
              cyclePhase = 'Follicular phase';
            } else if (cycleDay <= 16) {
              cyclePhase = 'Ovulation phase';
            } else {
              cyclePhase = 'Luteal phase';
            }
          }
        }
      } catch (_) {}

      // Pregnancy
      bool isPregnant = false;
      int? pregnancyWeek;
      try {
        final pregnancy = await _supabase
            .from('pregnancy_records')
            .select('lmp_date')
            .eq('user_id', userId)
            .eq('is_active', true)
            .maybeSingle();
        if (pregnancy != null) {
          isPregnant = true;
          final lmp = DateTime.tryParse(
              pregnancy['lmp_date'] as String? ?? '');
          if (lmp != null) {
            pregnancyWeek =
                (DateTime.now().difference(lmp).inDays / 7)
                    .floor();
          }
        }
      } catch (_) {}

      // PHQ-2
      int? phq2Score;
      try {
        final phq2 = await _supabase
            .from('mental_phq2_results')
            .select('total_score')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        phq2Score = phq2?['total_score'] as int?;
      } catch (_) {}

      // Mood
      String? latestMood;
      try {
        final mood = await _supabase
            .from('mental_mood_logs')
            .select('mood')
            .eq('user_id', userId)
            .order('logged_at', ascending: false)
            .limit(1)
            .maybeSingle();
        latestMood = mood?['mood'] as String?;
      } catch (_) {}

      // Build context string
      _userContext = _service.buildUserContext(
        userName: _userName,
        language: language,
        cyclePhase: cyclePhase,
        cycleDay: cycleDay,
        averageCycleLength: avgCycleLen,
        nextPeriodDate: nextPeriod,
        isPregnant: isPregnant,
        pregnancyWeek: pregnancyWeek,
        latestPhq2Score: phq2Score,
        latestMood: latestMood,
        dateOfBirth: dob,
      );

      // Load conversation history
      final history = await _service.loadHistory();
      final msgs = history
          .map((h) => _ChatMessage(
                role: h['role'] == 'user'
                    ? MessageRole.user
                    : MessageRole.assistant,
                content: h['content']!,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('FemiScreen._loadData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Send message ──────────────────────────────────────────

  Future<void> _send(String text) async {
    final message = text.trim();
    if (message.isEmpty || _isTyping) return;
    _textCtrl.clear();

    final userMsg = _ChatMessage(
      role: MessageRole.user,
      content: message,
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      _lumiEmotion = LumiEmotion.thinking;
    });

    await _service.saveMessage(role: 'user', content: message);
    _scrollToBottom();

    // Build history for API (exclude the message just added)
    final historyForApi = _messages
        .sublist(0, _messages.length - 1)
        .map((m) => {
              'role':
                  m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    final response = await _service.sendMessage(
      userMessage: message,
      conversationHistory: historyForApi,
      userContext: _userContext,
    );

    // Animate Lumi emotion change
    final newEmotion = _service.detectEmotion(response);
    await _lumiSwitchCtrl.forward();
    if (mounted) setState(() => _lumiEmotion = newEmotion);
    await _lumiSwitchCtrl.reverse();

    await _service.saveMessage(
        role: 'assistant', content: response);

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(
          role: MessageRole.assistant,
          content: response,
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final isDark = context.read<ThemeProvider>().isDark;
    final cardColor =
        isDark ? FemoraColors.darkSurface : Colors.white;
    final textPrimary = isDark
        ? FemoraColors.darkTextPrimary
        : FemoraColors.textPrimary;
    final textSecondary = isDark
        ? FemoraColors.darkTextSecondary
        : FemoraColors.textSecondary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Chat',
            style: FemoraTextStyles.titleLarge.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            )),
        content: Text(
          'This will delete your entire conversation with Femi. '
          'She will start fresh next time.',
          style: FemoraTextStyles.bodyMedium
              .copyWith(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear',
                style: TextStyle(color: FemoraColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _service.clearHistory();
      if (mounted) {
        setState(() {
          _messages.clear();
          _lumiEmotion = LumiEmotion.happy;
        });
      }
    }
  }

  // ── Theme helpers ─────────────────────────────────────────

  bool get _isDark => context.watch<ThemeProvider>().isDark;

  Color get _bgColor => _isDark
      ? FemoraColors.darkBackground
      : FemoraColors.lightBackgroundTint;

  Color get _cardColor =>
      _isDark ? FemoraColors.darkSurface : Colors.white;

  Color get _textPrimary => _isDark
      ? FemoraColors.darkTextPrimary
      : FemoraColors.textPrimary;

  Color get _textSecondary => _isDark
      ? FemoraColors.darkTextSecondary
      : FemoraColors.textSecondary;

  Color get _divider => _isDark
      ? FemoraColors.darkBorder
      : FemoraColors.lavenderWhisper;

  // ── Lumi image ────────────────────────────────────────────

  String get _lumiAsset {
    switch (_lumiEmotion) {
      case LumiEmotion.thinking:
        return 'assets/images/lumi/lumi_thinking.png';
      case LumiEmotion.caring:
        return 'assets/images/lumi/lumi_caring.png';
      case LumiEmotion.surprised:
        return 'assets/images/lumi/lumi_surprised.png';
      case LumiEmotion.happy:
    }
    return 'assets/images/lumi/lumi_happy.png';
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildLumiSection(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: FemoraColors.primary))
                : _messages.isEmpty
                    ? _buildWelcome()
                    : _buildMessageList(),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInput(),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Femi',
                style: FemoraTextStyles.headlineLarge.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w800,
                )),
            Text('Your wellness companion',
                style: FemoraTextStyles.caption
                    .copyWith(color: _textSecondary)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: FemoraColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                color: FemoraColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text('Online',
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.success,
                  fontWeight: FontWeight.w600,
                )),
          ]),
        ),
        if (_messages.isNotEmpty) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: _textSecondary, size: 20),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ]),
    );
  }

  // ── Lumi animated section ─────────────────────────────────

  Widget _buildLumiSection() {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_bounceAnim, _lumiOpacity]),
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, _bounceAnim.value),
              child: Opacity(
                opacity: _lumiOpacity.value,
                child: Image.asset(
                  _lumiAsset,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color:
                          FemoraColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('💜',
                          style: TextStyle(fontSize: 40)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Welcome screen ────────────────────────────────────────

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi $_userName! I\'m Femi 💜',
            style: FemoraTextStyles.titleLarge.copyWith(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "I'm here to support your wellness journey. "
            "Ask me anything — from your cycle to your "
            "mood, I've got you!",
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: _textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Try asking me:',
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrompts.map((prompt) {
              return GestureDetector(
                onTap: () => _send(prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color:
                        FemoraColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          FemoraColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    prompt,
                    style: FemoraTextStyles.caption.copyWith(
                      color: FemoraColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isUser = msg.role == MessageRole.user;
        return _buildBubble(msg, isUser);
      },
    );
  }

  Widget _buildBubble(_ChatMessage msg, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:
                    FemoraColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/lumi/lumi_happy.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                      child: Text('💜',
                          style: TextStyle(fontSize: 14))),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? FemoraColors.primary
                    : _cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      Radius.circular(isUser ? 18 : 4),
                  bottomRight:
                      Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? FemoraColors.primary
                            .withOpacity(0.25)
                        : Colors.black.withOpacity(
                            _isDark ? 0.15 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: isUser
                      ? Colors.white
                      : _textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Typing indicator ──────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: FemoraColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/lumi/lumi_thinking.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                    child: Text('💜',
                        style: TextStyle(fontSize: 14))),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(_isDark ? 0.15 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _TypingDots(color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _isDark
                  ? FemoraColors.darkSurfaceRaised
                  : FemoraColors.lightBackgroundTint,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _divider),
            ),
            child: TextField(
              controller: _textCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              style: FemoraTextStyles.bodyMedium
                  .copyWith(color: _textPrimary),
              decoration: InputDecoration(
                hintText: 'Talk to Femi...',
                hintStyle: FemoraTextStyles.bodyMedium
                    .copyWith(color: _textSecondary),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: InputBorder.none,
              ),
              onSubmitted: _send,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _send(_textCtrl.text),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: FemoraColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      FemoraColors.primary.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isTyping
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
          ),
        ),
      ]),
    );
  }
}

// ── Typing dots ───────────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      ),
    );
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 0, end: -7).animate(
              CurvedAnimation(
                  parent: c, curve: Curves.easeInOut),
            ))
        .toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

enum MessageRole { user, assistant }

class _ChatMessage {
  final MessageRole role;
  final String content;
  _ChatMessage({required this.role, required this.content});
}
Run flutter analyze on this file and fix any issues.
═══════════════════════════════════════════════════════════
STEP 5 — UPDATE DUMMY FEMI SCREEN
═══════════════════════════════════════════════════════════
Read lib/screens/home/home_screen.dart to find how the
Femi/AI tab is currently wired in the bottom navigation.
Find the file that acts as the Femi tab screen.
It is likely one of these:

lib/screens/home/dummy_pages/femi_screen.dart
lib/screens/home/dummy_pages/ai_screen.dart
or similar

Read that file. Replace its entire content with:
dartimport 'package:flutter/material.dart';
import '../../femi/femi_screen.dart';

// Keep the EXACT SAME class name that home_screen.dart imports
// Read home_screen.dart first to find the correct class name
// Then use that same class name below

class FemiDummyScreen extends StatelessWidget {
  const FemiDummyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FemiScreen();
  }
}
IMPORTANT: Read home_screen.dart first to find the exact
class name being imported for the Femi tab, and use that
exact same class name — do not change it.
═══════════════════════════════════════════════════════════
STEP 6 — FINAL CHECKS
═══════════════════════════════════════════════════════════

Run: flutter analyze
Fix every single issue found. Zero issues required.
Verify these files exist:

mobile/.env (with GEMINI_API_KEY)
mobile/assets/images/lumi/lumi_happy.png
mobile/assets/images/lumi/lumi_thinking.png
mobile/assets/images/lumi/lumi_caring.png
mobile/assets/images/lumi/lumi_surprised.png


Run: flutter run
Show the full output.
After app launches, navigate to the Femi tab.
It should show:

Lumi image bouncing gently at the top
"Hi [name]! I'm Femi 💜" welcome message
Six quick prompt chips
Input bar at the bottom



═══════════════════════════════════════════════════════════
CRITICAL RULES — DO NOT VIOLATE
═══════════════════════════════════════════════════════════

NEVER print or log the API key
NEVER crash if Lumi images are missing — use 💜 fallback
NEVER show raw error messages to the user
ALWAYS wrap Gemini API calls in try-catch
If flutter analyze shows ANY issues, fix them ALL before
running flutter run
The .env file must be listed in pubspec.yaml assets
dotenv.load() must be called before runApp() in main.dart

═══════════════════════════════════════════════════════════
END OF PROMPT
═══════════════════════════════════════════════════════════