import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promemoria')),
      body: AnimatedBuilder(
        animation: NotificationService.instance,
        builder: (context, _) {
          final notifications = NotificationService.instance;
          final showAsOn = notifications.enabled && _osNotificationsGranted;
          return ListView(
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
    );
  }
}
