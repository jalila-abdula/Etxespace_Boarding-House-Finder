import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../widgets/admin_login_sheet.dart';
import '../widgets/auth_header.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _hide = true;

  /// Runs a sign-in action. Returns true from the action when signed in.
  Future<void> _run(Future<bool> Function() action) async {
    setState(() => _loading = true);
    try {
      final ok = await action();
      // AuthGate now shows the home screen; remove Landing/Login from the stack.
      if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Login failed');
    } catch (e) {
      _toast('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_email.text.trim().isEmpty) {
      _toast('Enter your email first');
      return;
    }
    try {
      await _auth.resetPassword(_email.text);
      _toast('Password reset link sent to your email');
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Could not send reset link');
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            const AuthHeader(),
            const SizedBox(height: 28),
            const Text('Welcome Back!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark)),
            const SizedBox(height: 4),
            Text('Sign in to continue your search.',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loading ? null : () => _run(_auth.signInWithGoogle),
              icon: const Icon(Icons.g_mobiledata, size: 32),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: Text('or', style: TextStyle(color: Colors.grey))),
            ),
            const Text('Email Address',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'juan@example.com'),
            ),
            const SizedBox(height: 12),
            const Text('Password',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _password,
              obscureText: _hide,
              decoration: InputDecoration(
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text('Forgot password?',
                    style: TextStyle(color: Color(0xFF00A844))),
              ),
            ),
            const SizedBox(height: 4),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: _loading
                  ? null
                  : () => _run(() async {
                        await _auth.login(_email.text, _password.text);
                        return true;
                      }),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Login',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ",
                    style: TextStyle(color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text('Register',
                      style: TextStyle(
                          color: Color(0xFF00A844),
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const AdminAccessFooter(),
          ],
        ),
      ),
    );
  }
}