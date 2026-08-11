import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: AnimatedBuilder(
        animation: ThemeService.instance,
        builder: (context, _) {
          return RadioGroup<ThemeMode>(
            groupValue: ThemeService.instance.mode,
            onChanged: (m) => ThemeService.instance.setMode(m!),
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Tema', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const RadioListTile<ThemeMode>(
                  title: Text('Segui sistema'),
                  value: ThemeMode.system,
                ),
                const RadioListTile<ThemeMode>(
                  title: Text('Chiaro'),
                  value: ThemeMode.light,
                ),
                const RadioListTile<ThemeMode>(
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
