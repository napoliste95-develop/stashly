import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Estrae il primo link trovato in un testo condiviso (alcune app aggiungono
/// testo extra prima o dopo il link). Riconosce sia URL con schema esplicito
/// (`https://...`) sia domini "nudi" (es. `instagram.com/p/xyz`), a cui viene
/// anteposto `https://`.
String? extractUrl(String text) {
  final withScheme = RegExp(r'https?://\S+').firstMatch(text);
  if (withScheme != null) return withScheme.group(0);

  final bareDomain = RegExp(
    r'\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:/\S*)?',
  ).firstMatch(text);
  if (bareDomain != null) return 'https://${bareDomain.group(0)}';

  return null;
}

class ShareIntentService {
  static final ShareIntentService instance = ShareIntentService._();
  ShareIntentService._();

  StreamSubscription? _sub;

  void init(void Function(String url) onSharedUrl) {
    _sub?.cancel();
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
      final text = file.path.trim();
      if (text.isEmpty) continue;
      // Se non troviamo un link riconoscibile, apriamo comunque il foglio
      // con il testo condiviso così com'è: meglio farlo correggere
      // all'utente che fallire in silenzio senza aprire nulla.
      onSharedUrl(extractUrl(text) ?? text);
      return;
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
