// lib/screens/users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  UserRole? _filterRole;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Only department heads can access
    if (provider.currentUser?.role != UserRole.departmentHead) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text('Access Restricted', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Only Department Heads can manage users.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    var users = provider.userProfiles;
    if (_filterRole != null) users = users.where((u) => u.role == _filterRole).toList();
    if (_search.isNotEmpty) {
      users = users.where((u) =>
        u.fullName.toLowerCase().contains(_search.toLowerCase()) ||
        u.email.toLowerCase().contains(_search.toLowerCase()) ||
        (u.idNumber?.toLowerCase().contains(_search.toLowerCase()) ?? false)
      ).toList();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'User Management',
            subtitle: 'Manage system users and role permissions',
            action: ElevatedButton.icon(
              onPressed: () => _showUserDialog(context),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Add User'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            ),
          ),
          const SizedBox(height: 20),

          // Role summary cards
          Row(
            children: UserRole.values.map((role) {
              final count = provider.userProfiles.where((u) => u.role == role).length;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filterRole = _filterRole == role ? null : role),
                  child: Container(
                    margin: EdgeInsets.only(right: role != UserRole.values.last ? 12 : 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _filterRole == role ? role.color.withOpacity(0.1) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _filterRole == role ? role.color : AppTheme.border,
                        width: _filterRole == role ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(role.icon, color: role.color, size: 24),
                        const SizedBox(height: 10),
                        Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: role.color)),
                        Text(role.label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Search
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, or ID number...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              if (_filterRole != null) ...[
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(_filterRole!.label),
                  selected: true,
                  onSelected: (_) => setState(() => _filterRole = null),
                  selectedColor: _filterRole!.color.withOpacity(0.15),
                  checkmarkColor: _filterRole!.color,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _filterRole = null),
                ),
              ],
              const SizedBox(width: 12),
              Text('${users.length} users', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: users.isEmpty
                ? const EmptyState(icon: Icons.group_rounded, message: 'No users found.')
                : Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
                          child: const Row(children: [
                            Expanded(flex: 3, child: _UH('Name')),
                            Expanded(flex: 3, child: _UH('Email')),
                            Expanded(flex: 2, child: _UH('ID Number')),
                            Expanded(flex: 2, child: _UH('Role')),
                            Expanded(flex: 2, child: _UH('Department')),
                            Expanded(flex: 2, child: _UH('Lab Assigned')),
                            Expanded(child: _UH('Status')),
                            SizedBox(width: 100),
                          ]),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: users.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                            itemBuilder: (ctx, i) {
                              final user = users[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(children: [
                                  Expanded(flex: 3, child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: user.role.color.withOpacity(0.15),
                                        child: Text(
                                          user.fullName.substring(0, 1).toUpperCase(),
                                          style: TextStyle(fontWeight: FontWeight.w700, color: user.role.color, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(user.fullName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  )),
                                  Expanded(flex: 3, child: Text(user.email,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                    overflow: TextOverflow.ellipsis)),
                                  Expanded(flex: 2, child: Text(user.idNumber ?? '-',
                                    style: const TextStyle(fontSize: 13))),
                                  Expanded(flex: 2, child: _RoleBadge(user.role)),
                                  Expanded(flex: 2, child: Text(user.department ?? '-',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                                  Expanded(flex: 2, child: Text(user.laboratoryName ?? '-',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                                  Expanded(child: Switch.adaptive(
                                    value: user.isActive,
                                    activeColor: AppTheme.success,
                                    onChanged: (val) => provider.toggleUserActive(user.id, val),
                                  )),
                                  SizedBox(width: 100, child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _showUserDialog(context, user: user),
                                        icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        onPressed: () => _confirmDelete(context, user),
                                        icon: const Icon(Icons.delete_rounded, size: 16, color: AppTheme.error),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  )),
                                ]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showUserDialog(BuildContext context, {UserProfile? user}) {
    showDialog(context: context, builder: (_) => _UserFormDialog(user: user));
  }

  void _confirmDelete(BuildContext context, UserProfile user) {
    ConfirmDialog.show(
      context,
      title: 'Delete User',
      content: 'Are you sure you want to delete "${user.fullName}"? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () async {
        final provider = context.read<AppProvider>();
        await provider.deleteUser(user.id);
        if (context.mounted) {
          AppToast.show(context, 'User deleted');
        }
      },
    );
  }
}

class _UH extends StatelessWidget {
  final String label;
  const _UH(this.label);
  @override
  Widget build(BuildContext context) =>
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary));
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge(this.role);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: role.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: role.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 11, color: role.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(role.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: role.color),
              overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// =================== USER FORM DIALOG ===================
class _UserFormDialog extends StatefulWidget {
  final UserProfile? user;
  const _UserFormDialog({this.user});
  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.user?.fullName);
  late final _emailCtrl = TextEditingController(text: widget.user?.email);
  late final _idCtrl = TextEditingController(text: widget.user?.idNumber);
  late final _phoneCtrl = TextEditingController(text: widget.user?.phone);
  final _passwordCtrl = TextEditingController();
  UserRole _role = UserRole.faculty;
  String? _laboratoryId;
  bool _isActive = true;
  bool _obscure = true;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _role = widget.user!.role;
      _laboratoryId = widget.user!.laboratoryId;
      _isActive = widget.user!.isActive;
    }
  }

  @override
  void dispose() {
    for (var c in [_nameCtrl, _emailCtrl, _idCtrl, _phoneCtrl, _passwordCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isEdit = widget.user != null;
    final roleColor = _role.color;

    return Dialog(
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Icon(_role.icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(isEdit ? 'Edit User' : 'Add New User',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(children: [
                    // Error banner shown when save fails
                    if (_saveError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_saveError!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name *'),
                        validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(
                        controller: _idCtrl,
                        decoration: const InputDecoration(labelText: 'ID Number'),
                      )),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isEdit,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          helperText: isEdit ? 'Email cannot be changed' : null,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      )),
                    ]),
                    if (!isEdit) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (!isEdit && (v == null || v.isEmpty)) return 'Required';
                          if (!isEdit && v!.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Role dropdown — full width, Department field removed
                    DropdownButtonFormField<UserRole>(
                      value: _role,
                      decoration: const InputDecoration(labelText: 'Role *'),
                      items: UserRole.values.map((r) => DropdownMenuItem(
                        value: r,
                        child: Row(children: [
                          Icon(r.icon, size: 16, color: r.color),
                          const SizedBox(width: 8),
                          Text(r.label),
                        ]),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _role = v!;
                        // Clear lab when switching to roles that don't need it
                        if (_role != UserRole.laboratoryCustodian &&
                            _role != UserRole.studentAssistant) {
                          _laboratoryId = null;
                        }
                      }),
                    ),
                    // Assigned Laboratory — only visible for custodian & student assistant
                    if (_role == UserRole.laboratoryCustodian ||
                        _role == UserRole.studentAssistant) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        // Guard: only pass value if it actually exists in the items list
                        value: _laboratoryId != null &&
                               (_laboratoryId == 'all' ||
                                provider.laboratories.any((l) => l.id == _laboratoryId))
                            ? _laboratoryId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Laboratory',
                          prefixIcon: Icon(Icons.meeting_room_rounded, size: 18),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Laboratories')),
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ...provider.laboratories.map((l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          )),
                        ],
                        onChanged: (v) => setState(() => _laboratoryId = v),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Active / Inactive toggle
                    Row(
                      children: [
                        Switch.adaptive(
                          value: _isActive,
                          activeColor: AppTheme.success,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                        const SizedBox(width: 8),
                        Text(_isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isActive ? AppTheme.success : AppTheme.textSecondary,
                          )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Role permissions info
                    _PermissionsInfo(role: _role),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: roleColor),
                  child: Text(isEdit ? 'Update User' : 'Create User'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saveError = null);

    final profile = UserProfile(
      id: widget.user?.id ?? '',
      fullName: _nameCtrl.text,
      email: _emailCtrl.text.trim(),
      idNumber: _idCtrl.text.isNotEmpty ? _idCtrl.text : null,
      role: _role,
      department: null, // Department field removed
      // 'all' means no specific lab restriction — store as null in DB
      laboratoryId: (_laboratoryId == 'all') ? null : _laboratoryId,
      phone: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : null,
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<AppProvider>();
    bool success;
    if (widget.user != null) {
      success = await provider.updateUser(widget.user!.id, profile);
    } else {
      success = await provider.createUser(profile, _passwordCtrl.text);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        AppToast.show(context, widget.user != null ? 'User updated!' : 'User created successfully!');
      } else {
        // Show the actual error inside the dialog so it doesn't silently fail
        final errMsg = provider.error ?? 'An unexpected error occurred. Please try again.';
        setState(() => _saveError = errMsg);
      }
    }
  }
}

class _PermissionsInfo extends StatelessWidget {
  final UserRole role;
  const _PermissionsInfo({required this.role});

  @override
  Widget build(BuildContext context) {
    final permissions = <String>[];
    switch (role) {
      case UserRole.departmentHead:
        permissions.addAll(['Manage all equipment & labs', 'Manage users', 'Approve borrowing', 'Print reports', 'Delete records', 'Full system access']);
        break;
      case UserRole.laboratoryCustodian:
        permissions.addAll(['Manage equipment', 'Approve borrowing', 'Manage maintenance', 'Print reports']);
        break;
      case UserRole.faculty:
        permissions.addAll(['Request borrowing', 'View reports']);
        break;
      case UserRole.studentAssistant:
        permissions.addAll(['Request borrowing', 'Process returns']);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: role.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: role.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.shield_rounded, size: 16, color: role.color),
            const SizedBox(width: 8),
            Text('${role.label} Permissions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: role.color)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: permissions.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: role.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(p, style: TextStyle(fontSize: 11, color: role.color, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}