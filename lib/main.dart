import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/error_log_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ErrorLogService.instance.load();
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        await ErrorLogService.instance.log('Errore accesso anonimo: $e');
        rethrow;
      }
    }
    await FirestoreService().migrateMarkExistingItemsAsSeenIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _ensureSignedIn(),
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
