import 'package:flutter/material.dart';

import '../services/link_check_service.dart';
import '../services/notification_service.dart';

class LinkCheckSettingsScreen extends StatefulWidget {
  const LinkCheckSettingsScreen({super.key});

  @override
  State<LinkCheckSettingsScreen> createState() => _LinkCheckSettingsScreenState();
}

class _LinkCheckSettingsScreenState extends State<LinkCheckSettingsScreen> {
  bool _osNotificationsGranted = true;
  bool _checkingAll = false;

  @override
  void initState() {
    super.initState();
    _refreshOsPermission();
  }

  Future<void> _refreshOsPermission() async {
    final granted = await NotificationService.instance.hasOsPermission();
    if (mounted) setState(() => _osNotificationsGranted = granted);
  }

  Future<void> _onToggled(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermissionIfNeeded();
      await _refreshOsPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permesso notifiche negato. Attivalo dalle impostazioni di sistema per ricevere l\'avviso.',
            ),
          ),
        );
        return;
      }
    }
    await LinkCheckService.instance.setEnabled(value);
  }

  Future<void> _checkAllNow() async {
    setState(() => _checkingAll = true);
    try {
      final result = await LinkCheckService.instance.checkAllNow();
      if (!mounted) return;
      final deadCount = result.newlyDead.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.totalChecked} link verificati, '
            '$deadCount forse non più disponibili.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verifica non riuscita: $e')),
      );
    } finally {
      if (mounted) setState(() => _checkingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controllo link')),
      body: AnimatedBuilder(
        animation: LinkCheckService.instance,
        builder: (context, _) {
          final linkCheck = LinkCheckService.instance;
          final showAsOn = linkCheck.enabled && _osNotificationsGranted;
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Controlla automaticamente i link salvati'),
                subtitle: Text(
                  !linkCheck.enabled
                      ? 'Disattivato. Basato sul codice di risposta del sito: alcuni contenuti '
                          'rimossi potrebbero non essere rilevati.'
                      : !_osNotificationsGranted
                          ? 'Permesso negato — attivalo dalle impostazioni di sistema'
                          : 'Una volta a settimana, con avviso solo se trova nuovi link '
                              'probabilmente non più disponibili.',
                ),
                value: showAsOn,
                onChanged: _onToggled,
              ),
              if (linkCheck.enabled && !_osNotificationsGranted)
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Apri impostazioni di sistema'),
                  onTap: () => NotificationService.instance.openSystemSettings(),
                ),
              const Divider(),
              ListTile(
                leading: _checkingAll
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link_outlined),
                title: const Text('Verifica tutti i link ora'),
                onTap: _checkingAll ? null : _checkAllNow,
              ),
            ],
          );
        },
      ),
    );
  }
}
