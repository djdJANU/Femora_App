// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/splash_screen.dart';

/// Profile Screen
/// ───────────────
/// User profile, settings, language, theme, sign out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseConfig.client;

  Map<String, dynamic>? _profile;
  String? _avatarUrl;
  bool _isLoading = true;
  bool _isSigningOut = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadProfile();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _profile = response;
          _avatarUrl = response?['avatar_url'] as String?;
          _isLoading = false;
        });
        _fadeCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: FemoraTextStyles.titleLarge
                .copyWith(color: _textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
            'Are you sure you want to sign out?',
            style: FemoraTextStyles.bodyMedium
                .copyWith(color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: FemoraColors.error),
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, _, _) => const SplashScreen(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningOut = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: FemoraColors.error,
        ));
      }
    }
  }

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditProfileScreen(
          profile: _profile,
          onSaved: _loadProfile,
        ),
      ),
    );
  }

  // ── Theme-aware colour helpers ────────────────────────────────────────────

  bool get _isDark =>
      context.watch<ThemeProvider>().isDark;

  Color get _bgColor =>
      _isDark ? FemoraColors.darkBackground : FemoraColors.lightBackgroundTint;

  Color get _cardColor =>
      _isDark ? FemoraColors.darkSurface : Colors.white;

  Color get _textPrimary =>
      _isDark ? FemoraColors.darkTextPrimary : FemoraColors.textPrimary;

  Color get _textSecondary =>
      _isDark ? FemoraColors.darkTextSecondary : FemoraColors.textSecondary;

  Color get _dividerColor =>
      _isDark ? FemoraColors.darkBorder : FemoraColors.lavenderWhisper;

  Color get _accentBg =>
      _isDark ? FemoraColors.darkLavender : FemoraColors.lavenderWhisper;

  @override
  Widget build(BuildContext context) {
    // Watch providers so screen rebuilds on change
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: _bgColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: FemoraColors.primary))
          : SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildAvatarSection(),
                      const SizedBox(height: 24),
                      _buildSection('Account', [
                        _buildTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Edit Profile',
                          onTap: _openEditProfile,
                        ),
                        _buildDivider(),
                        _buildTile(
                          icon: Icons.bookmark_outline_rounded,
                          label: 'Saved',
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => _SavedScreen(isDark: _isDark))),
                        ),
                        _buildDivider(),
                        _buildTile(
                          icon: Icons.history_rounded,
                          label: 'My Activity',
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => _MyActivityScreen(isDark: _isDark))),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Preferences', [
                        _buildLanguageTile(),
                        _buildDivider(),
                        _buildThemeTile(),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('About', [
                        _buildTile(
                          icon: Icons.info_outline_rounded,
                          label: 'App Version',
                          trailing: Text('1.0.0',
                              style: FemoraTextStyles.caption
                                  .copyWith(color: _textSecondary)),
                          onTap: null,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSignOutButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: _cardColor,
      child: Column(children: [
        Row(children: [
          Text('Profile',
              style: FemoraTextStyles.headlineLarge.copyWith(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
              )),
        ]),
        Container(
          margin: const EdgeInsets.only(top: 14),
          height: 1,
          color: _dividerColor,
        ),
      ]),
    );
  }

  // ── Avatar section ────────────────────────────────────────────────────────

  Widget _buildAvatarSection() {
    final name = (_profile?['full_name'] as String?)?.trim() ?? '';
    final email = _supabase.auth.currentUser?.email ?? '';

    return Column(children: [
      // Tappable avatar with camera badge
      GestureDetector(
        onTap: _showAvatarOptions,
        child: Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FemoraColors.primary.withOpacity(0.12),
                border: Border.all(
                  color: FemoraColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _avatarUrl!,
                        fit: BoxFit.cover,
                        width: 90,
                        height: 90,
                        errorBuilder: (_, _, _) => _buildAvatarInitials(name, email),
                      ),
                    )
                  : _buildAvatarInitials(name, email),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: FemoraColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Name
      if (name.isNotEmpty)
        Text(
          name,
          style: FemoraTextStyles.titleLarge.copyWith(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      const SizedBox(height: 4),

      // Email
      Text(
        email,
        style: FemoraTextStyles.caption.copyWith(color: _textSecondary),
      ),

      // Date of birth if set
      if (_profile?['date_of_birth'] != null) ...[
        const SizedBox(height: 4),
        Text(
          DateFormat('MMMM d, yyyy').format(
              DateTime.parse(_profile!['date_of_birth'])),
          style: FemoraTextStyles.caption.copyWith(color: _textSecondary),
        ),
      ],
    ]);
  }

  Widget _buildAvatarInitials(String name, String email) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : email.isNotEmpty
            ? email[0].toUpperCase()
            : 'F';
    return Center(
      child: Text(
        initials,
        style: FemoraTextStyles.headlineLarge.copyWith(
          color: FemoraColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Profile Photo',
              style: FemoraTextStyles.titleLarge.copyWith(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
              )),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: FemoraColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded,
                  color: FemoraColors.primary, size: 22),
              ),
              title: Text('Choose from Gallery',
                style: FemoraTextStyles.bodyMedium.copyWith(color: _textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: FemoraColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                  color: FemoraColors.primary, size: 22),
              ),
              title: Text('Take Photo',
                style: FemoraTextStyles.bodyMedium.copyWith(color: _textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
              ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: FemoraColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                    color: FemoraColors.error, size: 22),
                ),
                title: Text('Remove Photo',
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: FemoraColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAvatar();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final file = File(picked.path);
      final ext = picked.path.split('.').last.toLowerCase();
      final fileName = '$userId/avatar.$ext';

      await _supabase.storage
          .from('avatars')
          .upload(fileName, file,
              fileOptions: const FileOptions(upsert: true));

      final url = _supabase.storage.from('avatars').getPublicUrl(fileName);
      final cacheBustedUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('profiles')
          .update({'avatar_url': cacheBustedUrl})
          .eq('id', userId);

      if (mounted) {
        setState(() => _avatarUrl = cacheBustedUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: FemoraColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('_pickAndUploadImage error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update photo. Please try again.'),
            backgroundColor: FemoraColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAvatar() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final files = await _supabase.storage.from('avatars').list(path: userId);
      for (final f in files) {
        await _supabase.storage.from('avatars').remove(['$userId/${f.name}']);
      }

      await _supabase
          .from('profiles')
          .update({'avatar_url': null}).eq('id', userId);

      if (mounted) {
        setState(() => _avatarUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed'),
            backgroundColor: FemoraColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('_deleteAvatar error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not remove photo. Please try again.'),
            backgroundColor: FemoraColors.error,
          ),
        );
      }
    }
  }

  // ── Section container ─────────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: FemoraTextStyles.caption.copyWith(
                color: _textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isDark
                      ? Colors.black.withOpacity(0.2)
                      : FemoraColors.primary.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Tile ──────────────────────────────────────────────────────────────────

  Widget _buildTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _accentBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon,
                color: FemoraColors.primary, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                )),
          ),
          trailing ??
              (onTap != null
                  ? Icon(Icons.chevron_right_rounded,
                      color: _textSecondary, size: 18)
                  : const SizedBox.shrink()),
        ]),
      ),
    );
  }

  // ── Language tile ─────────────────────────────────────────────────────────

  Widget _buildLanguageTile() {
    final localeProvider = context.watch<LocaleProvider>();
    final languages = [
      _LangOption(code: 'en', flag: '🇬🇧', label: 'English'),
      _LangOption(code: 'si', flag: '🇱🇰', label: 'සිංහල'),
      _LangOption(code: 'ta', flag: '🇱🇰', label: 'தமிழ்'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _accentBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.language_rounded,
                  color: FemoraColors.primary, size: 17),
            ),
            const SizedBox(width: 14),
            Text('Language',
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                )),
          ]),
          const SizedBox(height: 12),
          Row(children: languages.map((lang) {
            final selected =
                localeProvider.locale.languageCode == lang.code;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => localeProvider
                    .setLocale(Locale(lang.code)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? FemoraColors.primary
                        : _isDark
                            ? FemoraColors.darkSurfaceRaised
                            : FemoraColors.lightBackgroundTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? FemoraColors.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(lang.flag,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(lang.label,
                          style: FemoraTextStyles.caption.copyWith(
                            color: selected
                                ? Colors.white
                                : _textSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  // ── Theme tile ────────────────────────────────────────────────────────────

  Widget _buildThemeTile() {
    final themeProvider = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _accentBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            themeProvider.isDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            color: FemoraColors.primary,
            size: 17,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: themeProvider.isDark,
          onChanged: (_) => themeProvider.toggleTheme(),
          activeColor: FemoraColors.primary,
        ),
      ]),
    );
  }

  // ── Divider ───────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: _dividerColor),
    );
  }

  // ── Sign out button ───────────────────────────────────────────────────────

  Widget _buildSignOutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _isSigningOut ? null : _signOut,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: FemoraColors.error.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FemoraColors.error.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Center(
            child: _isSigningOut
                ? SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: FemoraColors.error,
                      strokeWidth: 2,
                    ))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: FemoraColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text('Sign Out',
                          style: FemoraTextStyles.bodyMedium
                              .copyWith(
                            color: FemoraColors.error,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Edit Profile Screen ───────────────────────────────────────────────────────

class _EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onSaved;

  const _EditProfileScreen({
    required this.profile,
    required this.onSaved,
  });

  @override
  State<_EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _supabase = SupabaseConfig.client;
  final _nameCtrl = TextEditingController();
  DateTime? _selectedDob;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text =
        (widget.profile?['full_name'] as String?) ?? '';
    final dob = widget.profile?['date_of_birth'];
    if (dob != null) _selectedDob = DateTime.tryParse(dob);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now()
          .subtract(const Duration(days: 365 * 13)),
      helpText: 'Select your date of birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: FemoraColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'date_of_birth':
            _selectedDob?.toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: FemoraColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _isDark =>
      context.watch<ThemeProvider>().isDark;

  Color get _bgColor =>
      _isDark ? FemoraColors.darkBackground : Colors.white;

  Color get _fieldBg =>
      _isDark
          ? FemoraColors.darkSurfaceRaised
          : FemoraColors.lightBackgroundTint;

  Color get _textPrimary =>
      _isDark ? FemoraColors.darkTextPrimary : FemoraColors.textPrimary;

  Color get _textSecondary =>
      _isDark
          ? FemoraColors.darkTextSecondary
          : FemoraColors.textSecondary;

  Color get _dividerColor =>
      _isDark ? FemoraColors.darkBorder : FemoraColors.lavenderWhisper;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: _bgColor,
              border: Border(
                bottom: BorderSide(color: _dividerColor, width: 1),
              ),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _isDark
                        ? FemoraColors.darkSurfaceRaised
                        : FemoraColors.lightBackgroundTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: _textPrimary, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Text('Edit Profile',
                  style: FemoraTextStyles.titleLarge.copyWith(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                  )),
            ]),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name',
                      style: FemoraTextStyles.bodyMedium.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: FemoraTextStyles.bodyLarge
                        .copyWith(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      hintStyle: FemoraTextStyles.bodyLarge
                          .copyWith(color: _textSecondary),
                      filled: true,
                      fillColor: _fieldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: FemoraColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('Date of Birth',
                      style: FemoraTextStyles.bodyMedium.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDob,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: _fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: _selectedDob != null
                            ? Border.all(
                                color: FemoraColors.primary
                                    .withOpacity(0.4),
                                width: 1.5)
                            : null,
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            color: _selectedDob != null
                                ? FemoraColors.primary
                                : _textSecondary,
                            size: 18),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDob != null
                              ? DateFormat('MMMM d, yyyy')
                                  .format(_selectedDob!)
                              : 'Select date of birth',
                          style: FemoraTextStyles.bodyLarge
                              .copyWith(
                            color: _selectedDob != null
                                ? _textPrimary
                                : _textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            color: _textSecondary, size: 18),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save button
                  GestureDetector(
                    onTap: _isSaving ? null : _save,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: FemoraColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: FemoraColors.primary
                                .withOpacity(0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ))
                            : Text('Save Changes',
                                style: FemoraTextStyles.bodyLarge
                                    .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Saved Screen ─────────────────────────────────────────────────────────────

class _SavedScreen extends StatefulWidget {
  final bool isDark;
  const _SavedScreen({required this.isDark});

  @override
  State<_SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<_SavedScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseConfig.client;
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _savedPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }

      // Articles: two-step fetch (same pattern as library_screen)
      final savedRows = await _supabase
          .from('mental_saved_articles')
          .select('article_id')
          .eq('user_id', userId);

      final articleIds = (savedRows as List)
          .map((r) => r['article_id'].toString())
          .where((id) => id.isNotEmpty)
          .toList();
      debugPrint('_SavedScreen articleIds: $articleIds');

      List<Map<String, dynamic>> articles = [];
      if (articleIds.isNotEmpty) {
        final fetched = await _supabase
            .from('library_articles')
            .select()
            .inFilter('id', articleIds);
        articles = (fetched as List)
            .where((a) => a['is_published'] != false)
            .map((a) => Map<String, dynamic>.from(a))
            .toList();
      }

      // Posts: fetch liked posts, then resolve author names separately
      // (community_posts has no FK to profiles, so nested join is not possible)
      final postsResponse = await _supabase
          .from('post_likes')
          .select('''
            post_id,
            created_at,
            community_posts!post_likes_post_id_fkey (
              id,
              content,
              category,
              language,
              is_anonymous,
              likes_count,
              comments_count,
              created_at,
              image_url,
              user_id
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('_SavedScreen postsResponse length: ${(postsResponse as List).length}');
      final List<Map<String, dynamic>> rawPosts = [];
      for (final row in postsResponse as List) {
        final post = row['community_posts'];
        if (post == null) continue;
        rawPosts.add({
          ...Map<String, dynamic>.from(post),
          'liked_at': row['created_at'],
        });
      }

      // Resolve author names for non-anonymous posts
      final nonAnonIds = rawPosts
          .where((p) => !(p['is_anonymous'] as bool? ?? false))
          .map((p) => p['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      Map<String, String> nameMap = {};
      if (nonAnonIds.isNotEmpty) {
        final profileRows = await _supabase
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', nonAnonIds);
        for (final p in profileRows as List) {
          nameMap[p['id'] as String] = (p['full_name'] as String?) ?? '';
        }
      }

      final List<Map<String, dynamic>> posts = rawPosts.map((post) {
        return {
          ...post,
          'author_name': (post['is_anonymous'] as bool? ?? false)
              ? null
              : nameMap[post['user_id'] as String?],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _articles = articles;
          _savedPosts = posts;
          _loading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('_SavedScreen._load ERROR: $e');
      debugPrint('_SavedScreen._load STACK: $stack');
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _bg => widget.isDark
      ? FemoraColors.darkBackground
      : FemoraColors.lightBackgroundTint;
  Color get _card => widget.isDark
      ? FemoraColors.darkSurface
      : Colors.white;
  Color get _textPrimary => widget.isDark
      ? FemoraColors.darkTextPrimary
      : FemoraColors.textPrimary;
  Color get _textSecondary => widget.isDark
      ? FemoraColors.darkTextSecondary
      : FemoraColors.textSecondary;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            color: _card,
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        color: _textPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Text('Saved',
                    style: FemoraTextStyles.titleLarge.copyWith(
                      color: _textPrimary,
                      fontWeight: FontWeight.w800,
                    )),
              ]),
              const SizedBox(height: 14),
              TabBar(
                controller: _tabCtrl,
                labelColor: FemoraColors.primary,
                unselectedLabelColor: _textSecondary,
                indicatorColor: FemoraColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: FemoraTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Articles'),
                  Tab(text: 'Posts'),
                ],
              ),
            ]),
          ),
          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: FemoraColors.primary))
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildArticlesList(),
                      _buildPostsList(),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildArticlesList() {
    if (_articles.isEmpty) {
      return _empty('No saved articles yet',
          'Articles you save in the Library will appear here.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final article = _articles[i];
        final title = article['title'] as String? ?? 'Untitled';
        final category = article['category'] as String? ?? '';
        final readTime = article['read_time'] as String? ?? '';
        final subtitle = category.isNotEmpty && readTime.isNotEmpty
            ? '$category • $readTime'
            : category.isNotEmpty
                ? category
                : readTime.isNotEmpty
                    ? readTime
                    : 'Article';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: FemoraColors.primary.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: FemoraColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('📄', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FemoraTextStyles.bodyMedium.copyWith(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: FemoraTextStyles.caption
                        .copyWith(color: _textSecondary)),
              ],
            )),
            Icon(Icons.chevron_right_rounded,
                color: _textSecondary, size: 18),
          ]),
        );
      },
    );
  }

  Widget _buildPostsList() {
    if (_savedPosts.isEmpty) {
      return _empty('No liked posts yet',
          'Posts you like in Community will appear here.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _savedPosts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final post = _savedPosts[i];
        final isAnon = post['is_anonymous'] as bool? ?? false;
        final author = isAnon
            ? 'Anonymous'
            : (post['author_name'] as String? ?? 'Community Member');
        final likes = (post['likes_count'] as num?)?.toInt() ?? 0;
        final initial = isAnon ? '?' : author[0].toUpperCase();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: FemoraColors.primary.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: FemoraColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initial,
                      style: FemoraTextStyles.caption.copyWith(
                        color: FemoraColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(author,
                    style: FemoraTextStyles.caption.copyWith(
                      color: _textSecondary,
                      fontWeight: FontWeight.w600,
                    )),
                ),
                Icon(Icons.favorite_rounded,
                    color: FemoraColors.primary.withValues(alpha: 0.6),
                    size: 14),
                const SizedBox(width: 4),
                Text('$likes',
                    style: FemoraTextStyles.caption
                        .copyWith(color: _textSecondary)),
              ]),
              const SizedBox(height: 8),
              Text(post['content'] as String? ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: _textPrimary, height: 1.4)),
            ],
          ),
        );
      },
    );
  }

  Widget _empty(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline_rounded,
                color: FemoraColors.primary.withValues(alpha: 0.4),
                size: 48),
            const SizedBox(height: 16),
            Text(title,
                style: FemoraTextStyles.bodyLarge.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: FemoraTextStyles.bodyMedium
                    .copyWith(color: _textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── My Activity Screen ────────────────────────────────────────────────────────

class _MyActivityScreen extends StatefulWidget {
  final bool isDark;
  const _MyActivityScreen({required this.isDark});

  @override
  State<_MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<_MyActivityScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseConfig.client;
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _myPosts = [];
  List<Map<String, dynamic>> _myComments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final posts = await _supabase
          .from('community_posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final comments = await _supabase
          .from('post_comments')
          .select('id, content, created_at, is_anonymous, post_id, community_posts(content)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myPosts = List<Map<String, dynamic>>.from(posts);
          _myComments = List<Map<String, dynamic>>.from(comments);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color get _bg => widget.isDark
      ? FemoraColors.darkBackground
      : FemoraColors.lightBackgroundTint;
  Color get _card => widget.isDark
      ? FemoraColors.darkSurface
      : Colors.white;
  Color get _textPrimary => widget.isDark
      ? FemoraColors.darkTextPrimary
      : FemoraColors.textPrimary;
  Color get _textSecondary => widget.isDark
      ? FemoraColors.darkTextSecondary
      : FemoraColors.textSecondary;

  String _timeAgo(String createdAt) {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            color: _card,
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        color: _textPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Text('My Activity',
                    style: FemoraTextStyles.titleLarge.copyWith(
                      color: _textPrimary,
                      fontWeight: FontWeight.w800,
                    )),
              ]),
              const SizedBox(height: 14),
              TabBar(
                controller: _tabCtrl,
                labelColor: FemoraColors.primary,
                unselectedLabelColor: _textSecondary,
                indicatorColor: FemoraColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: FemoraTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'My Posts'),
                  Tab(text: 'My Comments'),
                ],
              ),
            ]),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: FemoraColors.primary))
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildPostsList(),
                      _buildCommentsList(),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPostsList() {
    if (_myPosts.isEmpty) {
      return _empty('No posts yet',
          'Your community posts will appear here.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _myPosts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final post = _myPosts[i];
        final isAnon = post['is_anonymous'] as bool? ?? false;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: FemoraColors.primary.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAnon
                        ? FemoraColors.primary.withValues(alpha: 0.1)
                        : FemoraColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAnon ? 'Anonymous' : 'Named',
                    style: FemoraTextStyles.caption.copyWith(
                      color: isAnon
                          ? FemoraColors.primary
                          : FemoraColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Text(_timeAgo(post['created_at'] as String),
                    style: FemoraTextStyles.caption
                        .copyWith(color: _textSecondary)),
              ]),
              const SizedBox(height: 8),
              Text(post['content'] as String? ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: _textPrimary, height: 1.4)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.favorite_outline_rounded,
                    color: _textSecondary, size: 14),
                const SizedBox(width: 4),
                Text('${post['likes_count'] ?? 0}',
                    style: FemoraTextStyles.caption
                        .copyWith(color: _textSecondary)),
                const SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline_rounded,
                    color: _textSecondary, size: 14),
                const SizedBox(width: 4),
                Text('${post['comments_count'] ?? 0}',
                    style: FemoraTextStyles.caption
                        .copyWith(color: _textSecondary)),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsList() {
    if (_myComments.isEmpty) {
      return _empty('No comments yet',
          'Comments you make in Community will appear here.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _myComments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final comment = _myComments[i];
        final parentPost = comment['community_posts']
            as Map<String, dynamic>?;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: FemoraColors.primary.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parent post preview
              if (parentPost != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: FemoraColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    parentPost['content'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FemoraTextStyles.caption.copyWith(
                      color: _textSecondary, height: 1.4)),
                ),
                const SizedBox(height: 8),
              ],
              // My comment
              Row(children: [
                Icon(Icons.subdirectory_arrow_right_rounded,
                    color: FemoraColors.primary, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(comment['content'] as String? ?? '',
                      style: FemoraTextStyles.bodyMedium.copyWith(
                        color: _textPrimary, height: 1.4)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(_timeAgo(comment['created_at'] as String),
                  style: FemoraTextStyles.caption
                      .copyWith(color: _textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _empty(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                color: FemoraColors.primary.withValues(alpha: 0.4),
                size: 48),
            const SizedBox(height: 16),
            Text(title,
                style: FemoraTextStyles.bodyLarge.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: FemoraTextStyles.bodyMedium
                    .copyWith(color: _textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Language option model ─────────────────────────────────────────────────────

class _LangOption {
  final String code;
  final String flag;
  final String label;

  const _LangOption({
    required this.code,
    required this.flag,
    required this.label,
  });
}
