import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/saved_item.dart';

const _migratedSeenAtPrefsKey = 'migrated_seen_at_v1';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _db.collection('users').doc(_uid).collection('items');

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _db.collection('users').doc(_uid).collection('categories');

  // ---------------- Feedback ----------------

  Future<void> submitFeedback({
    required String type,
    required String message,
  }) async {
    await _db.collection('feedback').add({
      'type': type,
      'message': message.trim(),
      'userId': _uid,
      'createdAt': Timestamp.now(),
    });
  }

  // ---------------- Items ----------------

  Stream<List<SavedItem>> watchItems() {
    return _itemsRef.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) {
        for (final doc in snapshot.docs) {
          _migrateLegacyItemIfNeeded(doc);
        }
        return snapshot.docs
            .map((doc) => SavedItem.fromFirestore(doc.id, doc.data()))
            .toList();
      },
    );
  }

  /// I primi item creati avevano un campo 'category' (testo singolo) invece
  /// di 'categoryIds' (lista di id). Li converte automaticamente al volo,
  /// creando la categoria corrispondente se non esiste già.
  Future<void> _migrateLegacyItemIfNeeded(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    if (data.containsKey('categoryIds')) return;
    final legacyName = data['category'] as String?;
    if (legacyName == null || legacyName.isEmpty) {
      await doc.reference.update({'categoryIds': <String>[], 'title': data['note'] ?? ''});
      return;
    }
    try {
      final category = await getOrCreateCategoryByName(legacyName);
      await doc.reference.update({
        'categoryIds': [category.id],
        'title': data['title'] ?? data['note'] ?? '',
      });
    } catch (e) {
      // Best-effort: se fallisce, l'item resta nel formato legacy e verrà
      // ritentato al prossimo caricamento della lista.
    }
  }

  Future<void> addItem({
    required String url,
    required SocialPlatform platform,
    required String title,
    required List<String> categoryIds,
    required String note,
  }) async {
    await _itemsRef.add({
      'url': url,
      'platform': platform.name,
      'title': title.trim(),
      'categoryIds': categoryIds,
      'note': note.trim(),
      'createdAt': Timestamp.now(),
      'seenAt': null,
    });
  }

  /// Segna un salvato come visto (aperto dall'utente). Best-effort: non
  /// deve mai bloccare l'apertura del link se fallisce.
  Future<void> markItemSeen(String id) async {
    try {
      await _itemsRef.doc(id).update({'seenAt': Timestamp.now()});
    } catch (e) {
      // ignorato volutamente, vedi commento sopra.
    }
  }

  /// Conta i salvati mai aperti (campo 'seenAt' nullo), con una query di
  /// aggregazione lato server (un solo round-trip, nessun documento scaricato).
  Future<int> countUnseenItems() async {
    final aggregate = await _itemsRef.where('seenAt', isEqualTo: null).count().get();
    return aggregate.count ?? 0;
  }

  /// Marca come "già visti" tutti i salvati creati prima dell'introduzione
  /// del tracking 'seenAt', così il primo promemoria settimanale non conta
  /// mesi di arretrato mai aperto. Va eseguita una sola volta per utente:
  /// il flag di completamento è persistito in locale (SharedPreferences).
  Future<void> migrateMarkExistingItemsAsSeenIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedSeenAtPrefsKey) == true) return;
    try {
      final snapshot = await _itemsRef.get();
      final now = Timestamp.now();
      final toMigrate = snapshot.docs.where((doc) => !doc.data().containsKey('seenAt')).toList();
      for (var i = 0; i < toMigrate.length; i += 500) {
        final chunk = toMigrate.skip(i).take(500);
        final batch = _db.batch();
        for (final doc in chunk) {
          batch.update(doc.reference, {'seenAt': now});
        }
        await batch.commit();
      }
    } catch (e) {
      return;
    }
    await prefs.setBool(_migratedSeenAtPrefsKey, true);
  }

  Future<void> updateItem(
    String id, {
    required String url,
    required SocialPlatform platform,
    required String title,
    required List<String> categoryIds,
    required String note,
  }) async {
    await _itemsRef.doc(id).update({
      'url': url,
      'platform': platform.name,
      'title': title.trim(),
      'categoryIds': categoryIds,
      'note': note.trim(),
    });
  }

  Future<void> deleteItem(String id) async {
    await _itemsRef.doc(id).delete();
  }

  // ---------------- Categories ----------------

  Stream<List<Category>> watchCategories() {
    return _categoriesRef.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Category.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<Category> createCategory(String name) async {
    final trimmed = name.trim();
    final chosenColor = await _pickUnusedColor();
    final doc = await _categoriesRef.add({
      'name': trimmed,
      'color': chosenColor.toARGB32(),
    });
    return Category(id: doc.id, name: trimmed, color: chosenColor);
  }

  /// Sceglie un colore della tavolozza non ancora usato da nessuna
  /// categoria esistente. Se sono tutti occupati, ne riusa uno (le
  /// categorie in eccesso condivideranno un colore, ma è un caso raro).
  Future<Color> _pickUnusedColor() async {
    final existing = await _categoriesRef.get();
    final usedColors = existing.docs.map((d) => d.data()['color'] as int).toSet();
    return categoryColorPalette.firstWhere(
      (c) => !usedColors.contains(c.toARGB32()),
      orElse: () => categoryColorPalette[existing.docs.length % categoryColorPalette.length],
    );
  }

  /// Restituisce la categoria con questo nome, creandola se manca.
  Future<Category> getOrCreateCategoryByName(String name) async {
    final trimmed = name.trim();
    final existing = await _categoriesRef.where('name', isEqualTo: trimmed).limit(1).get();
    if (existing.docs.isNotEmpty) {
      return Category.fromFirestore(existing.docs.first.id, existing.docs.first.data());
    }
    return createCategory(trimmed);
  }

  Future<void> renameCategory(String id, String newName) async {
    await _categoriesRef.doc(id).update({'name': newName.trim()});
  }

  Future<void> updateCategoryColor(String id, Color color) async {
    await _categoriesRef.doc(id).update({'color': color.toARGB32()});
  }

  Future<void> deleteCategory(String id) async {
    final affected = await _itemsRef.where('categoryIds', arrayContains: id).get();
    final batch = _db.batch();
    for (final doc in affected.docs) {
      final ids = (doc.data()['categoryIds'] as List).cast<String>();
      ids.remove(id);
      batch.update(doc.reference, {'categoryIds': ids});
    }
    batch.delete(_categoriesRef.doc(id));
    await batch.commit();
  }
}
