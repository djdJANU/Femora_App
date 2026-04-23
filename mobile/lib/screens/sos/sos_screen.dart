// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../services/sos_repository.dart';
import 'add_contact_screen.dart';

/// SOS Main Screen
/// ────────────────
/// Emergency alert hub. Features:
///   - One-tap 5-second countdown SOS button
///   - Shake-to-activate (foreground only)
///   - GPS location shared via SMS (url_launcher sms: scheme)
///   - Emergency contacts management (max 3)
///   - Quick-dial Sri Lanka emergency numbers
///
/// Note: SMS opens the native messaging app pre-filled;
/// the user taps Send in the messaging app.
/// Background shake detection is not implemented (foreground only).
class SosMainScreen extends StatefulWidget {
  const SosMainScreen({super.key});

  @override
  State<SosMainScreen> createState() => _SosMainScreenState();
}

class _SosMainScreenState extends State<SosMainScreen>
    with TickerProviderStateMixin {
  final _repo = SosRepository();

  // ── State ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  bool _sosActive = false;
  int _countdown = 5;
  bool _shakeEnabled = true;
  bool _locationPermissionGranted = false;
  bool _locationPermissionPermanentlyDenied = false;
  Position? _currentPosition;

  Timer? _countdownTimer;
  StreamSubscription<UserAccelerometerEvent>? _shakeSubscription;
  String _pendingTriggerMethod = 'manual';

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();

    // Pulse animation for countdown (repeating scale)
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _loadContacts();
    _checkLocationPermission();
    _startShakeDetection();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    _shakeSubscription?.cancel();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadContacts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final contacts = await _repo.getEmergencyContacts();
    if (mounted) setState(() { _contacts = contacts; _isLoading = false; });
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Immediately request the permission
        final result = await Geolocator.requestPermission();
        if (mounted) {
          setState(() {
            _locationPermissionGranted =
                result == LocationPermission.whileInUse ||
                    result == LocationPermission.always;
            _locationPermissionPermanentlyDenied =
                result == LocationPermission.deniedForever;
          });
          if (_locationPermissionGranted) _getCurrentLocation();
        }
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationPermissionGranted = false;
            _locationPermissionPermanentlyDenied = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _locationPermissionGranted = true;
            _locationPermissionPermanentlyDenied = false;
          });
          _getCurrentLocation();
        }
      }
    } catch (e) {
      debugPrint('Location permission check error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint('Location fetch error (non-blocking): $e');
    }
  }

  // ── Shake detection ────────────────────────────────────────────────────────

  void _startShakeDetection() {
    try {
      _shakeSubscription = userAccelerometerEventStream().listen(
        _onAccelerometer,
        onError: (e) {
          debugPrint('Shake detection error: $e');
          if (mounted) setState(() => _shakeEnabled = false);
        },
        cancelOnError: true,
      );
    } catch (e) {
      // Device does not have a user accelerometer sensor
      debugPrint('Shake detection unavailable: $e');
      if (mounted) setState(() => _shakeEnabled = false);
    }
  }

  void _onAccelerometer(UserAccelerometerEvent event) {
    if (!_shakeEnabled || _sosActive) return;
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (magnitude > 20) {
      _startSOS('shake');
    }
  }

  // ── SOS logic ──────────────────────────────────────────────────────────────

  void _startSOS(String triggerMethod) {
    if (_sosActive) return;
    HapticFeedback.heavyImpact();
    _pendingTriggerMethod = triggerMethod;
    setState(() {
      _sosActive = true;
      _countdown = 5;
    });
    _pulseCtrl.repeat(reverse: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      HapticFeedback.vibrate();
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _cancelSOS() {
    _countdownTimer?.cancel();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    final method = _pendingTriggerMethod;
    setState(() { _sosActive = false; _countdown = 5; });

    // Log cancelled trigger (non-blocking)
    _repo.logTrigger(
      triggerMethod: method,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      contactsAlerted: [],
      wasCancelled: true,
    );
  }

  Future<void> _triggerSOS() async {
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    // Try a fresh location fetch with short timeout; use cached if it fails
    Position? position = _currentPosition;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) setState(() => _currentPosition = position);
    } catch (_) {
      // Use cached position or null — location failure must not block SOS
    }

    final locationString = position != null
        ? 'https://maps.google.com/?q=${position.latitude},${position.longitude}'
        : 'Location unavailable';

    final List<String> alerted = [];

    for (final contact in _contacts) {
      final phone = contact['phone_number'] as String? ?? '';
      if (phone.isEmpty) continue;

      final smsBody =
          '🆘 ${contact['name']} — I need help!\n\n'
          'My location: $locationString\n\n'
          'Sent via Femora Safety';

      try {
        final uri = Uri(
          scheme: 'sms',
          path: phone,
          queryParameters: {'body': smsBody},
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          alerted.add(phone);
        }
      } catch (e) {
        // One contact failing must not block others
        debugPrint('SMS launch error for $phone: $e');
      }

      // Small delay so the OS processes each SMS intent
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Log the trigger (non-blocking)
    await _repo.logTrigger(
      triggerMethod: _pendingTriggerMethod,
      latitude: position?.latitude,
      longitude: position?.longitude,
      contactsAlerted: alerted,
      wasCancelled: false,
    );

    if (!mounted) return;
    setState(() { _sosActive = false; _countdown = 5; });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alerted.isNotEmpty
              ? 'Alert sent to ${alerted.length} contact${alerted.length > 1 ? 's' : ''}'
              : 'No contacts to alert. Please add emergency contacts.',
        ),
        backgroundColor: alerted.isNotEmpty
            ? FemoraColors.success
            : FemoraColors.warning,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Emergency number call ──────────────────────────────────────────────────

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open dialler. Please call $number manually.'),
            backgroundColor: FemoraColors.error,
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                _buildHeader(),
                if (_locationPermissionPermanentlyDenied)
                  _buildLocationBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildSosButton(),
                        const Divider(
                          height: 1,
                          color: FemoraColors.lavenderWhisper,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildContactsSection(),
                              const SizedBox(height: 28),
                              _buildEmergencyNumbers(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: FemoraColors.lavenderWhisper, width: 1),
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency SOS',
                style: FemoraTextStyles.titleLarge.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Stay safe · Sri Lanka',
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Shake toggle
        Row(children: [
          Text(
            'Shake',
            style: FemoraTextStyles.caption.copyWith(
              color: FemoraColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _shakeEnabled,
              onChanged: (v) => setState(() => _shakeEnabled = v),
              activeColor: FemoraColors.primary,
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Location permission banner ─────────────────────────────────────────────

  Widget _buildLocationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: FemoraColors.warning.withOpacity(0.1),
      child: Row(children: [
        const Icon(Icons.location_off_rounded,
            color: FemoraColors.warning, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Location access denied. Your SOS will be sent without your location.',
            style: FemoraTextStyles.caption.copyWith(
              color: FemoraColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            await Geolocator.openAppSettings();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FemoraColors.warning,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Settings',
              style: FemoraTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── SOS Button area ────────────────────────────────────────────────────────

  Widget _buildSosButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      color: Colors.white,
      child: Column(
        children: [
          // Decorative outer rings
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FemoraColors.error.withOpacity(0.06),
                ),
              ),
              Container(
                width: 215,
                height: 215,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FemoraColors.error.withOpacity(0.10),
                ),
              ),
              // Main SOS button with pulse
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _sosActive ? _pulseAnim.value : 1.0,
                  child: child,
                ),
                child: GestureDetector(
                  onTap: _sosActive ? null : () => _startSOS('manual'),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FemoraColors.error,
                      boxShadow: [
                        BoxShadow(
                          color: FemoraColors.error.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _sosActive
                          ? Text(
                              '$_countdown',
                              style: const TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 3,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_sosActive) ...[
            Text(
              'Sending in $_countdown seconds...',
              style: FemoraTextStyles.bodyMedium.copyWith(
                color: FemoraColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _cancelSOS,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: FemoraColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: FemoraColors.error.withOpacity(0.3)),
                ),
                child: Text(
                  'CANCEL',
                  style: FemoraTextStyles.bodyLarge.copyWith(
                    color: FemoraColors.error,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              'Tap to send alert',
              style: FemoraTextStyles.bodyMedium.copyWith(
                color: FemoraColors.textSecondary,
              ),
            ),
            if (_shakeEnabled) ...[
              const SizedBox(height: 4),
              Text(
                'or shake your phone',
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Emergency contacts section ─────────────────────────────────────────────

  Widget _buildContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Emergency Contacts',
              style: FemoraTextStyles.titleLarge.copyWith(
                color: FemoraColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_contacts.length < 3)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddContactScreen(),
                    ),
                  ).then((result) {
                    if (result == true) _loadContacts();
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: FemoraColors.lavenderWhisper,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: FemoraColors.primary,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: FemoraColors.primary),
            ),
          )
        else if (_contacts.isEmpty)
          _buildEmptyContacts()
        else
          ...(_contacts.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildContactCard(c),
              ))),
      ],
    );
  }

  Widget _buildEmptyContacts() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddContactScreen()),
        ).then((result) {
          if (result == true) _loadContacts();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FemoraColors.lightBackgroundTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: FemoraColors.neutralLight,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FemoraColors.lavenderWhisper,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: FemoraColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add up to 3 emergency contacts',
              style: FemoraTextStyles.bodyMedium.copyWith(
                color: FemoraColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'They will receive your location when you send an SOS',
              textAlign: TextAlign.center,
              style: FemoraTextStyles.caption.copyWith(
                color: FemoraColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final name = contact['name'] as String? ?? '';
    final phone = contact['phone_number'] as String? ?? '';
    final relationship = contact['relationship'] as String? ?? '';
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FemoraColors.neutralLight),
        boxShadow: [
          BoxShadow(
            color: FemoraColors.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: FemoraColors.lavenderWhisper,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: FemoraTextStyles.bodyLarge.copyWith(
                color: FemoraColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: FemoraTextStyles.bodyLarge.copyWith(
                  color: FemoraColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                phone,
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: FemoraColors.lavenderWhisper,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  relationship,
                  style: FemoraTextStyles.caption.copyWith(
                    color: FemoraColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Edit
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddContactScreen(existingContact: contact),
              ),
            ).then((result) {
              if (result == true) _loadContacts();
            });
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: FemoraColors.lightBackgroundTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: FemoraColors.textSecondary,
              size: 16,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Delete
        GestureDetector(
          onTap: () => _confirmDelete(contact),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: FemoraColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_rounded,
              color: FemoraColors.error,
              size: 16,
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> contact) async {
    final name = contact['name'] as String? ?? 'this contact';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove contact?'),
        content: Text('Remove $name from your emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: FemoraColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteContact(contact['id'] as String);
      _loadContacts();
    }
  }

  // ── Emergency numbers ──────────────────────────────────────────────────────

  Widget _buildEmergencyNumbers() {
    final numbers = [
      _EmergencyNumber(
        label: 'Police',
        number: '119',
        icon: Icons.local_police_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _EmergencyNumber(
        label: 'Ambulance',
        number: '110',
        icon: Icons.local_hospital_rounded,
        color: FemoraColors.error,
      ),
      _EmergencyNumber(
        label: "Women's Help",
        number: '1938',
        icon: Icons.support_agent_rounded,
        color: FemoraColors.primary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Numbers',
          style: FemoraTextStyles.titleLarge.copyWith(
            color: FemoraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        ...numbers.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildEmergencyNumberCard(n),
            )),
      ],
    );
  }

  Widget _buildEmergencyNumberCard(_EmergencyNumber n) {
    return GestureDetector(
      onTap: () => _call(n.number),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FemoraColors.neutralLight),
          boxShadow: [
            BoxShadow(
              color: n.color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: n.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(n.icon, color: n.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.label,
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: FemoraColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  n.number,
                  style: FemoraTextStyles.headlineMedium.copyWith(
                    color: n.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: n.color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: n.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.phone_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Emergency number model ────────────────────────────────────────────────────

class _EmergencyNumber {
  final String label;
  final String number;
  final IconData icon;
  final Color color;

  const _EmergencyNumber({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
  });
}
