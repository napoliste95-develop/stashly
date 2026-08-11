import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'welcome_dialog_dismissed';

Future<void> maybeShowWelcomeDialog(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_prefsKey) == true) return;
  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _WelcomeDialog(),
  );
}

class _WelcomeDialog extends StatefulWidget {
  const _WelcomeDialog();

  @override
  State<_WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> {
  bool _dontShowAgain = false;

  Future<void> _close() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _point(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Benvenuto su Stashly'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Un posto solo per tutti i contenuti che salvi sui social, '
              'invece di lasciarli sparsi a prendere polvere.',
            ),
            const SizedBox(height: 16),
            _point(
              Icons.ios_share_outlined,
              'Condividi un post da Instagram, TikTok o Pinterest scegliendo '
              'Stashly dal menu "Condividi", oppure aggiungi un link a mano '
              'con il pulsante +.',
            ),
            _point(
              Icons.label_outline,
              'Organizza ogni salvato in una o più categorie, ognuna con un '
              'colore diverso a tua scelta.',
            ),
            _point(
              Icons.edit_outlined,
              'Dai un nome a ogni salvato e modificalo quando vuoi dal menu '
              'sulla carta.',
            ),
            _point(
              Icons.system_update_outlined,
              'L\'app si aggiorna da sola: trovi il controllo manuale in '
              'Impostazioni.',
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
              title: const Text('Non mostrare più questo messaggio'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: _close, child: const Text('Ho capito')),
      ],
    );
  }
}
