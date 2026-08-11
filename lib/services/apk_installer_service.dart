import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'error_log_service.dart';

class ApkInstallerService {
  /// Scarica l'APK dall'url indicato in una cartella temporanea,
  /// riportando l'avanzamento (0.0 - 1.0) tramite [onProgress].
  Future<File> download(String url, void Function(double progress) onProgress) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception('Download fallito (HTTP ${response.statusCode})');
    }

    final total = response.contentLength ?? 0;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/stashly-update.apk');
    final sink = file.openWrite();

    var received = 0;
    await response.stream.listen((chunk) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress(received / total);
    }).asFuture<void>();
    await sink.close();

    return file;
  }

  /// Avvia l'installer di sistema per il file scaricato. La prima volta
  /// Android potrebbe mostrare un pannello per autorizzare l'installazione
  /// di app da questa fonte (una schermata di sistema, non un browser).
  Future<void> install(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      await ErrorLogService.instance.log(
        'Errore avvio installer aggiornamento: ${result.type} - ${result.message}',
      );
      throw Exception(result.message);
    }
  }
}
