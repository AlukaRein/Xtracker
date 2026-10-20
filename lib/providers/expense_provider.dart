import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/category_alert.dart';
import '../services/firestore_sync_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<String> _customCategories = [];
  Map<String, double> _categoryLimits = {};
  bool _isNotificationEnabled = true;
  final _uuid = const Uuid();

  String? _currentUserId;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;

  static const _expensesKey = 'expenses';
  static const _categoriesKey = 'custom_categories';
  static const _limitsKey = 'category_budget_limits';
  static const _notificationKey = 'notification_alerts_enabled';

  final List<String> defaultCategories = [
    'Makan',
    'Transport',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Tagihan',
    'Pendidikan',
    'Bensin',
    'Game',
    'Lainnya',
  ];

  List<String> get allCategories => [
        ...defaultCategories,
        ..._customCategories.where((c) => !defaultCategories.contains(c)),
      ];

  bool get isNotificationEnabled => _isNotificationEnabled;
  Map<String, double> get categoryLimits => Map.unmodifiable(_categoryLimits);
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get currentUserId => _currentUserId;

  double getCategoryLimit(String category) {
    return _categoryLimits[category] ?? 0.0;
  }

  void updateUser(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (_currentUserId != null) {
        syncWithCloud();
      }
    }
  }

  Future<bool> syncWithCloud() async {
    if (_currentUserId == null || !FirestoreSyncService.isFirebaseReady) {
      return false;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final cloudExpenses =
          await FirestoreSyncService.fetchExpenses(_currentUserId!);
      final cloudConfig =
          await FirestoreSyncService.fetchConfig(_currentUserId!);

      if (cloudExpenses != null && cloudExpenses.isNotEmpty) {
        // Gabungkan cloud expenses dengan expenses lokal
        final Map<String, Expense> map = {for (var e in _expenses) e.id: e};
        for (final ce in cloudExpenses) {
          map[ce.id] = ce;
        }
        _expenses = map.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        // Jika ada transaksi lokal yang belum ada di cloud, simpan ke cloud
        for (final local in _expenses) {
          if (!cloudExpenses.any((ce) => ce.id == local.id)) {
            await FirestoreSyncService.saveExpense(_currentUserId!, local);
          }
        }
      } else if (_expenses.isNotEmpty) {
        // Cloud masih kosong, upload seluruh data lokal saat ini ke cloud
        await FirestoreSyncService.batchUpload(
          _currentUserId!,
          expenses: _expenses,
          customCategories: _customCategories,
          categoryLimits: _categoryLimits,
          isNotificationEnabled: _isNotificationEnabled,
        );
      }

      if (cloudConfig != null) {
        if (cloudConfig['customCategories'] is List) {
          final loadedCats = List<String>.from(cloudConfig['customCategories']);
          for (final cat in loadedCats) {
            if (!_customCategories.contains(cat)) {
              _customCategories.add(cat);
            }
          }
        }
        if (cloudConfig['categoryLimits'] is Map) {
          final loadedLimits =
              Map<String, dynamic>.from(cloudConfig['categoryLimits']);
          for (final entry in loadedLimits.entries) {
            _categoryLimits[entry.key] = (entry.value as num).toDouble();
          }
        }
        if (cloudConfig['isNotificationEnabled'] is bool) {
          _isNotificationEnabled = cloudConfig['isNotificationEnabled'] as bool;
        }
      }

      _lastSyncedAt = DateTime.now();
      await _saveData();
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sync with cloud error: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    _isNotificationEnabled = enabled;
    await _saveData();
    if (_currentUserId != null) {
      FirestoreSyncService.saveConfig(
        _currentUserId!,
        customCategories: _customCategories,
        categoryLimits: _categoryLimits,
        isNotificationEnabled: _isNotificationEnabled,
      );
    }
    notifyListeners();
  }

  Future<void> setCategoryLimit(String category, double limit) async {
    if (limit <= 0) {
      _categoryLimits.remove(category);
    } else {
      _categoryLimits[category] = limit;
    }
    await _saveData();
    if (_currentUserId != null) {
      FirestoreSyncService.saveConfig(
        _currentUserId!,
        customCategories: _customCategories,
        categoryLimits: _categoryLimits,
        isNotificationEnabled: _isNotificationEnabled,
      );
    }
    notifyListeners();
  }

  Future<void> removeCategoryLimit(String category) async {
    _categoryLimits.remove(category);
    await _saveData();
    if (_currentUserId != null) {
      FirestoreSyncService.saveConfig(
        _currentUserId!,
        customCategories: _customCategories,
        categoryLimits: _categoryLimits,
        isNotificationEnabled: _isNotificationEnabled,
      );
    }
    notifyListeners();
  }

  List<Expense> getExpensesForMonth(int year, int month) {
    return _expenses
        .where((e) => e.date.year == year && e.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalForMonth(int year, int month) {
    return getExpensesForMonth(year, month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getCategoryTotalsForMonth(int year, int month) {
    final result = <String, double>{};
    for (final e in getExpensesForMonth(year, month)) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    final sorted = Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  List<CategoryAlert> getSpendingAlerts(int year, int month) {
    if (!_isNotificationEnabled) return [];

    final categoryTotals = getCategoryTotalsForMonth(year, month);
    final totalMonth = getTotalForMonth(year, month);
    final alerts = <CategoryAlert>[];

    for (final entry in categoryTotals.entries) {
      final category = entry.key;
      final spent = entry.value;
      final limit = _categoryLimits[category] ?? 0.0;

      if (limit > 0) {
        if (spent >= limit) {
          alerts.add(
            CategoryAlert(
              category: category,
              currentSpent: spent,
              limit: limit,
              severity: AlertSeverity.exceeded,
              message:
                  'Pengeluaran $category telah melebihi batas anggaran yang ditentukan!',
            ),
          );
        } else if (spent >= limit * 0.8) {
          alerts.add(
            CategoryAlert(
              category: category,
              currentSpent: spent,
              limit: limit,
              severity: AlertSeverity.warning,
              message:
                  'Pengeluaran $category sudah mencapai ${(spent / limit * 100).toInt()}% dari batas anggaran.',
            ),
          );
        }
      } else if (totalMonth > 0 && (spent / totalMonth) >= 0.5 && spent >= 250000) {
        // High spending dominance alert when no specific budget limit is set
        alerts.add(
          CategoryAlert(
            category: category,
            currentSpent: spent,
            limit: totalMonth * 0.5,
            severity: AlertSeverity.warning,
            message:
                'Pengeluaran $category mendominasi ${((spent / totalMonth) * 100).toStringAsFixed(0)}% dari seluruh pengeluaran bulan ini!',
          ),
        );
      }
    }

    // Sort: exceeded first, then higher currentSpent
    alerts.sort((a, b) {
      if (a.isExceeded && !b.isExceeded) return -1;
      if (!a.isExceeded && b.isExceeded) return 1;
      return b.currentSpent.compareTo(a.currentSpent);
    });

    return alerts;
  }

  CategoryAlert? checkPotentialAlert({
    required String category,
    required double newAmount,
    required DateTime date,
  }) {
    if (!_isNotificationEnabled || newAmount <= 0) return null;

    final currentExpenses = getExpensesForMonth(date.year, date.month);
    final currentCatSpent = currentExpenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, e) => sum + e.amount);
    final projectedSpent = currentCatSpent + newAmount;
    final limit = _categoryLimits[category] ?? 0.0;

    if (limit > 0) {
      if (projectedSpent >= limit) {
        return CategoryAlert(
          category: category,
          currentSpent: projectedSpent,
          limit: limit,
          severity: AlertSeverity.exceeded,
          message:
              'Transaksi ini akan membuat pengeluaran $category melebihi batas anggaran bulanan!',
        );
      } else if (projectedSpent >= limit * 0.8) {
        return CategoryAlert(
          category: category,
          currentSpent: projectedSpent,
          limit: limit,
          severity: AlertSeverity.warning,
          message:
              'Transaksi ini akan membuat pengeluaran $category mencapai ${(projectedSpent / limit * 100).toInt()}% dari batas anggaran.',
        );
      }
    }

    return null;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final expensesJson = prefs.getStringList(_expensesKey) ?? [];
    _expenses = expensesJson.map((e) => Expense.fromJson(e)).toList();

    _customCategories = prefs.getStringList(_categoriesKey) ?? [];

    final limitsJson = prefs.getString(_limitsKey);
    if (limitsJson != null) {
      try {
        final decoded = jsonDecode(limitsJson) as Map<String, dynamic>;
        _categoryLimits =
            decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {
        _categoryLimits = {};
      }
    }

    _isNotificationEnabled = prefs.getBool(_notificationKey) ?? true;

    notifyListeners();
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required DateTime date,
    String note = '',
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
    _expenses.add(expense);
    _expenses.sort((a, b) => b.date.compareTo(a.date));

    if (!allCategories.contains(category)) {
      _customCategories.add(category);
    }

    await _saveData();
    if (_currentUserId != null) {
      FirestoreSyncService.saveExpense(_currentUserId!, expense);
      FirestoreSyncService.saveConfig(
        _currentUserId!,
        customCategories: _customCategories,
        categoryLimits: _categoryLimits,
        isNotificationEnabled: _isNotificationEnabled,
      );
    }
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _saveData();
    if (_currentUserId != null) {
      FirestoreSyncService.deleteExpense(_currentUserId!, id);
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _expensesKey, _expenses.map((e) => e.toJson()).toList());
    await prefs.setStringList(_categoriesKey, _customCategories);
    await prefs.setString(_limitsKey, jsonEncode(_categoryLimits));
    await prefs.setBool(_notificationKey, _isNotificationEnabled);
  }
}
