import 'package:cloud_firestore/cloud_firestore.dart';

enum SocialPlatform { instagram, tiktok, pinterest, other }

SocialPlatform platformFromUrl(String url) {
  final u = url.toLowerCase();
  if (u.contains('instagram.com')) return SocialPlatform.instagram;
  if (u.contains('tiktok.com')) return SocialPlatform.tiktok;
  if (u.contains('pinterest.') || u.contains('pin.it')) {
    return SocialPlatform.pinterest;
  }
  return SocialPlatform.other;
}

String platformLabel(SocialPlatform platform) {
  switch (platform) {
    case SocialPlatform.instagram:
      return 'Instagram';
    case SocialPlatform.tiktok:
      return 'TikTok';
    case SocialPlatform.pinterest:
      return 'Pinterest';
    case SocialPlatform.other:
      return 'Altro';
  }
}

class SavedItem {
  final String id;
  final String url;
  final SocialPlatform platform;
  final String title;
  final List<String> categoryIds;
  final String note;
  final DateTime createdAt;

  SavedItem({
    required this.id,
    required this.url,
    required this.platform,
    required this.title,
    required this.categoryIds,
    required this.note,
    required this.createdAt,
  });

  factory SavedItem.fromFirestore(String id, Map<String, dynamic> data) {
    return SavedItem(
      id: id,
      url: data['url'] as String? ?? '',
      platform: SocialPlatform.values.firstWhere(
        (p) => p.name == (data['platform'] as String? ?? 'other'),
        orElse: () => SocialPlatform.other,
      ),
      title: data['title'] as String? ?? '',
      categoryIds: (data['categoryIds'] as List?)?.cast<String>() ?? [],
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'platform': platform.name,
      'title': title,
      'categoryIds': categoryIds,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
