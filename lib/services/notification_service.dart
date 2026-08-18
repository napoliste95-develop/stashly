import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import '../models/saved_item.dart';
import 'firestore_service.dart';
import 'link_check_service.dart';

const kUnseenReminderTask = 'unseen_reminder_task';

const List<String> _weekdayLabels = [
  'Lunedì',
  'Martedì',
  'Mercoledì',
  'Giovedì',
  'Venerdì',
  'Sabato',
  'Domenica',
];

/// Etichetta italiana per un giorno della settimana (1 = lunedì, 7 = domenica,
/// come [DateTime.weekday]).
String weekdayLabel(int weekday) => _weekdayLabels[weekday - 1];

/// Calcola quanto manca alla prossima occorrenza di [targetWeekday]/[targetTime]
/// a partire da [now]. Se [now] coincide esattamente con l'orario target,
/// restituisce il ritardo per la settimana successiva (evita un doppio invio).
Duration computeInitialDelay({
  required DateTime now,
  required int targetWeekday,
  required TimeOfDay targetTime,
}) {
  var target = DateTime(now.year, now.month, now.day, targetTime.hour, targetTime.minute);
  final diffDays = (targetWeekday - now.weekday) % 7;
  target = target.add(Duration(days: diffDays));
  if (!target.isAfter(now)) {
    target = target.add(const Duration(days: 7));
  }
  return target.difference(now);
}

/// Punto di ingresso eseguito da Android in un isolate separato quando il
/// task periodico di promemoria scatta. Deve restare una funzione top-level.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (FirebaseAuth.instance.currentUser == null) return true;
      if (task == kDeadLinkCheckTask) {
        final result = await LinkCheckService.instance.runBackgroundCheck();
        if (result.newlyDead.isNotEmpty) {
          await _showDeadLinksNotification(result.newlyDead);
        }
      } else {
        final count = await FirestoreService().countUnseenItems();
        if (count > 0) {
          await _showUnseenNotification(count);
        }
      }
    } catch (_) {
      // Best-effort: un fallimento qui non deve far ripetere il task
      // all'infinito né bloccare il resto dell'app.
    }
    return true;
  });
}

Future<void> _showUnseenNotification(int count) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('ic_stat_notify');
  await plugin.initialize(settings: const InitializationSettings(android: androidInit));
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'unseen_reminder_channel',
      'Promemoria salvati',
      channelDescription: 'Promemoria settimanale dei salvati non ancora visti',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );
  final body = count == 1 ? 'Hai 1 salvato non ancora visto' : 'Hai $count salvati non ancora visti';
  await plugin.show(
    id: 0,
    title: 'Stashly',
    body: body,
    notificationDetails: details,
  );
}

Future<void> _showDeadLinksNotification(List<SavedItem> newlyDead) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('ic_stat_notify');
  await plugin.initialize(settings: const InitializationSettings(android: androidInit));
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'dead_link_channel',
      'Controllo link',
      channelDescription: 'Avviso quando alcuni link salvati non sembrano più raggiungibili',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );
  final count = newlyDead.length;
  final body = count == 1
      ? '1 salvato potrebbe non essere più disponibile'
      : '$count salvati potrebbero non essere più disponibili';
  await plugin.show(
    id: 1,
    title: 'Stashly',
    body: body,
    notificationDetails: details,
  );
}

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const _enabledKey = 'reminder_enabled';
  static const _weekdayKey = 'reminder_weekday';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';
  static const _permissionAskedKey = 'reminder_permission_asked';

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _enabled = true;
  int _weekday = DateTime.sunday;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  bool _permissionAsked = false;

  bool get enabled => _enabled;
  int get weekday => _weekday;
  TimeOfDay get time => _time;
  bool get permissionAlreadyAsked => _permissionAsked;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    _weekday = prefs.getInt(_weekdayKey) ?? DateTime.sunday;
    _time = TimeOfDay(
      hour: prefs.getInt(_hourKey) ?? 18,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
    _permissionAsked = prefs.getBool(_permissionAskedKey) ?? false;
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
      await Workmanager().cancelByUniqueName(kUnseenReminderTask);
    }
  }

  Future<void> setSchedule({required int weekday, required TimeOfDay time}) async {
    _weekday = weekday;
    _time = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weekdayKey, weekday);
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);
    if (_enabled) {
      await _scheduleTask();
    }
  }

  Future<void> _scheduleTask() async {
    await Workmanager().cancelByUniqueName(kUnseenReminderTask);
    final delay = computeInitialDelay(now: DateTime.now(), targetWeekday: _weekday, targetTime: _time);
    await Workmanager().registerPeriodicTask(
      kUnseenReminderTask,
      kUnseenReminderTask,
      frequency: const Duration(days: 7),
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Stato reale del permesso di sistema (non la sola preferenza salvata
  /// in-app), da controllare ogni volta che si apre la schermata Impostazioni.
  Future<bool> hasOsPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final result = await android?.areNotificationsEnabled();
    return result ?? false;
  }

  Future<bool> requestPermissionIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    _permissionAsked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionAskedKey, true);
    return granted ?? false;
  }

  Future<void> openSystemSettings() => openAppSettings();
}
