import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aspetto')),
      body: AnimatedBuilder(
        animation: ThemeService.instance,
        builder: (context, _) {
          return RadioGroup<ThemeMode>(
            groupValue: ThemeService.instance.mode,
            onChanged: (m) => ThemeService.instance.setMode(m!),
            child: ListView(
              children: const [
                RadioListTile<ThemeMode>(
                  title: Text('Segui sistema'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Chiaro'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Scuro'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
