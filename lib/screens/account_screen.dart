// lib/screens/account_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _profileKey  = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _idNumberCtrl;
  late TextEditingController _departmentCtrl;

  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent  = true;
  bool _obscureNew      = true;
  bool _obscureConfirm  = true;

  bool _savingProfile   = false;
  bool _savingPassword  = false;
  bool _uploadingAvatar = false;

  String? _profileSuccess;
  String? _profileError;
  String? _passwordSuccess;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final user      = context.read<AppProvider>().currentUser;
    _nameCtrl       = TextEditingController(text: user?.fullName   ?? '');
    _phoneCtrl      = TextEditingController(text: user?.phone      ?? '');
    _idNumberCtrl   = TextEditingController(text: user?.idNumber   ?? '');
    _departmentCtrl = TextEditingController(text: user?.department ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _idNumberCtrl.dispose();
    _departmentCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Save profile ──────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    setState(() {
      _savingProfile  = true;
      _profileError   = null;
      _profileSuccess = null;
    });
    try {
      final provider = context.read<AppProvider>();
      final user     = provider.currentUser!;
      final updated  = UserProfile(
        id:           user.id,
        fullName:     _nameCtrl.text.trim(),
        email:        user.email,
        idNumber:     _idNumberCtrl.text.trim().isEmpty ? null : _idNumberCtrl.text.trim(),
        role:         user.role,
        department:   _departmentCtrl.text.trim().isEmpty ? null : _departmentCtrl.text.trim(),
        laboratoryId: user.laboratoryId,
        phone:        _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        isActive:     user.isActive,
        avatarUrl:    user.avatarUrl,
        createdAt:    user.createdAt,
        updatedAt:    DateTime.now(),
      );
      final ok = await provider.updateCurrentUserProfile(updated);
      if (mounted) {
        setState(() {
          if (ok) _profileSuccess = 'Profile updated successfully!';
          else    _profileError   = 'Failed to update profile. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  // ── Change password ───────────────────────────────────────
  Future<void> _changePassword() async {
    if (!_passwordKey.currentState!.validate()) return;
    setState(() {
      _savingPassword  = true;
      _passwordError   = null;
      _passwordSuccess = null;
    });
    try {
      final user = context.read<AppProvider>().currentUser!;
      // Verify current password first by re-signing in
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: user.email,
          password: _currentPassCtrl.text,
        );
      } catch (_) {
        if (mounted) setState(() => _passwordError = 'Current password is incorrect.');
        return;
      }
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: _newPassCtrl.text));
      if (mounted) {
        setState(() {
          _passwordSuccess = 'Password changed successfully!';
          _currentPassCtrl.clear();
          _newPassCtrl.clear();
          _confirmPassCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _passwordError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  // ── Pick & upload avatar via file_picker ──────────────────
  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // loads bytes into memory — needed for web & desktop
    );
    if (result == null || result.files.isEmpty) return;

    final file  = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        AppToast.show(context, 'Could not read image bytes. Please try another file.', type: ToastType.error);
      }
      return;
    }

    setState(() => _uploadingAvatar = true);
    try {
      final provider = context.read<AppProvider>();
      final user     = provider.currentUser!;
      final ext      = (file.extension ?? 'jpg').toLowerCase();
      final path     = 'avatars/${user.id}.$ext';

      // Upload to Supabase Storage bucket named 'avatars'
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
          );

      // Get the public URL and save it to the user profile
      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      await Supabase.instance.client
          .from('user_profiles')
          .update({'avatar_url': publicUrl}).eq('id', user.id);

      // Refresh the current user in the provider
      await provider.checkAuth();

      if (mounted) {
        AppToast.show(context, 'Profile picture updated!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Upload failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'My Account',
            subtitle: 'Manage your profile information and security settings',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: avatar card
                _AvatarCard(
                  user: user,
                  uploading: _uploadingAvatar,
                  onChangePhoto: _pickAndUploadAvatar,
                ),
                const SizedBox(width: 24),
                // Right: forms
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _ProfileForm(
                          formKey:        _profileKey,
                          nameCtrl:       _nameCtrl,
                          email:          user.email,
                          phoneCtrl:      _phoneCtrl,
                          idNumberCtrl:   _idNumberCtrl,
                          departmentCtrl: _departmentCtrl,
                          saving:         _savingProfile,
                          successMessage: _profileSuccess,
                          errorMessage:   _profileError,
                          onSave:         _saveProfile,
                        ),
                        const SizedBox(height: 20),
                        _PasswordForm(
                          formKey:         _passwordKey,
                          currentCtrl:     _currentPassCtrl,
                          newCtrl:         _newPassCtrl,
                          confirmCtrl:     _confirmPassCtrl,
                          newPassCtrl:     _newPassCtrl,
                          obscureCurrent:  _obscureCurrent,
                          obscureNew:      _obscureNew,
                          obscureConfirm:  _obscureConfirm,
                          onToggleCurrent: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          onToggleNew:     () => setState(() => _obscureNew     = !_obscureNew),
                          onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          saving:          _savingPassword,
                          successMessage:  _passwordSuccess,
                          errorMessage:    _passwordError,
                          onSave:          _changePassword,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Avatar Card
// ════════════════════════════════════════════════════════════
class _AvatarCard extends StatefulWidget {
  final UserProfile  user;
  final bool         uploading;
  final VoidCallback onChangePhoto;

  const _AvatarCard({
    required this.user,
    required this.uploading,
    required this.onChangePhoto,
  });

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard> {
  bool _avatarLoadFailed = false;

  @override
  void didUpdateWidget(_AvatarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.avatarUrl != widget.user.avatarUrl) {
      _avatarLoadFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty && !_avatarLoadFailed;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Avatar with camera-button overlay ──
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: user.role.color.withOpacity(0.15),
                backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl!) : null,
                onBackgroundImageError: hasAvatar
                    ? (_, __) {
                        if (mounted) setState(() => _avatarLoadFailed = true);
                      }
                    : null,
                child: !hasAvatar
                    ? Text(
                        user.fullName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: user.role.color),
                      )
                    : null,
              ),
              GestureDetector(
                onTap: widget.uploading ? null : widget.onChangePhoto,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: widget.uploading
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(user.fullName,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: user.role.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: user.role.color.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(user.role.icon, size: 12, color: user.role.color),
              const SizedBox(width: 5),
              Text(user.role.label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: user.role.color)),
            ]),
          ),
          const SizedBox(height: 8),

          Text(user.email,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),

          _InfoRow(Icons.badge_rounded,        'ID',    user.idNumber   ?? '—'),
          const SizedBox(height: 8),
          _InfoRow(Icons.phone_rounded,        'Phone', user.phone      ?? '—'),
          const SizedBox(height: 8),
          _InfoRow(Icons.apartment_rounded,    'Dept',  user.department ?? '—'),
          if (user.laboratoryName != null) ...[
            const SizedBox(height: 8),
            _InfoRow(Icons.meeting_room_rounded, 'Lab', user.laboratoryName!),
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.uploading ? null : widget.onChangePhoto,
              icon: widget.uploading
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary))
                  : const Icon(Icons.upload_rounded, size: 16),
              label: Text(widget.uploading ? 'Uploading…' : 'Change Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: AppTheme.textSecondary),
      const SizedBox(width: 6),
      Text('$label: ',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}

// ════════════════════════════════════════════════════════════
// Profile Form
// ════════════════════════════════════════════════════════════
class _ProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, phoneCtrl, idNumberCtrl, departmentCtrl;
  final String  email;
  final bool    saving;
  final String? successMessage;
  final String? errorMessage;
  final VoidCallback onSave;

  const _ProfileForm({
    required this.formKey,
    required this.nameCtrl,
    required this.email,
    required this.phoneCtrl,
    required this.idNumberCtrl,
    required this.departmentCtrl,
    required this.saving,
    this.successMessage,
    this.errorMessage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FormHeader(
              icon: Icons.person_rounded,
              title: 'Profile Information',
              subtitle: 'Update your name, phone, and other personal details.',
            ),
            const SizedBox(height: 20),

            if (successMessage != null)
              _AlertBanner(message: successMessage!, isError: false),
            if (errorMessage != null)
              _AlertBanner(message: errorMessage!, isError: true),

            Row(children: [
              Expanded(child: _Field(
                  label: 'Full Name', controller: nameCtrl,
                  icon: Icons.person_outline_rounded, required: true)),
              const SizedBox(width: 16),
              Expanded(child: _Field(
                  label: 'ID Number', controller: idNumberCtrl,
                  icon: Icons.badge_outlined)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _ReadOnlyField(
                  label: 'Email', value: email,
                  icon: Icons.email_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _Field(
                  label: 'Phone', controller: phoneCtrl,
                  icon: Icons.phone_outlined)),
            ]),
            const SizedBox(height: 14),
            _Field(label: 'Department', controller: departmentCtrl,
                icon: Icons.apartment_outlined),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 16),
                label: Text(saving ? 'Saving…' : 'Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Password Form
// ════════════════════════════════════════════════════════════
class _PasswordForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController currentCtrl, newCtrl, confirmCtrl, newPassCtrl;
  final bool obscureCurrent, obscureNew, obscureConfirm;
  final VoidCallback onToggleCurrent, onToggleNew, onToggleConfirm;
  final bool    saving;
  final String? successMessage;
  final String? errorMessage;
  final VoidCallback onSave;

  const _PasswordForm({
    required this.formKey,
    required this.currentCtrl,
    required this.newCtrl,
    required this.confirmCtrl,
    required this.newPassCtrl,
    required this.obscureCurrent,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.onToggleCurrent,
    required this.onToggleNew,
    required this.onToggleConfirm,
    required this.saving,
    this.successMessage,
    this.errorMessage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FormHeader(
              icon: Icons.lock_rounded,
              title: 'Change Password',
              subtitle: 'Choose a strong password with at least 8 characters.',
            ),
            const SizedBox(height: 20),

            if (successMessage != null)
              _AlertBanner(message: successMessage!, isError: false),
            if (errorMessage != null)
              _AlertBanner(message: errorMessage!, isError: true),

            _PasswordField(
              label: 'Current Password',
              controller: currentCtrl,
              obscure: obscureCurrent,
              onToggle: onToggleCurrent,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _PasswordField(
                label: 'New Password',
                controller: newCtrl,
                obscure: obscureNew,
                onToggle: onToggleNew,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'Minimum 8 characters';
                  return null;
                },
              )),
              const SizedBox(width: 16),
              Expanded(child: _PasswordField(
                label: 'Confirm New Password',
                controller: confirmCtrl,
                obscure: obscureConfirm,
                onToggle: onToggleConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != newPassCtrl.text) return 'Passwords do not match';
                  return null;
                },
              )),
            ]),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.lock_reset_rounded, size: 16),
                label: Text(saving ? 'Updating…' : 'Update Password'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared small widgets
// ════════════════════════════════════════════════════════════
class _FormHeader extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  const _FormHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool required;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            prefixIcon: Icon(icon, size: 16),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary)),
            ),
            const Tooltip(
              message: 'Email cannot be changed here',
              child: Icon(Icons.lock_outline,
                  size: 14, color: AppTheme.textSecondary),
            ),
          ]),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined, size: 16),
            suffixIcon: IconButton(
              icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 16),
              onPressed: onToggle,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String message;
  final bool   isError;
  const _AlertBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppTheme.error : AppTheme.success;
    final icon  = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 13))),
      ]),
    );
  }
}