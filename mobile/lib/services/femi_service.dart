// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
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
      model: 'gemini-2.5-flash-lite',
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
      history.add(Content.multi([TextPart(userContext)]));
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
              Content.multi([TextPart(msg['content']!)]));
        } else if (msg['role'] == 'assistant') {
          history.add(
              Content.model([TextPart(msg['content']!)]));
        }
      }

      // Start chat and send message
      final chat = model.startChat(history: history);
      final response = await chat.sendMessage(
          Content.multi([TextPart(userMessage)]));

      return response.text ?? "I'm here for you! 💜";
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini API error: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('quota') ||
          errorStr.contains('429') ||
          errorStr.contains('rate')) {
        debugPrint(
            'Gemini rate limited — switching to OpenRouter fallback');
        return await _sendViaOpenRouter(
          userMessage: userMessage,
          conversationHistory: conversationHistory,
          userContext: userContext,
        );
      }
      if (errorStr.contains('safety')) {
        return "I want to give you the most helpful response. "
            "Could you rephrase that? 💜";
      }
      return await _sendViaOpenRouter(
        userMessage: userMessage,
        conversationHistory: conversationHistory,
        userContext: userContext,
      );
    } catch (e) {
      debugPrint('FemiService.sendMessage error: $e');
      return "Something unexpected happened! "
          "Please try again in a moment. 💜";
    }
  }

  // ── OpenRouter Fallback ───────────────────────────────────

  Future<String> _sendViaOpenRouter({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
    required String userContext,
  }) async {
    try {
      final messages = <Map<String, String>>[];
      messages.add({'role': 'system', 'content': _systemPrompt});
      messages.add({'role': 'user', 'content': userContext});
      messages.add({
        'role': 'assistant',
        'content':
            "I understand your health context. I'm here for you! 💜",
      });
      for (final msg in conversationHistory.take(20)) {
        messages.add(msg);
      }
      messages.add({'role': 'user', 'content': userMessage});

      final response = await http
          .post(
            Uri.parse(
                'https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization':
                  'Bearer ${dotenv.env['OPENROUTER_API_KEY'] ?? ''}',
              'HTTP-Referer': 'https://femora.app',
              'X-Title': 'Femora',
            },
            body: jsonEncode({
              'model': 'mistralai/mistral-7b-instruct:free',
              'messages': messages,
              'max_tokens': 1024,
              'temperature': 0.85,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String? ??
            "I'm here for you! 💜";
      }
      return "I'm having a little moment — please try again in a second! 💜";
    } catch (e) {
      debugPrint('OpenRouter fallback error: $e');
      return "I'm having a little moment — please try again in a second! 💜";
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
