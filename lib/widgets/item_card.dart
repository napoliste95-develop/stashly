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
