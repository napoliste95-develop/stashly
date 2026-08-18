import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/firestore_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? _authValidationError() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      return 'Inserisci email e password.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Inserisci un indirizzo email valido (es. nome@esempio.com).';
    }
    if (password.length < 6) {
      return 'La password deve contenere almeno 6 caratteri.';
    }
    return null;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        setState(() => _error =
            'Esiste già un account con questa email, creato con password. '
            'Accedi con email e password per collegarlo a Google in un '
            'secondo momento.');
      } else {
        setState(() => _error = e.message ?? e.code);
      }
    } catch (e) {
      // Bug noto del plugin firebase_auth su Android: quando la vera
      // eccezione non viene serializzata correttamente sul canale Pigeon,
      // arriva solo il nome grezzo del canale invece del vero errore.
      final raw = e.toString().toLowerCase();
      if (raw.contains('pigeon') || raw.contains('channel-error')) {
        setState(() => _error =
            'Non è stato possibile completare l\'operazione a causa di un '
            'problema di comunicazione con il servizio di accesso. Controlla '
            'che email e password siano corretti — oppure che l\'account non '
            'esista già, se stai creando un nuovo account — e riprova.');
      } else {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    final validationError = _authValidationError();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    await _run(action);
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

  Future<void> _loginWithGoogle() async {
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      rethrow;
    }
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        // Collega l'account anonimo: i salvati esistenti restano tutti.
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // Questo account Google è già collegato a un altro utente Stashly:
          // non è un collegamento, è un login su quell'account esistente.
          await _switchToExistingGoogleAccount(credential);
          return;
        }
        rethrow;
      }
    } else {
      await FirebaseAuth.instance.signInWithCredential(credential);
    }
    setState(() {});
  }

  Future<void> _switchToExistingGoogleAccount(AuthCredential credential) async {
    final items = await FirestoreService().getAllItemsOnce();
    if (items.isNotEmpty) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Account Google già collegato altrove'),
          content: Text(
            'Questo account Google è già collegato a un altro account Stashly. '
            'Se continui accederai a quell\'account: i salvati di questa sessione '
            '(${items.length}) non saranno più visibili, a meno che tu non li '
            'esporti ora da Impostazioni → Esporta dati e li importi dopo aver '
            'effettuato l\'accesso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Accedi comunque'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await FirebaseAuth.instance.signInWithCredential(credential);
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
              OutlinedButton.icon(
                onPressed: _loading ? null : () => _run(_loginWithGoogle),
                icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                label: const Text('Continua con Google'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('oppure', style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
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
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    tooltip: _obscurePassword
                        ? 'Mostra password'
                        : 'Nascondi password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : () => _runAuthAction(_register),
                child: const Text('Crea account (mantieni i salvati)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _loading ? null : () => _runAuthAction(_login),
                child: const Text('Ho già un account: accedi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
