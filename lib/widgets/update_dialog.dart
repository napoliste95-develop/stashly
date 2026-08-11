import 'package:flutter/material.dart';

import '../services/apk_installer_service.dart';
import '../services/update_service.dart';

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _UpdateDialog(info: info),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;

  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

enum _Stage { prompt, downloading, installing, error }

class _UpdateDialogState extends State<_UpdateDialog> {
  final _installer = ApkInstallerService();
  _Stage _stage = _Stage.prompt;
  double _progress = 0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _stage = _Stage.downloading;
      _progress = 0;
    });
    try {
      final file = await _installer.download(
        widget.info.apkUrl,
        (p) => setState(() => _progress = p),
      );
      setState(() => _stage = _Stage.installing);
      await _installer.install(file);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _stage = _Stage.error;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuova versione disponibile: ${widget.info.version}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_stage == _Stage.prompt) ...[
              Text(
                widget.info.changelog.isEmpty
                    ? 'Sono disponibili miglioramenti e correzioni.'
                    : widget.info.changelog,
              ),
            ] else if (_stage == _Stage.downloading) ...[
              Text('Download in corso... ${(_progress * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            ] else if (_stage == _Stage.installing) ...[
              const Text('Download completato, avvio installazione...'),
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ] else if (_stage == _Stage.error) ...[
              Text('Qualcosa è andato storto: $_error'),
            ],
          ],
        ),
      ),
      actions: _stage == _Stage.prompt
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Più tardi'),
              ),
              FilledButton(
                onPressed: _startUpdate,
                child: const Text('Scarica e installa'),
              ),
            ]
          : _stage == _Stage.error
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Chiudi'),
                  ),
                  FilledButton(
                    onPressed: _startUpdate,
                    child: const Text('Riprova'),
                  ),
                ]
              : [],
    );
  }
}
