import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeService.instance.load();
  await Workmanager().initialize(callbackDispatcher);
  await NotificationService.instance.load();
  runApp(const StashlyApp());
}

class StashlyApp extends StatelessWidget {
  const StashlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Stashly',
          themeMode: ThemeService.instance.mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Creato una sola volta (non ad ogni build): un Future nuovo ad ogni
  // rebuild farebbe ripartire il FutureBuilder da "waiting", smontando
  // HomeScreen (e con essa il listener delle condivisioni) ogni volta che
  // StashlyApp si ricostruisce, es. al cambio tema.
  late final Future<void> _signInFuture = _ensureSignedIn();

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    await FirestoreService().migrateMarkExistingItemsAsSeenIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _signInFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Errore di accesso: ${snapshot.error}')),
          );
        }
        return const HomeScreen();
      },
    );
  }
}
