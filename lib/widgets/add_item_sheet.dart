import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/saved_item.dart';
import '../services/firestore_service.dart';

class AddItemSheet extends StatefulWidget {
  final List<Category> existingCategories;
  final String? prefilledUrl;
  final SavedItem? existingItem;

  const AddItemSheet({
    super.key,
    this.existingCategories = const [],
    this.prefilledUrl,
    this.existingItem,
  });

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final _urlController = TextEditingController(
    text: widget.existingItem?.url ?? widget.prefilledUrl ?? '',
  );
  late final _titleController = TextEditingController(
    text: widget.existingItem?.title ?? '',
  );
  late final _noteController = TextEditingController(
    text: widget.existingItem?.note ?? '',
  );
  final _newCategoryController = TextEditingController();
  late final Set<String> _selectedCategoryIds =
      {...(widget.existingItem?.categoryIds ?? const [])};
  bool _saving = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _addNewCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;
    final id = await FirestoreService().getOrCreateCategoryByName(name);
    setState(() {
      _selectedCategoryIds.add(id);
      _newCategoryController.clear();
    });
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await FirestoreService().updateItem(
          widget.existingItem!.id,
          url: url,
          platform: platformFromUrl(url),
          title: _titleController.text,
          categoryIds: _selectedCategoryIds.toList(),
          note: _noteController.text,
        );
      } else {
        await FirestoreService().addItem(
          url: url,
          platform: platformFromUrl(url),
          title: _titleController.text,
          categoryIds: _selectedCategoryIds.toList(),
          note: _noteController.text,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossibile salvare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Modifica salvato' : 'Nuovo salvato',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              autofocus: widget.prefilledUrl == null && !_isEditing,
              decoration: const InputDecoration(
                labelText: 'Link (Instagram, TikTok, Pinterest...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nome (mostrato al posto del link)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota (opzionale)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text('Categorie', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.existingCategories.map((c) {
                final selected = _selectedCategoryIds.contains(c.id);
                return FilterChip(
                  label: Text(c.name),
                  selected: selected,
                  backgroundColor: c.color.withValues(alpha: 0.15),
                  selectedColor: c.color.withValues(alpha: 0.35),
                  avatar: CircleAvatar(backgroundColor: c.color, radius: 6),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedCategoryIds.add(c.id);
                      } else {
                        _selectedCategoryIds.remove(c.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Nuova categoria',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addNewCategory(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addNewCategory,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Salva modifiche' : 'Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
