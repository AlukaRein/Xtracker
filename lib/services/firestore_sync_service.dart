import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class FirestoreSyncService {
  static bool get isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static FirebaseFirestore? get _db {
    if (!isFirebaseReady) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance error: $e');
      return null;
    }
  }

  /// Mengambil seluruh data pengeluaran dari Cloud Firestore untuk user tertentu.
  static Future<List<Expense>?> fetchExpenses(String userId) async {
    final db = _db;
    if (db == null) return null;

    try {
      final snapshot = await db
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Expense(
          id: data['id'] as String? ?? doc.id,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          category: data['category'] as String? ?? 'Lainnya',
          date: data['date'] != null
              ? DateTime.tryParse(data['date'] as String) ?? DateTime.now()
              : DateTime.now(),
          note: data['note'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching expenses from Firestore: $e');
      return null;
    }
  }

  /// Mengambil data konfigurasi (kategori kustom & batas anggaran) dari Cloud Firestore.
  static Future<Map<String, dynamic>?> fetchConfig(String userId) async {
    final db = _db;
    if (db == null) return null;

    try {
      final doc = await db
          .collection('users')
          .doc(userId)
          .collection('config')
          .doc('budget_settings')
          .get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('Error fetching config from Firestore: $e');
      return null;
    }
  }

  /// Menyimpan satu pengeluaran baru atau pembaruan ke Cloud Firestore.
  static Future<void> saveExpense(String userId, Expense expense) async {
    final db = _db;
    if (db == null) return;

    try {
      await db
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(expense.id)
          .set({
        'id': expense.id,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
        'note': expense.note,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving expense to Firestore: $e');
    }
  }

  /// Menghapus transaksi pengeluaran dari Cloud Firestore.
  static Future<void> deleteExpense(String userId, String expenseId) async {
    final db = _db;
    if (db == null) return;

    try {
      await db
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting expense from Firestore: $e');
    }
  }

  /// Menyimpan konfigurasi batas anggaran dan kategori ke Cloud Firestore.
  static Future<void> saveConfig(
    String userId, {
    required List<String> customCategories,
    required Map<String, double> categoryLimits,
    required bool isNotificationEnabled,
  }) async {
    final db = _db;
    if (db == null) return;

    try {
      await db
          .collection('users')
          .doc(userId)
          .collection('config')
          .doc('budget_settings')
          .set({
        'customCategories': customCategories,
        'categoryLimits': categoryLimits,
        'isNotificationEnabled': isNotificationEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving config to Firestore: $e');
    }
  }

  /// Mengunggah seluruh data lokal ke Cloud Firestore (dipakai saat pertama kali sinkronisasi).
  static Future<void> batchUpload(
    String userId, {
    required List<Expense> expenses,
    required List<String> customCategories,
    required Map<String, double> categoryLimits,
    required bool isNotificationEnabled,
  }) async {
    final db = _db;
    if (db == null) return;

    try {
      final batch = db.batch();

      // Batch expenses
      for (final expense in expenses) {
        final docRef = db
            .collection('users')
            .doc(userId)
            .collection('expenses')
            .doc(expense.id);
        batch.set(docRef, {
          'id': expense.id,
          'amount': expense.amount,
          'category': expense.category,
          'date': expense.date.toIso8601String(),
          'note': expense.note,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Config doc
      final configRef = db
          .collection('users')
          .doc(userId)
          .collection('config')
          .doc('budget_settings');
      batch.set(configRef, {
        'customCategories': customCategories,
        'categoryLimits': categoryLimits,
        'isNotificationEnabled': isNotificationEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error batch uploading to Firestore: $e');
    }
  }
}
