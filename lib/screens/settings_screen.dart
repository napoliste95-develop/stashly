import 'package:flutter/material.dart';

import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'appearance_settings_screen.dart';
import 'feedback_screen.dart';
import 'reminder_settings_screen.dart';
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
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Aspetto'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Promemoria'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()),
            ),
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
  }
}
