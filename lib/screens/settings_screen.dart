import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'error_log_screen.dart';
import 'feedback_screen.dart';
import 'version_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checkingUpdate = false;

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final info = await UpdateService().checkForUpdate();
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hai già la versione più recente.')),
        );
      } else {
        await showUpdateDialog(context, info);
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: AnimatedBuilder(
        animation: ThemeService.instance,
        builder: (context, _) {
          return RadioGroup<ThemeMode>(
            groupValue: ThemeService.instance.mode,
            onChanged: (m) => ThemeService.instance.setMode(m!),
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Tema', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const RadioListTile<ThemeMode>(
                  title: Text('Segui sistema'),
                  value: ThemeMode.system,
                ),
                const RadioListTile<ThemeMode>(
                  title: Text('Chiaro'),
                  value: ThemeMode.light,
                ),
                const RadioListTile<ThemeMode>(
                  title: Text('Scuro'),
                  value: ThemeMode.dark,
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text('Informazioni', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: _checkingUpdate
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update_outlined),
                  title: const Text('Controlla aggiornamenti'),
                  onTap: _checkingUpdate ? null : _checkForUpdate,
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Versione'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VersionScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Log errori'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ErrorLogScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Segnala un problema o proponi una funzionalità'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
