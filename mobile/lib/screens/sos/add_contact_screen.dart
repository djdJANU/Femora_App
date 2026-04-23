// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/sos_repository.dart';

/// Add / Edit Emergency Contact Screen
/// ─────────────────────────────────────
/// Pass [existingContact] to enter edit mode.
/// Returns true on successful save so the caller can reload.
class AddContactScreen extends StatefulWidget {
  final Map<String, dynamic>? existingContact;

  const AddContactScreen({super.key, this.existingContact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen>
    with SingleTickerProviderStateMixin {
  final _repo = SosRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String _relationship = 'Family';
  bool _isSaving = false;

  bool get _isEditMode => widget.existingContact != null;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();

    if (_isEditMode) {
      _nameCtrl.text = widget.existingContact!['name'] ?? '';
      _phoneCtrl.text = widget.existingContact!['phone_number'] ?? '';
      _relationship = widget.existingContact!['relationship'] ?? 'Family';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        await _repo.updateContact(
          id: widget.existingContact!['id'],
          name: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          relationship: _relationship,
        );
      } else {
        await _repo.addContact(
          name: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          relationship: _relationship,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: FemoraColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Name ───────────────────────────────────────
                          _buildFieldLabel('Full Name'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _nameCtrl,
                            hint: 'e.g. Amma, Priya',
                            keyboardType: TextInputType.name,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Name is required';
                              }
                              if (v.trim().length > 50) {
                                return 'Name must be 50 characters or less';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── Phone ──────────────────────────────────────
                          _buildFieldLabel('Phone Number'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _phoneCtrl,
                            hint: 'e.g. 0771234567 or +94771234567',
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              final cleaned = v.trim();
                              if (!cleaned.startsWith('0') &&
                                  !cleaned.startsWith('+')) {
                                return 'Must start with 0 or +';
                              }
                              final digits =
                                  cleaned.replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 9 || digits.length > 15) {
                                return 'Must be 9–15 digits';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── Relationship ───────────────────────────────
                          _buildFieldLabel('Relationship'),
                          const SizedBox(height: 12),
                          _buildRelationshipChips(),

                          const SizedBox(height: 36),

                          // ── Save button ────────────────────────────────
                          _buildSaveButton(),
                        ],
                      ),
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

  // ── Header ────────────────────────────────────────────────────────────────

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
        Text(
          _isEditMode ? 'Edit Contact' : 'Add Contact',
          style: FemoraTextStyles.titleLarge.copyWith(
            color: FemoraColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ]),
    );
  }

  // ── Field helpers ─────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: FemoraTextStyles.bodyMedium.copyWith(
        color: FemoraColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: FemoraTextStyles.bodyMedium.copyWith(
        color: FemoraColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: FemoraTextStyles.bodyMedium.copyWith(
          color: FemoraColors.textSecondary.withOpacity(0.6),
        ),
        filled: true,
        fillColor: FemoraColors.lightBackgroundTint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: FemoraColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: FemoraColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: FemoraColors.error, width: 1.5),
        ),
      ),
    );
  }

  // ── Relationship chips ────────────────────────────────────────────────────

  Widget _buildRelationshipChips() {
    const options = ['Family', 'Friend', 'Other'];
    return Row(
      children: options.map((option) {
        final selected = _relationship == option;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _relationship = option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? FemoraColors.lavenderWhisper
                    : FemoraColors.lightBackgroundTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? FemoraColors.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                option,
                style: FemoraTextStyles.bodyMedium.copyWith(
                  color: selected
                      ? FemoraColors.primary
                      : FemoraColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: FemoraColors.primary,
          disabledBackgroundColor: FemoraColors.neutralLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isEditMode ? 'Save Changes' : 'Add Contact',
                style: FemoraTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
