import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const String updateManifestUrl =
    'https://stashly-napoli-77201.web.app/version.json';

class UpdateInfo {
  final int versionCode;
  final String version;
  final String apkUrl;
  final String changelog;

  /// Se true, questa release non può essere installata automaticamente
  /// (es. cambio della chiave di firma dell'APK) e il dialog di
  /// aggiornamento deve mostrare istruzioni manuali invece del pulsante
  /// "Scarica e installa".
  final bool requiresManualReinstall;
  final String? manualReinstallMessage;

  UpdateInfo({
    required this.versionCode,
    required this.version,
    required this.apkUrl,
    required this.changelog,
    this.requiresManualReinstall = false,
    this.manualReinstallMessage,
  });
}

class UpdateService {
  /// Restituisce le info sull'aggiornamento se ne è disponibile uno più
  /// recente di quello installato, altrimenti null.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse('$updateManifestUrl?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteVersionCode = data['versionCode'] as int;

      final info = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(info.buildNumber) ?? 0;

      if (remoteVersionCode <= currentVersionCode) return null;

      return UpdateInfo(
        versionCode: remoteVersionCode,
        version: data['version'] as String,
        apkUrl: data['apkUrl'] as String,
        changelog: data['changelog'] as String? ?? '',
        requiresManualReinstall: data['requiresManualReinstall'] as bool? ?? false,
        manualReinstallMessage: data['manualReinstallMessage'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}
