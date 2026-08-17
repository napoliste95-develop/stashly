import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Estrae il primo link http/https trovato in un testo condiviso
/// (alcune app aggiungono testo extra prima o dopo il link).
String? extractUrl(String text) {
  final match = RegExp(r'https?://\S+').firstMatch(text);
  return match?.group(0);
}

class ShareIntentService {
  static final ShareIntentService instance = ShareIntentService._();
  ShareIntentService._();

  StreamSubscription? _sub;

  void init(void Function(String url) onSharedUrl) {
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _handle(files, onSharedUrl),
    );

    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handle(files, onSharedUrl);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handle(List<SharedMediaFile> files, void Function(String url) onSharedUrl) {
    for (final file in files) {
      final url = extractUrl(file.path);
      if (url != null) {
        onSharedUrl(url);
        return;
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
