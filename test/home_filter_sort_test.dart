import 'package:flutter_test/flutter_test.dart';
import 'package:stashly/models/saved_item.dart';
import 'package:stashly/screens/home_screen.dart';

SavedItem _item({
  required String id,
  String title = '',
  String note = '',
  String url = 'https://example.com',
  SocialPlatform platform = SocialPlatform.other,
  List<String> categoryIds = const [],
  required DateTime createdAt,
}) {
  return SavedItem(
    id: id,
    url: url,
    platform: platform,
    title: title,
    categoryIds: categoryIds,
    note: note,
    createdAt: createdAt,
  );
}

void main() {
  final items = [
    _item(
      id: '1',
      title: 'Ricetta pasta',
      platform: SocialPlatform.tiktok,
      categoryIds: ['cucina'],
      createdAt: DateTime(2026, 1, 1),
    ),
    _item(
      id: '2',
      title: 'Outfit autunno',
      platform: SocialPlatform.instagram,
      categoryIds: ['moda'],
      createdAt: DateTime(2026, 3, 1),
    ),
    _item(
      id: '3',
      note: 'idea regalo pasta madre',
      platform: SocialPlatform.pinterest,
      categoryIds: ['cucina'],
      createdAt: DateTime(2026, 2, 1),
    ),
  ];

  test('filtra per categoria', () {
    final result = filterAndSortItems(items, categoryId: 'moda');
    expect(result.map((e) => e.id), ['2']);
  });

  test('cerca per testo su titolo, nota e link (case-insensitive)', () {
    final result = filterAndSortItems(items, searchQuery: 'PASTA');
    expect(result.map((e) => e.id).toSet(), {'1', '3'});
  });

  test('ordina per data più recenti', () {
    final result = filterAndSortItems(items, sortOption: SortOption.newest);
    expect(result.map((e) => e.id), ['2', '3', '1']);
  });

  test('ordina per data meno recenti', () {
    final result = filterAndSortItems(items, sortOption: SortOption.oldest);
    expect(result.map((e) => e.id), ['1', '3', '2']);
  });

  test('ordina per nome A-Z (usa url se manca il titolo)', () {
    final result = filterAndSortItems(items, sortOption: SortOption.nameAsc);
    // "https://..." (h) < "Outfit autunno" (o) < "Ricetta pasta" (r)
    expect(result.map((e) => e.id), ['3', '2', '1']);
  });

  test('combina filtro categoria e ricerca testo', () {
    final result = filterAndSortItems(
      items,
      categoryId: 'cucina',
      searchQuery: 'regalo',
    );
    expect(result.map((e) => e.id), ['3']);
  });
}
