// ignore_for_file: deprecated_member_use

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

  Color get _cardColor =>
      _isDark ? FemoraColors.darkSurface : Colors.white;

  Color get _textPrimary => _isDark
      ? FemoraColors.darkTextPrimary
      : FemoraColors.textPrimary;

  Color get _textSecondary => _isDark
      ? FemoraColors.darkTextSecondary
      : FemoraColors.textSecondary;

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
      backgroundColor: const Color(0xFFF6F0FF),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Row(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Femi',
                style: FemoraTextStyles.headlineLarge.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                )),
            Text('Your wellness companion',
                style: FemoraTextStyles.caption.copyWith(
                  color: const Color(0xFF9CA3AF),
                )),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('Online',
                style: FemoraTextStyles.caption.copyWith(
                  color: const Color(0xFF22C55E),
                  fontWeight: FontWeight.w700,
                )),
          ]),
        ),
        if (_messages.isNotEmpty) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                size: 20, color: Color(0xFF9CA3AF)),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ]),
    );
  }

  // ── Lumi animated section ─────────────────────────────────

  Widget _buildLumiSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_bounceAnim, _lumiOpacity]),
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, _bounceAnim.value),
              child: Opacity(
                opacity: _lumiOpacity.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft glow circle behind Lumi
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFA66CFF).withOpacity(0.18),
                            const Color(0xFFA66CFF).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    Image.asset(
                      _lumiAsset,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                          '💜',
                          style: TextStyle(fontSize: 50)),
                    ),
                  ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFA66CFF).withOpacity(0.12),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/lumi/lumi_happy.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                      child: Text('💜',
                          style: TextStyle(fontSize: 14))),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? FemoraColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? FemoraColors.primary.withOpacity(0.25)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: isUser
                      ? Colors.white
                      : const Color(0xFF1F1F1F),
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
                errorBuilder: (_, _, _) => const Center(
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: const Color(0xFFF6F0FF),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA66CFF).withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFA66CFF).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded,
                color: FemoraColors.primary, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              style: FemoraTextStyles.bodyMedium
                  .copyWith(color: const Color(0xFF1F1F1F)),
              decoration: InputDecoration(
                hintText: 'Talk to Femi...',
                hintStyle: FemoraTextStyles.bodyMedium
                    .copyWith(color: const Color(0xFF9CA3AF)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_textCtrl.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FemoraColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: FemoraColors.primary.withOpacity(0.35),
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
                      color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
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
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, _) => Transform.translate(
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
