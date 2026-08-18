import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/saved_item.dart';
import 'firestore_service.dart';

/// Esporta/importa l'intera libreria di salvati e categorie dell'utente in
/// JSON, per permettere un ripristino manuale (es. dopo disinstallazione).
class BackupService {
  final _firestoreService = FirestoreService();

  Future<String> buildExportJson() async {
    final categories = await _firestoreService.getAllCategoriesOnce();
    final items = await _firestoreService.getAllItemsOnce();
    final info = await PackageInfo.fromPlatform();

    final map = {
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': info.version,
      'categories': categories
          .map((c) => {'id': c.id, ...c.toJson()})
          .toList(),
      'items': items.map((i) => {'id': i.id, ...i.toJson()}).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Genera il JSON e lo scrive in un file nella directory temporanea,
  /// pronto per essere condiviso tramite il foglio di condivisione di sistema.
  Future<File> exportToFile() async {
    final json = await buildExportJson();
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final file = File('${dir.path}/stashly-backup-$stamp.json');
    return file.writeAsString(json);
  }

  /// Importa categorie e salvati da un JSON prodotto da [buildExportJson].
  /// Le categorie vengono rimappate per nome (nuovi id locali, dato che dopo
  /// una reinstallazione l'utente ha un nuovo account/uid). L'import procede
  /// sempre in modalità "unione": non controlla né blocca in presenza di
  /// una libreria non vuota. Ritorna il numero di elementi importati.
  Future<int> importFromJson(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map ||
        decoded['categories'] is! List ||
        decoded['items'] is! List) {
      throw const FormatException('File non valido: struttura JSON inattesa.');
    }

    final oldToNewCategoryId = <String, String>{};
    for (final raw in decoded['categories'] as List) {
      if (raw is! Map) continue;
      final json = raw.cast<String, dynamic>();
      final oldId = json['id'] as String?;
      final name = (json['name'] as String? ?? '').trim();
      if (oldId == null || name.isEmpty) continue;
      final category = await _firestoreService.getOrCreateCategoryByName(name);
      oldToNewCategoryId[oldId] = category.id;
    }

    final itemsToRestore = <SavedItem>[];
    for (final raw in decoded['items'] as List) {
      if (raw is! Map) continue;
      final json = raw.cast<String, dynamic>();
      final oldItem = SavedItem.fromJson('', json);
      final remappedCategoryIds = oldItem.categoryIds
          .map((id) => oldToNewCategoryId[id])
          .whereType<String>()
          .toList();
      itemsToRestore.add(
        SavedItem(
          id: '',
          url: oldItem.url,
          platform: oldItem.platform,
          title: oldItem.title,
          categoryIds: remappedCategoryIds,
          note: oldItem.note,
          createdAt: oldItem.createdAt,
          seenAt: oldItem.seenAt,
          linkStatus: oldItem.linkStatus,
          lastCheckedAt: oldItem.lastCheckedAt,
        ),
      );
    }

    await _firestoreService.restoreItems(itemsToRestore);
    return itemsToRestore.length;
  }
}
