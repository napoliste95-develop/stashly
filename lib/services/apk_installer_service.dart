import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ApkInstallerService {
  static const _maxAttempts = 3;

  /// Scarica l'APK dall'url indicato in una cartella temporanea,
  /// riportando l'avanzamento (0.0 - 1.0) tramite [onProgress].
  /// Riprova automaticamente in caso di problemi di rete transitori
  /// (es. connessioni interrotte a metà, comuni su rete mobile).
  Future<File> download(String url, void Function(double progress) onProgress) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      final client = http.Client();
      try {
        onProgress(0);
        final request = http.Request('GET', Uri.parse(url))
          ..followRedirects = true
          ..headers['User-Agent'] = 'Stashly-App'
          ..headers['Connection'] = 'close';
        final response = await client.send(request);

        if (response.statusCode != 200) {
          throw Exception('Download fallito (HTTP ${response.statusCode})');
        }

        final total = response.contentLength ?? 0;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/stashly-update.apk');
        final sink = file.openWrite();

        var received = 0;
        try {
          await response.stream.listen((chunk) {
            sink.add(chunk);
            received += chunk.length;
            if (total > 0) onProgress(received / total);
          }).asFuture<void>();
        } finally {
          await sink.close();
        }

        return file;
      } catch (e) {
        lastError = e;
        if (attempt < _maxAttempts) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } finally {
        client.close();
      }
    }
    throw Exception('Download non riuscito dopo $_maxAttempts tentativi: $lastError');
  }

  /// Avvia l'installer di sistema per il file scaricato. La prima volta
  /// Android potrebbe mostrare un pannello per autorizzare l'installazione
  /// di app da questa fonte (una schermata di sistema, non un browser).
  Future<void> install(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }
}
