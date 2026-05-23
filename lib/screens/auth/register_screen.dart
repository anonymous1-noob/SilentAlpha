import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _handleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _handleCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      handle: _handleCtrl.text.trim().toLowerCase(),
    );
    if (!mounted) return;
    if (ok) {
      // Sign out immediately so the user lands on the login screen
      await auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Sign in to continue.'),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(); // back to login
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  child: const Text(
                    'Create account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: const Text(
                    'Join the finance conversation',
                    style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 36),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: TextFormField(
                    controller: _handleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Handle (e.g. vikas_trades)',
                      prefixIcon: Icon(Icons.alternate_email, color: AppTheme.onSurfaceMuted),
                      helperText: 'Unique · lowercase · no spaces',
                      helperStyle: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11),
                    ),
                    onChanged: (v) {
                      final clean = v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
                      if (clean != v) {
                        _handleCtrl.value = _handleCtrl.value.copyWith(
                          text: clean,
                          selection: TextSelection.collapsed(offset: clean.length),
                        );
                      }
                    },
                    validator: (v) {
                      if (v == null || v.length < 3) return 'Min 3 characters';
                      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) return 'Only letters, numbers, underscores';
                      if (v.toLowerCase() == 'anonymous') return '"anonymous" is a reserved handle';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 280),
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.onSurfaceMuted),
                    ),
                    validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 360),
                  child: TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.onSurfaceMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.onSurfaceMuted,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                  ),
                ),
                const SizedBox(height: 28),
                FadeInUp(
                  delay: const Duration(milliseconds: 440),
                  child: GradientButton(
                    label: 'Create Account',
                    loading: auth.loading,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: const Center(
                    child: Text(
                      'By signing up you agree to our terms of service.',
                      style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                      textAlign: TextAlign.center,
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
}
