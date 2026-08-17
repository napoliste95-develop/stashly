import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/saved_item.dart';
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

  Future<void> _create() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Crea'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    setState(() => _busy = true);
    try {
      await _service.createCategory(name);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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

  Future<bool> _confirmDelete(Category category) async {
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
    return confirmed == true;
  }

  Future<void> _delete(Category category) async {
    setState(() => _busy = true);
    try {
      await _service.deleteCategory(category.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showGestureHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Come modificare o eliminare'),
        content: const Text(
          'Scorri una categoria verso destra per rinominarla, '
          'verso sinistra per eliminarla. Tocca il pallino colorato '
          'per cambiarne il colore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestisci categorie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Come funziona',
            onPressed: _showGestureHelp,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuova categoria',
            onPressed: _create,
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Category>>(
            stream: _service.watchCategories(),
            builder: (context, categorySnapshot) {
              final categories = categorySnapshot.data ?? [];

              if (categories.isEmpty) {
                return const Center(
                  child: Text('Nessuna categoria ancora creata.'),
                );
              }

              return StreamBuilder<List<SavedItem>>(
                stream: _service.watchItems(),
                builder: (context, itemsSnapshot) {
                  final items = itemsSnapshot.data ?? [];

                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final count = items
                          .where((i) => i.categoryIds.contains(category.id))
                          .length;
                      return Dismissible(
                        key: ValueKey(category.id),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_outlined, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Modifica', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Elimina', style: TextStyle(color: Colors.white)),
                              SizedBox(width: 8),
                              Icon(Icons.delete_outline, color: Colors.white),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            await _rename(category);
                            return false;
                          }
                          return _confirmDelete(category);
                        },
                        onDismissed: (_) => _delete(category),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: category.color.withValues(alpha: 0.4),
                          child: ListTile(
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
                            subtitle: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bookmark_outline, size: 14),
                                const SizedBox(width: 4),
                                Text('$count'),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
