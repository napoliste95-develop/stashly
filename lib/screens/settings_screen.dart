import 'package:flutter/material.dart';

import '../services/notification_service.dart';
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
  bool _osNotificationsGranted = true;

  @override
  void initState() {
    super.initState();
    _refreshOsPermission();
  }

  Future<void> _refreshOsPermission() async {
    final granted = await NotificationService.instance.hasOsPermission();
    if (mounted) setState(() => _osNotificationsGranted = granted);
  }

  Future<void> _onReminderToggled(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermissionIfNeeded();
      await _refreshOsPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permesso notifiche negato. Attivalo dalle impostazioni di sistema per ricevere il promemoria.',
            ),
          ),
        );
        return;
      }
    }
    await NotificationService.instance.setEnabled(value);
  }

  Future<void> _pickWeekday(int? weekday) async {
    if (weekday == null) return;
    await NotificationService.instance.setSchedule(
      weekday: weekday,
      time: NotificationService.instance.time,
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: NotificationService.instance.time,
    );
    if (picked != null) {
      await NotificationService.instance.setSchedule(
        weekday: NotificationService.instance.weekday,
        time: picked,
      );
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
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Promemoria settimanale', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                AnimatedBuilder(
                  animation: NotificationService.instance,
                  builder: (context, _) {
                    final notifications = NotificationService.instance;
                    final showAsOn = notifications.enabled && _osNotificationsGranted;
                    return Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Ricordami i salvati non visti'),
                          subtitle: Text(
                            !notifications.enabled
                                ? 'Disattivato'
                                : !_osNotificationsGranted
                                    ? 'Permesso negato — attivalo dalle impostazioni di sistema'
                                    : 'Ogni ${weekdayLabel(notifications.weekday)} alle '
                                        '${notifications.time.format(context)}',
                          ),
                          value: showAsOn,
                          onChanged: _onReminderToggled,
                        ),
                        if (notifications.enabled && !_osNotificationsGranted)
                          ListTile(
                            leading: const Icon(Icons.settings_outlined),
                            title: const Text('Apri impostazioni di sistema'),
                            onTap: () => NotificationService.instance.openSystemSettings(),
                          ),
                        if (showAsOn) ...[
                          ListTile(
                            title: const Text('Giorno'),
                            trailing: DropdownButton<int>(
                              value: notifications.weekday,
                              items: List.generate(
                                7,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text(weekdayLabel(i + 1)),
                                ),
                              ),
                              onChanged: _pickWeekday,
                            ),
                          ),
                          ListTile(
                            title: const Text('Ora'),
                            trailing: Text(notifications.time.format(context)),
                            onTap: _pickTime,
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              'La consegna esatta dipende dalle impostazioni di risparmio energetico del telefono.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
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
