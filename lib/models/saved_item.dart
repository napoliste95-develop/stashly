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

/// Esito dell'ultimo controllo di raggiungibilità del link, basato solo sullo
/// status HTTP: è un segnale "best effort", non una garanzia (molte
/// piattaforme rispondono comunque 200 anche per contenuti rimossi).
enum LinkStatus { unknown, alive, dead, unverifiable }

class SavedItem {
  final String id;
  final String url;
  final SocialPlatform platform;
  final String title;
  final List<String> categoryIds;
  final String note;
  final DateTime createdAt;
  final DateTime? seenAt;
  final LinkStatus linkStatus;
  final DateTime? lastCheckedAt;

  SavedItem({
    required this.id,
    required this.url,
    required this.platform,
    required this.title,
    required this.categoryIds,
    required this.note,
    required this.createdAt,
    this.seenAt,
    this.linkStatus = LinkStatus.unknown,
    this.lastCheckedAt,
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
      linkStatus: LinkStatus.values.firstWhere(
        (s) => s.name == (data['linkStatus'] as String? ?? 'unknown'),
        orElse: () => LinkStatus.unknown,
      ),
      lastCheckedAt: (data['lastCheckedAt'] as Timestamp?)?.toDate(),
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
      'linkStatus': linkStatus.name,
      'lastCheckedAt': lastCheckedAt == null ? null : Timestamp.fromDate(lastCheckedAt!),
    };
  }

  factory SavedItem.fromJson(String id, Map<String, dynamic> json) {
    return SavedItem(
      id: id,
      url: json['url'] as String? ?? '',
      platform: SocialPlatform.values.firstWhere(
        (p) => p.name == (json['platform'] as String? ?? 'other'),
        orElse: () => SocialPlatform.other,
      ),
      title: json['title'] as String? ?? '',
      categoryIds: (json['categoryIds'] as List?)?.cast<String>() ?? [],
      note: json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      seenAt: json['seenAt'] == null ? null : DateTime.tryParse(json['seenAt'] as String),
      linkStatus: LinkStatus.values.firstWhere(
        (s) => s.name == (json['linkStatus'] as String? ?? 'unknown'),
        orElse: () => LinkStatus.unknown,
      ),
      lastCheckedAt: json['lastCheckedAt'] == null
          ? null
          : DateTime.tryParse(json['lastCheckedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'platform': platform.name,
      'title': title,
      'categoryIds': categoryIds,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'seenAt': seenAt?.toIso8601String(),
      'linkStatus': linkStatus.name,
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
    };
  }
}
