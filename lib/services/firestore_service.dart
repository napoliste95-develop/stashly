import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/saved_item.dart';
import 'error_log_service.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _db.collection('users').doc(_uid).collection('items');

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _db.collection('users').doc(_uid).collection('categories');

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
      final id = await getOrCreateCategoryByName(legacyName);
      await doc.reference.update({
        'categoryIds': [id],
        'title': data['title'] ?? data['note'] ?? '',
      });
    } catch (e) {
      await ErrorLogService.instance.log('Errore migrazione elemento: $e');
    }
  }

  Future<void> addItem({
    required String url,
    required SocialPlatform platform,
    required String title,
    required List<String> categoryIds,
    required String note,
  }) async {
    try {
      await _itemsRef.add({
        'url': url,
        'platform': platform.name,
        'title': title.trim(),
        'categoryIds': categoryIds,
        'note': note.trim(),
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      await ErrorLogService.instance.log('Errore salvataggio elemento: $e');
      rethrow;
    }
  }

  Future<void> updateItem(
    String id, {
    required String url,
    required SocialPlatform platform,
    required String title,
    required List<String> categoryIds,
    required String note,
  }) async {
    try {
      await _itemsRef.doc(id).update({
        'url': url,
        'platform': platform.name,
        'title': title.trim(),
        'categoryIds': categoryIds,
        'note': note.trim(),
      });
    } catch (e) {
      await ErrorLogService.instance.log('Errore modifica elemento: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _itemsRef.doc(id).delete();
    } catch (e) {
      await ErrorLogService.instance.log('Errore eliminazione elemento: $e');
      rethrow;
    }
  }

  // ---------------- Categories ----------------

  Stream<List<Category>> watchCategories() {
    return _categoriesRef.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Category.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> createCategory(String name, {Color? color}) async {
    try {
      final chosenColor = color ??
          categoryColorPalette[
              DateTime.now().millisecondsSinceEpoch % categoryColorPalette.length];
      final doc = await _categoriesRef.add({
        'name': name.trim(),
        'color': chosenColor.toARGB32(),
      });
      return doc.id;
    } catch (e) {
      await ErrorLogService.instance.log('Errore creazione categoria: $e');
      rethrow;
    }
  }

  /// Restituisce l'id della categoria con questo nome, creandola se manca.
  Future<String> getOrCreateCategoryByName(String name) async {
    final trimmed = name.trim();
    final existing = await _categoriesRef.where('name', isEqualTo: trimmed).limit(1).get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;
    return createCategory(trimmed);
  }

  Future<void> renameCategory(String id, String newName) async {
    try {
      await _categoriesRef.doc(id).update({'name': newName.trim()});
    } catch (e) {
      await ErrorLogService.instance.log('Errore rinomina categoria: $e');
      rethrow;
    }
  }

  Future<void> updateCategoryColor(String id, Color color) async {
    try {
      await _categoriesRef.doc(id).update({'color': color.toARGB32()});
    } catch (e) {
      await ErrorLogService.instance.log('Errore aggiornamento colore categoria: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final affected = await _itemsRef.where('categoryIds', arrayContains: id).get();
      final batch = _db.batch();
      for (final doc in affected.docs) {
        final ids = (doc.data()['categoryIds'] as List).cast<String>();
        ids.remove(id);
        batch.update(doc.reference, {'categoryIds': ids});
      }
      batch.delete(_categoriesRef.doc(id));
      await batch.commit();
    } catch (e) {
      await ErrorLogService.instance.log('Errore eliminazione categoria: $e');
      rethrow;
    }
  }
}
