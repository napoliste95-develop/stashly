import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionScreen extends StatelessWidget {
  const VersionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Versione')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final info = snapshot.data!;
          return ListView(
            children: [
              ListTile(
                title: const Text('Nome app'),
                subtitle: Text(info.appName),
              ),
              ListTile(
                title: const Text('Package'),
                subtitle: Text(info.packageName),
              ),
              ListTile(
                title: const Text('Versione'),
                subtitle: Text('${info.version} (build ${info.buildNumber})'),
              ),
            ],
          );
        },
      ),
    );
  }
}
