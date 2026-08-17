import 'package:cloud_firestore/cloud_firestore.dart';

enum SocialPlatform {
  instagram,
  tiktok,
  pinterest,
  youtube,
  x,
  facebook,
  reddit,
  threads,
  twitch,
  other,
}

SocialPlatform platformFromUrl(String url) {
  final u = url.toLowerCase();
  if (u.contains('instagram.com')) return SocialPlatform.instagram;
  if (u.contains('tiktok.com')) return SocialPlatform.tiktok;
  if (u.contains('pinterest.') || u.contains('pin.it')) {
    return SocialPlatform.pinterest;
  }
  if (u.contains('youtube.com') || u.contains('youtu.be')) {
    return SocialPlatform.youtube;
  }
  if (u.contains('twitter.com') || u.contains('x.com')) {
    return SocialPlatform.x;
  }
  if (u.contains('facebook.com') || u.contains('fb.watch')) {
    return SocialPlatform.facebook;
  }
  if (u.contains('reddit.com')) return SocialPlatform.reddit;
  if (u.contains('threads.net') || u.contains('threads.com')) {
    return SocialPlatform.threads;
  }
  if (u.contains('twitch.tv')) return SocialPlatform.twitch;
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
    case SocialPlatform.youtube:
      return 'YouTube';
    case SocialPlatform.x:
      return 'X';
    case SocialPlatform.facebook:
      return 'Facebook';
    case SocialPlatform.reddit:
      return 'Reddit';
    case SocialPlatform.threads:
      return 'Threads';
    case SocialPlatform.twitch:
      return 'Twitch';
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
  final DateTime? seenAt;

  SavedItem({
    required this.id,
    required this.url,
    required this.platform,
    required this.title,
    required this.categoryIds,
    required this.note,
    required this.createdAt,
    this.seenAt,
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
      seenAt: (data['seenAt'] as Timestamp?)?.toDate(),
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
      'seenAt': seenAt == null ? null : Timestamp.fromDate(seenAt!),
    };
  }
}
