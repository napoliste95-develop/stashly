import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/error_log_service.dart';

class ErrorLogScreen extends StatelessWidget {
  const ErrorLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log errori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Svuota log',
            onPressed: () => ErrorLogService.instance.clear(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: ErrorLogService.instance,
        builder: (context, _) {
          final errors = ErrorLogService.instance.errors;
          if (errors.isEmpty) {
            return const Center(child: Text('Nessun errore registrato.'));
          }
          return ListView.builder(
            itemCount: errors.length,
            itemBuilder: (context, index) {
              final e = errors[index];
              return ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(e.message),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(e.timestamp)),
              );
            },
          );
        },
      ),
    );
  }
}
