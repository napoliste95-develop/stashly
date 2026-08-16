import 'package:flutter_test/flutter_test.dart';
import 'package:stashly/models/saved_item.dart';

void main() {
  test('platformFromUrl riconosce le piattaforme dal link', () {
    expect(
      platformFromUrl('https://www.instagram.com/reel/abc'),
      SocialPlatform.instagram,
    );
    expect(
      platformFromUrl('https://www.tiktok.com/@user/video/123'),
      SocialPlatform.tiktok,
    );
    expect(
      platformFromUrl('https://pin.it/abc123'),
      SocialPlatform.pinterest,
    );
    expect(
      platformFromUrl('https://www.youtube.com/watch?v=abc'),
      SocialPlatform.youtube,
    );
    expect(
      platformFromUrl('https://youtu.be/abc'),
      SocialPlatform.youtube,
    );
    expect(
      platformFromUrl('https://x.com/user/status/123'),
      SocialPlatform.x,
    );
    expect(
      platformFromUrl('https://twitter.com/user/status/123'),
      SocialPlatform.x,
    );
    expect(
      platformFromUrl('https://www.facebook.com/user/posts/123'),
      SocialPlatform.facebook,
    );
    expect(
      platformFromUrl('https://www.reddit.com/r/flutter/comments/abc'),
      SocialPlatform.reddit,
    );
    expect(
      platformFromUrl('https://www.threads.net/@user/post/abc'),
      SocialPlatform.threads,
    );
    expect(
      platformFromUrl('https://www.twitch.tv/user/clip/abc'),
      SocialPlatform.twitch,
    );
    expect(
      platformFromUrl('https://example.com/foo'),
      SocialPlatform.other,
    );
  });
}
