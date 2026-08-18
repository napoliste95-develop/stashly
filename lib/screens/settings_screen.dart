import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/backup_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'appearance_settings_screen.dart';
import 'feedback_screen.dart';
import 'link_check_settings_screen.dart';
import 'reminder_settings_screen.dart';
import 'version_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checkingUpdate = false;
  bool _exporting = false;
  bool _importing = false;

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final file = await BackupService().exportToFile();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Backup Stashly'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Esportazione non riuscita: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importData() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file?.path == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importa dati'),
        content: const Text(
          'Gli elementi e le categorie del file selezionato verranno aggiunti alla tua libreria attuale. Procedere?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _importing = true);
    try {
      final jsonString = await File(file!.path!).readAsString();
      final count = await BackupService().importFromJson(jsonString);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1 ? '1 elemento importato.' : '$count elementi importati.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importazione non riuscita: $e')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

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
          ListTile(
            leading: const Icon(Icons.link_off),
            title: const Text('Controllo link'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LinkCheckSettingsScreen()),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Dati', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: _exporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            title: const Text('Esporta i tuoi dati'),
            onTap: _exporting ? null : _exportData,
          ),
          ListTile(
            leading: _importing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_upload_outlined),
            title: const Text('Importa dati'),
            onTap: _importing ? null : _importData,
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
