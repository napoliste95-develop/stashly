import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final credential = EmailAuthProvider.credential(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      // Collega l'account anonimo: i salvati esistenti restano tutti.
      await user.linkWithCredential(credential);
    } else {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
    setState(() {});
  }

  Future<void> _login() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    setState(() {});
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isAnonymous) ...[
              Text('Sei connesso come:', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _loading ? null : () => _run(_logout),
                child: const Text('Esci'),
              ),
            ] else ...[
              const Text(
                'Stai usando Stashly senza account: i tuoi salvati sono '
                'legati solo a questo dispositivo. Crea un account per non '
                'perderli se cambi telefono.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : () => _run(_register),
                child: const Text('Crea account (mantieni i salvati)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _loading ? null : () => _run(_login),
                child: const Text('Ho già un account: accedi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
