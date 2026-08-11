import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Nuova versione disponibile: ${info.version}'),
      content: SingleChildScrollView(
        child: Text(
          info.changelog.isEmpty
              ? 'Sono disponibili miglioramenti e correzioni.'
              : info.changelog,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Più tardi'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            await launchUrl(
              Uri.parse(info.apkUrl),
              mode: LaunchMode.externalApplication,
            );
          },
          child: const Text('Scarica e installa'),
        ),
      ],
    ),
  );
}
