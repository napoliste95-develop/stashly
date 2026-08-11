import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/firestore_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _service = FirestoreService();
  bool _busy = false;

  Future<void> _rename(Category category) async {
    final controller = TextEditingController(text: category.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rinomina categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == category.name) return;

    setState(() => _busy = true);
    try {
      await _service.renameCategory(category.id, newName);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeColor(Category category, List<Category> allCategories) async {
    final usedByOthers = allCategories
        .where((c) => c.id != category.id)
        .map((c) => c.color.toARGB32())
        .toSet();

    final newColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scegli un colore'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categoryColorPalette.map((color) {
            final selected = color.toARGB32() == category.color.toARGB32();
            final takenByOther = usedByOthers.contains(color.toARGB32());
            return GestureDetector(
              onTap: takenByOther ? null : () => Navigator.pop(context, color),
              child: Opacity(
                opacity: takenByOther ? 0.25 : 1,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                  child: takenByOther
                      ? const Icon(Icons.lock, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (newColor == null) return;

    setState(() => _busy = true);
    try {
      await _service.updateCategoryColor(category.id, newColor);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina categoria'),
        content: Text(
          'I salvati in "${category.name}" non verranno eliminati, '
          'perderanno solo questa categoria. Continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _service.deleteCategory(category.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestisci categorie')),
      body: Stack(
        children: [
          StreamBuilder<List<Category>>(
            stream: _service.watchCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];

              if (categories.isEmpty) {
                return const Center(
                  child: Text('Nessuna categoria ancora creata.'),
                );
              }

              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    leading: GestureDetector(
                      onTap: () => _changeColor(category, categories),
                      child: CircleAvatar(
                        backgroundColor: category.color,
                        child: const Icon(
                          Icons.bookmark,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    title: Text(category.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _rename(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(category),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (_busy)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
