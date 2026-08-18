import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/category.dart';
import '../models/saved_item.dart';
import '../services/firestore_service.dart';
import 'item_sheet_helper.dart';

FaIconData platformIcon(SocialPlatform platform) {
  switch (platform) {
    case SocialPlatform.instagram:
      return FontAwesomeIcons.instagram;
    case SocialPlatform.tiktok:
      return FontAwesomeIcons.tiktok;
    case SocialPlatform.pinterest:
      return FontAwesomeIcons.pinterest;
    case SocialPlatform.youtube:
      return FontAwesomeIcons.youtube;
    case SocialPlatform.x:
      return FontAwesomeIcons.xTwitter;
    case SocialPlatform.facebook:
      return FontAwesomeIcons.facebook;
    case SocialPlatform.reddit:
      return FontAwesomeIcons.reddit;
    case SocialPlatform.threads:
      return FontAwesomeIcons.threads;
    case SocialPlatform.twitch:
      return FontAwesomeIcons.twitch;
    case SocialPlatform.other:
      return FontAwesomeIcons.link;
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
    case SocialPlatform.youtube:
      return const Color(0xFFFF0000);
    case SocialPlatform.x:
      return const Color(0xFF000000);
    case SocialPlatform.facebook:
      return const Color(0xFF1877F2);
    case SocialPlatform.reddit:
      return const Color(0xFFFF4500);
    case SocialPlatform.threads:
      return const Color(0xFF000000);
    case SocialPlatform.twitch:
      return const Color(0xFF9146FF);
    case SocialPlatform.other:
      return Colors.grey;
  }
}

/// Apre il link del salvato e, se non era ancora stato visto, lo marca
/// come visto. Condivisa tra [ItemCard] e [ItemGridTile].
Future<void> openAndMarkSeen(SavedItem item) async {
  final uri = Uri.tryParse(item.url);
  if (uri != null) {
    if (item.seenAt == null) {
      unawaited(FirestoreService().markItemSeen(item.id));
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          child: FaIcon(
            platformIcon(item.platform),
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Row(
          children: [
            if (item.seenAt == null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Expanded(
              child: Text(
                item.title.isNotEmpty ? item.title : item.url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: item.seenAt != null
                    ? TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
          ],
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
        onTap: () => openAndMarkSeen(item),
      ),
    );
  }
}

class ItemGridTile extends StatelessWidget {
  final SavedItem item;
  final Map<String, Category> categoryById;

  const ItemGridTile({super.key, required this.item, required this.categoryById});

  @override
  Widget build(BuildContext context) {
    final categories = item.categoryIds
        .map((id) => categoryById[id])
        .whereType<Category>()
        .toList();

    return Card(
      margin: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openAndMarkSeen(item),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 72,
                  width: double.infinity,
                  color: platformColor(item.platform),
                  child: Center(
                    child: FaIcon(
                      platformIcon(item.platform),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Text(
                    item.title.isNotEmpty ? item.title : item.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: item.seenAt != null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                if (categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...categories.take(2).map(
                              (c) => Chip(
                                label: Text(
                                  c.name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: c.color.withValues(alpha: 0.2),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                        if (categories.length > 2)
                          Chip(
                            label: Text(
                              '+${categories.length - 2}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            if (item.seenAt == null)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
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
            ),
          ],
        ),
      ),
    );
  }
}
