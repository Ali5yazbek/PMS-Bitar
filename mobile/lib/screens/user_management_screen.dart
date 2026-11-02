import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final usersProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/users');
  return res.data as List<dynamic>;
});

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(context, ref, null),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add User', style: TextStyle(color: Colors.white)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Error loading users: $e', style: const TextStyle(color: AppTheme.danger))),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No users found', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              final role = user['role']?.toString() ?? 'unknown';
              Color roleColor = AppTheme.textSecondary;
              
              if (role == 'admin') roleColor = Colors.purpleAccent;
              else if (role == 'agent') roleColor = Colors.blueAccent;
              else if (role == 'maintenance') roleColor = Colors.orangeAccent;
              else if (role == 'tenant') roleColor = AppTheme.success;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceHover),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.2),
                      child: Text(
                        (user['name']?.toString() ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'] ?? 'Unknown User',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['email'] ?? '',
                            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: GoogleFonts.inter(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.primary, size: 20),
                      onPressed: () => _showUserForm(context, ref, user),
                    ),
                    if (user['id'] != 1) // Prevent deleting primary admin visually
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                        onPressed: () => _confirmDelete(context, ref, user),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUserForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserFormSheet(user: user, parentRef: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delete User', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('Are you sure you want to delete ${user['name']}? This action cannot be undone.', style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await ApiService().client.delete('/users/${user['id']}');
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted.'), backgroundColor: AppTheme.success));
                          ref.invalidate(usersProvider);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppTheme.danger));
                        }
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  final Map<String, dynamic>? user;
  final WidgetRef parentRef;
  const _UserFormSheet({required this.user, required this.parentRef});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _nationalIdCtrl;
  String _selectedRole = 'tenant';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?['name'] ?? '');
    _usernameCtrl = TextEditingController(text: widget.user?['username'] ?? '');
    _emailCtrl = TextEditingController(text: widget.user?['email'] ?? '');
    _passwordCtrl = TextEditingController();
    _phoneCtrl = TextEditingController(text: widget.user?['phone'] ?? '');
    _nationalIdCtrl = TextEditingController(text: widget.user?['national_id'] ?? '');
    
    if (widget.user?['role'] != null) {
      _selectedRole = widget.user!['role'];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = {
      'name': _nameCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role': _selectedRole,
      'phone': _phoneCtrl.text.trim(),
      'national_id': _nationalIdCtrl.text.trim(),
    };

    if (_passwordCtrl.text.isNotEmpty) {
      payload['password'] = _passwordCtrl.text;
    } else if (widget.user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password is required for new users'), backgroundColor: AppTheme.warning));
      return;
    }

    try {
      if (widget.user == null) {
        await ApiService().post('/users', data: payload);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created successfully'), backgroundColor: AppTheme.success));
      } else {
        await ApiService().put('/users/${widget.user!['id']}', data: payload);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully'), backgroundColor: AppTheme.success));
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.parentRef.invalidate(usersProvider);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: $e'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.user == null ? 'Create New User' : 'Update User',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildField('Full Name', _nameCtrl, required: true),
              const SizedBox(height: 16),
              _buildField('Email Address', _emailCtrl, required: true),
              const SizedBox(height: 16),
              _buildField('Username (Optional)', _usernameCtrl),
              const SizedBox(height: 16),
              _buildField('Password', _passwordCtrl, obscure: true, hint: widget.user != null ? 'Leave blank to keep unchanged' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: AppTheme.surfaceHover,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'User Role',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'agent', child: Text('Agent')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                  DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 16),
              _buildField('Phone (Optional)', _phoneCtrl),
              const SizedBox(height: 16),
              _buildField('National ID (Optional)', _nationalIdCtrl),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.user == null ? 'Create User' : 'Save Changes', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool obscure = false, String? hint, bool required = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      validator: required ? (v) => v == null || v.isEmpty ? 'This field is required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
