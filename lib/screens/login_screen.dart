// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final provider = context.read<AppProvider>();
    final success = await provider.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!success && mounted) {
      setState(() {
        _loading = false;
        final providerError = provider.error?.toLowerCase() ?? '';
        final isNetworkError = providerError.contains('timeout') ||
            providerError.contains('504') ||
            providerError.contains('network') ||
            providerError.contains('fetch') ||
            providerError.contains('socket') ||
            providerError.contains('connection');
        _error = isNetworkError
            ? 'Connection timed out. Please check your internet and try again.'
            : 'Invalid email or password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Left panel – branding
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.computer_rounded, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'CCS Laboratory\nManagement System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Manage laboratory equipment, track borrowing,\nschedule maintenance, and generate reports.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 48),
                    ...[
                      _Feature(Icons.inventory_2_rounded, 'Equipment Tracking'),
                      _Feature(Icons.swap_horiz_rounded, 'Borrowing Management'),
                      _Feature(Icons.build_rounded, 'Maintenance Scheduling'),
                      _Feature(Icons.map_rounded, 'Interactive Lab Floor Map'),
                      _Feature(Icons.print_rounded, 'Print Reports'),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Right panel – login form
          Expanded(
            flex: 4,
            child: Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to your account',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 40),

                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _error!.contains('timed out') || _error!.contains('Connection')
                                          ? Icons.wifi_off_rounded
                                          : Icons.error_outline_rounded,
                                      color: AppTheme.error,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                                    ),
                                  ],
                                ),
                                if (_error!.contains('timed out') || _error!.contains('Connection')) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                      onPressed: _loading ? null : _signIn,
                                      icon: const Icon(Icons.refresh_rounded, size: 15),
                                      label: const Text('Tap to retry', style: TextStyle(fontSize: 13)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.error,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        alignment: Alignment.centerLeft,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined, size: 18),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                          onFieldSubmitted: (_) => _signIn(),
                        ),
                        const SizedBox(height: 20),

                        const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outlined, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                          onFieldSubmitted: (_) => _signIn(),
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signIn,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: AppTheme.border),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Contact your Department Head to get access.',
                            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}