// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Breathing Exercise Screen
/// ──────────────────────────
/// 4-7-8 breathing technique.
/// Inhale 4s → Hold 7s → Exhale 8s
/// Pure Flutter — no packages needed.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {

  // ── Breathing phases ────────────────────────────────────────────────────
  static const _phases = [
    _Phase(label: 'inhale',  seconds: 4),
    _Phase(label: 'hold',    seconds: 7),
    _Phase(label: 'exhale',  seconds: 8),
  ];

  int _phaseIndex = 0;
  int _secondsLeft = 0;
  int _rounds = 0;
  bool _isRunning = false;
  bool _isComplete = false;
  static const _totalRounds = 4;

  Timer? _timer;

  // ── Main breathing animation ─────────────────────────────────────────────
  // Single controller that drives the circle size.
  // Never reset abruptly — always forward() or reverse() smoothly.
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  // ── Hold pulse animation ─────────────────────────────────────────────────
  // Subtle gentle pulse during hold phase only.
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Entry fade ───────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Breathing circle — drives size from small (0.45) to large (0.82)
    _breathCtrl = AnimationController(vsync: this);
    _breathAnim = Tween<double>(begin: 0.45, end: 0.82).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );

    // Hold pulse — very subtle scale 1.0 → 1.025 → 1.0, repeating
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Entry fade
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathCtrl.dispose();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  void _start() {
    setState(() {
      _isRunning = true;
      _isComplete = false;
      _rounds = 0;
      _phaseIndex = 0;
    });
    _beginPhase(0);
  }

  void _stop() {
    _timer?.cancel();
    _breathCtrl.stop();
    _pulseCtrl.stop();
    setState(() {
      _isRunning = false;
      _phaseIndex = 0;
      _secondsLeft = 0;
      _rounds = 0;
    });
    // Animate circle back to resting size smoothly
    _breathCtrl.animateTo(0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut);
  }

  void _beginPhase(int index) {
    final phase = _phases[index];
    setState(() {
      _phaseIndex = index;
      _secondsLeft = phase.seconds;
    });

    _pulseCtrl.stop();
    _pulseCtrl.reset();

    if (phase.label == 'inhale') {
      // Grow circle over exactly 4 seconds
      _breathCtrl.animateTo(
        1.0,
        duration: Duration(seconds: phase.seconds),
        curve: Curves.easeInOut,
      );
    } else if (phase.label == 'hold') {
      // Keep circle at full size, add gentle pulse
      _breathCtrl.animateTo(1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut);
      // Start subtle repeating pulse
      _pulseCtrl.repeat(reverse: true);
    } else {
      // Shrink circle over exactly 8 seconds
      _breathCtrl.animateTo(
        0.0,
        duration: Duration(seconds: phase.seconds),
        curve: Curves.easeInOut,
      );
    }

    // Countdown timer — ticks every second
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    final nextIndex = (_phaseIndex + 1) % _phases.length;
    if (nextIndex == 0) {
      final newRounds = _rounds + 1;
      if (newRounds >= _totalRounds) {
        _pulseCtrl.stop();
        _breathCtrl.animateTo(0,
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut);
        setState(() {
          _isRunning = false;
          _isComplete = true;
          _rounds = newRounds;
        });
        return;
      }
      setState(() => _rounds = newRounds);
    }
    _beginPhase(nextIndex);
  }

  // ── Phase helpers ──────────────────────────────────────────────────────────

  String _phaseLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_phases[_phaseIndex].label) {
      case 'inhale': return l10n.breathingInhale;
      case 'hold':   return l10n.breathingHold;
      case 'exhale': return l10n.breathingExhale;
      default:       return '';
    }
  }

  String _phaseInstruction(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_phases[_phaseIndex].label) {
      case 'inhale': return l10n.breathingInhaleSeconds;
      case 'hold':   return l10n.breathingHoldSeconds;
      case 'exhale': return l10n.breathingExhaleSeconds;
      default:       return '';
    }
  }

  Color get _phaseColor {
    switch (_phases[_phaseIndex].label) {
      case 'inhale': return const Color(0xFF34D399);
      case 'hold':   return FemoraColors.primary;
      case 'exhale': return const Color(0xFF60A5FA);
      default:       return FemoraColors.primary;
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(l10n),
              const Spacer(),
              if (_isComplete)
                _buildComplete(l10n)
              else ...[
                if (_isRunning)
                  Text(
                    '${l10n.breathingRounds(_rounds + 1)} of $_totalRounds',
                    style: FemoraTextStyles.caption.copyWith(
                      color: FemoraColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 24),
                _buildCircle(l10n),
                const SizedBox(height: 32),
                if (_isRunning) ...[
                  Text(
                    _phaseInstruction(context),
                    style: FemoraTextStyles.bodyMedium.copyWith(
                      color: FemoraColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'A simple technique to calm your nervous system.\n4 rounds take about 1 minute.',
                      textAlign: TextAlign.center,
                      style: FemoraTextStyles.bodyMedium.copyWith(
                        color: FemoraColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                _buildButton(l10n),
              ],
              const Spacer(),
              if (_isRunning && !_isComplete)
                _buildPhaseIndicators(l10n),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: FemoraColors.lavenderWhisper, width: 1),
        ),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () { _stop(); Navigator.pop(context); },
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: FemoraColors.lightBackgroundTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: FemoraColors.textPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.breathingTitle,
              style: FemoraTextStyles.titleLarge.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w800)),
          Text(l10n.breathingSubtitle,
              style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.textSecondary)),
        ]),
      ]),
    );
  }

  // ── Animated circle ────────────────────────────────────────────────────────

  Widget _buildCircle(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathAnim, _pulseAnim]),
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final baseSize = screenWidth * _breathAnim.value;
        final size = _isRunning && _phases[_phaseIndex].label == 'hold'
            ? baseSize * _pulseAnim.value
            : baseSize;
        final restSize = screenWidth * 0.55;
        final displaySize = _isRunning ? size : restSize;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow — only when running
            if (_isRunning)
              Container(
                width: displaySize + 20,
                height: displaySize + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _phaseColor.withOpacity(0.07),
                ),
              ),
            // Main circle
            Container(
              width: displaySize,
              height: displaySize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRunning
                    ? _phaseColor.withOpacity(0.11)
                    : FemoraColors.lavenderWhisper,
                border: Border.all(
                  color: _isRunning
                      ? _phaseColor.withOpacity(0.35)
                      : FemoraColors.softLilac,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRunning) ...[
                    Text(
                      '$_secondsLeft',
                      style: TextStyle(
                        fontSize: displaySize * 0.22,
                        fontWeight: FontWeight.w900,
                        color: _phaseColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _phaseLabel(context),
                      style: FemoraTextStyles.bodyLarge.copyWith(
                        color: _phaseColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.air_rounded,
                      color: FemoraColors.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.breathingStart,
                      style: FemoraTextStyles.bodyLarge.copyWith(
                        color: FemoraColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Start / Stop button ────────────────────────────────────────────────────

  Widget _buildButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: _isRunning ? _stop : _start,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _isRunning
                ? FemoraColors.error.withOpacity(0.08)
                : FemoraColors.primary,
            borderRadius: BorderRadius.circular(16),
            border: _isRunning
                ? Border.all(
                    color: FemoraColors.error.withOpacity(0.3),
                    width: 1.5)
                : null,
            boxShadow: _isRunning
                ? []
                : [
                    BoxShadow(
                      color: FemoraColors.primary.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              _isRunning ? l10n.breathingStop : l10n.breathingStart,
              style: FemoraTextStyles.bodyLarge.copyWith(
                color: _isRunning ? FemoraColors.error : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Phase indicators ───────────────────────────────────────────────────────

  Widget _buildPhaseIndicators(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _phases.asMap().entries.map((e) {
        final isActive = e.key == _phaseIndex;
        final labels = [
          l10n.breathingInhale,
          l10n.breathingHold,
          l10n.breathingExhale,
        ];
        final colors = [
          const Color(0xFF34D399),
          FemoraColors.primary,
          const Color(0xFF60A5FA),
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 10 : 6,
              height: isActive ? 10 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? colors[e.key] : FemoraColors.neutralLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[e.key],
              style: FemoraTextStyles.caption.copyWith(
                color: isActive ? colors[e.key] : FemoraColors.textSecondary,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  // ── Complete state ─────────────────────────────────────────────────────────

  Widget _buildComplete(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        const Text('🌸', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 20),
        Text(
          l10n.breathingComplete,
          textAlign: TextAlign.center,
          style: FemoraTextStyles.headlineMedium.copyWith(
            color: FemoraColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$_totalRounds rounds completed',
          style: FemoraTextStyles.bodyMedium
              .copyWith(color: FemoraColors.textSecondary),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _start,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: FemoraColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: FemoraColors.primary.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text('Go Again',
                  style: FemoraTextStyles.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: FemoraColors.neutralLight, width: 1.5),
            ),
            child: Center(
              child: Text('Back to Dashboard',
                  style: FemoraTextStyles.bodyLarge.copyWith(
                      color: FemoraColors.textPrimary,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Phase model ───────────────────────────────────────────────────────────────

class _Phase {
  final String label;
  final int seconds;

  const _Phase({required this.label, required this.seconds});
}
