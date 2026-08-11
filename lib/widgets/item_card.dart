import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/category.dart';
import '../models/saved_item.dart';
import '../services/firestore_service.dart';
import 'item_sheet_helper.dart';

String platformLetter(SocialPlatform platform) {
  switch (platform) {
    case SocialPlatform.instagram:
      return 'I';
    case SocialPlatform.tiktok:
      return 'T';
    case SocialPlatform.pinterest:
      return 'P';
    case SocialPlatform.other:
      return '•';
  }
}

Color platformColor(SocialPlatform platform) {
  switch (platform) {
    case SocialPlatform.instagram:
      return const Color(0xFFC13584);
    case SocialPlatform.tiktok:
      return const Color(0xFF010101);
    case SocialPlatform.pinterest:
      return const Color(0xFFE60023);
    case SocialPlatform.other:
      return Colors.grey;
  }
}

class ItemCard extends StatelessWidget {
  final SavedItem item;
  final Map<String, Category> categoryById;

  const ItemCard({super.key, required this.item, required this.categoryById});

  @override
  Widget build(BuildContext context) {
    final categories = item.categoryIds
        .map((id) => categoryById[id])
        .whereType<Category>()
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: platformColor(item.platform),
          child: Text(
            platformLetter(item.platform),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.title.isNotEmpty ? item.title : item.url,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${platformLabel(item.platform)} · '
              '${DateFormat('dd/MM/yyyy').format(item.createdAt)}',
            ),
            if (categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: categories
                      .map(
                        (c) => Chip(
                          label: Text(
                            c.name,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: c.color.withValues(alpha: 0.2),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
        isThreeLine: categories.isNotEmpty,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              openItemSheet(context, existingItem: item);
            } else if (value == 'delete') {
              FirestoreService().deleteItem(item.id);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Modifica')),
            PopupMenuItem(value: 'delete', child: Text('Elimina')),
          ],
        ),
        onTap: () async {
          final uri = Uri.tryParse(item.url);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}
