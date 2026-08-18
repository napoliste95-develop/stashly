import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/saved_item.dart';
import 'firestore_service.dart';

const kDeadLinkCheckTask = 'dead_link_check_task';

/// Numero massimo di item controllati in un singolo giro automatico
/// periodico (a rotazione, partendo dai meno recentemente controllati), per
/// restare dentro i tempi che Android concede ai job periodici in background.
/// "Verifica tutti i link ora" (manuale, in foreground) non ha questo limite.
const _kAutoCheckBatchSize = 150;

const _kCheckConcurrency = 5;
const _kCheckTimeout = Duration(seconds: 8);

class BatchCheckResult {
  final int totalChecked;
  final List<SavedItem> newlyDead;

  const BatchCheckResult({required this.totalChecked, required this.newlyDead});
}

/// Controlla se i link salvati sono ancora raggiungibili, in base al solo
/// status HTTP della risposta: un segnale "best effort", non una garanzia
/// (molte piattaforme rispondono comunque 200 anche per contenuti rimossi).
class LinkCheckService extends ChangeNotifier {
  static final LinkCheckService instance = LinkCheckService._();
  LinkCheckService._();

  static const _enabledKey = 'link_check_enabled';

  final _firestoreService = FirestoreService();

  bool _enabled = false;

  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    notifyListeners();
    if (_enabled) {
      await _scheduleTask();
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (value) {
      await _scheduleTask();
    } else {
      await Workmanager().cancelByUniqueName(kDeadLinkCheckTask);
    }
  }

  Future<void> _scheduleTask() async {
    await Workmanager().cancelByUniqueName(kDeadLinkCheckTask);
    await Workmanager().registerPeriodicTask(
      kDeadLinkCheckTask,
      kDeadLinkCheckTask,
      frequency: const Duration(days: 7),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Controlla un singolo URL e restituisce il suo stato. Non lancia mai
  /// eccezioni: un errore di rete/timeout produce [LinkStatus.unverifiable],
  /// mai [LinkStatus.dead], per evitare falsi positivi.
  Future<LinkStatus> checkLinkStatus(String url, {Duration timeout = _kCheckTimeout}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return LinkStatus.unverifiable;
    http.Response response;
    try {
      response = await http.head(uri).timeout(timeout);
      if (response.statusCode == 405) {
        response = await http.get(uri).timeout(timeout);
      }
    } catch (_) {
      try {
        response = await http.get(uri).timeout(timeout);
      } catch (_) {
        return LinkStatus.unverifiable;
      }
    }
    return _statusFromCode(response.statusCode);
  }

  LinkStatus _statusFromCode(int code) {
    if (code == 404 || code == 410) return LinkStatus.dead;
    if (code >= 200 && code < 400) return LinkStatus.alive;
    return LinkStatus.unverifiable;
  }

  /// Controlla una lista di item con concorrenza limitata, persiste gli
  /// esiti in blocco e restituisce quali sono passati a "morto" in questo
  /// giro rispetto allo stato precedente (unica fonte di verità per decidere
  /// se notificare, nessuna cache separata necessaria).
  Future<BatchCheckResult> checkItems(List<SavedItem> items) async {
    final statusByItemId = <String, LinkStatus>{};
    final newlyDead = <SavedItem>[];

    for (var i = 0; i < items.length; i += _kCheckConcurrency) {
      final chunk = items.skip(i).take(_kCheckConcurrency);
      final results = await Future.wait(
        chunk.map((item) async => MapEntry(item, await checkLinkStatus(item.url))),
      );
      for (final entry in results) {
        final item = entry.key;
        final newStatus = entry.value;
        statusByItemId[item.id] = newStatus;
        if (item.linkStatus != LinkStatus.dead && newStatus == LinkStatus.dead) {
          newlyDead.add(item);
        }
      }
    }

    if (statusByItemId.isNotEmpty) {
      await _firestoreService.updateLinkStatuses(statusByItemId, DateTime.now());
    }
    return BatchCheckResult(totalChecked: items.length, newlyDead: newlyDead);
  }

  /// Controllo manuale di un singolo item, con persistenza immediata.
  Future<LinkStatus> checkSingleItemAndPersist(SavedItem item) async {
    final status = await checkLinkStatus(item.url);
    await _firestoreService.updateSingleLinkStatus(item.id, status, DateTime.now());
    return status;
  }

  /// "Verifica tutti i link ora": versione foreground, senza il limite di
  /// [_kAutoCheckBatchSize] usato dal giro automatico periodico.
  Future<BatchCheckResult> checkAllNow() async {
    final items = await _firestoreService.getAllItemsOnce();
    return checkItems(items);
  }

  /// Eseguito dal job periodico in background: seleziona i item meno
  /// recentemente controllati (o mai controllati) fino al tetto di
  /// [_kAutoCheckBatchSize], per restare dentro i tempi concessi da Android.
  Future<BatchCheckResult> runBackgroundCheck() async {
    final items = await _firestoreService.getAllItemsOnce();
    items.sort((a, b) {
      final aTime = a.lastCheckedAt;
      final bTime = b.lastCheckedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return -1;
      if (bTime == null) return 1;
      return aTime.compareTo(bTime);
    });
    final batch = items.take(_kAutoCheckBatchSize).toList();
    return checkItems(batch);
  }
}
