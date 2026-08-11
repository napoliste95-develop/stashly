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
      platformFromUrl('https://example.com/foo'),
      SocialPlatform.other,
    );
  });
}
