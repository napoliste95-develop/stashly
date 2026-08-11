import 'package:flutter/material.dart';

import '../models/saved_item.dart';
import '../services/firestore_service.dart';
import 'add_item_sheet.dart';

Future<void> openItemSheet(
  BuildContext context, {
  String? prefilledUrl,
  SavedItem? existingItem,
}) async {
  final categories = await FirestoreService().watchCategories().first;
  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AddItemSheet(
      prefilledUrl: prefilledUrl,
      existingItem: existingItem,
      existingCategories: categories,
    ),
  );
}
