import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/utils/formatter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Expense Model Tests', () {
    test('Expense toMap and fromMap serialization', () {
      final now = DateTime(2026, 10, 3, 12, 0);
      final expense = Expense(
        id: 'test-id-1',
        amount: 25000.0,
        category: 'Makan',
        date: now,
        note: 'Nasi goreng',
      );

      final map = expense.toMap();
      expect(map['id'], 'test-id-1');
      expect(map['amount'], 25000.0);
      expect(map['category'], 'Makan');
      expect(map['date'], now.toIso8601String());
      expect(map['note'], 'Nasi goreng');

      final fromMap = Expense.fromMap(map);
      expect(fromMap.id, expense.id);
      expect(fromMap.amount, expense.amount);
      expect(fromMap.category, expense.category);
      expect(fromMap.date, expense.date);
      expect(fromMap.note, expense.note);

      final json = expense.toJson();
      final fromJson = Expense.fromJson(json);
      expect(fromJson.id, expense.id);
      expect(fromJson.amount, expense.amount);
    });
  });

  group('ExpenseProvider Tests', () {
    test('Default categories are present', () {
      final provider = ExpenseProvider();
      expect(provider.defaultCategories, contains('Makan'));
      expect(provider.defaultCategories, contains('Transport'));
      expect(provider.allCategories.length, provider.defaultCategories.length);
    });

    test('Add expense updates list and totals', () async {
      final provider = ExpenseProvider();
      await provider.loadData();

      final dateOct = DateTime(2026, 10, 3);
      await provider.addExpense(
        amount: 50000,
        category: 'Makan',
        date: dateOct,
        note: 'Lunch',
      );

      await provider.addExpense(
        amount: 30000,
        category: 'Transport',
        date: dateOct,
        note: 'Taxi',
      );

      final octExpenses = provider.getExpensesForMonth(2026, 10);
      expect(octExpenses.length, 2);
      expect(provider.getTotalForMonth(2026, 10), 80000.0);

      final categoryTotals = provider.getCategoryTotalsForMonth(2026, 10);
      expect(categoryTotals['Makan'], 50000.0);
      expect(categoryTotals['Transport'], 30000.0);
    });

    test('Adding custom category includes it in allCategories and saves it', () async {
      final provider = ExpenseProvider();
      await provider.loadData();

      await provider.addExpense(
        amount: 100000,
        category: 'Hobi Baru',
        date: DateTime(2026, 10, 1),
      );

      expect(provider.allCategories, contains('Hobi Baru'));

      // Verify persistence across provider reload
      final provider2 = ExpenseProvider();
      await provider2.loadData();
      expect(provider2.allCategories, contains('Hobi Baru'));
      expect(provider2.getExpensesForMonth(2026, 10).length, 1);
    });

    test('Delete expense updates state and persistence', () async {
      final provider = ExpenseProvider();
      await provider.loadData();

      await provider.addExpense(
        amount: 15000,
        category: 'Bensin',
        date: DateTime(2026, 10, 2),
      );

      var expenses = provider.getExpensesForMonth(2026, 10);
      expect(expenses.length, 1);
      final id = expenses.first.id;

      await provider.deleteExpense(id);
      expenses = provider.getExpensesForMonth(2026, 10);
      expect(expenses.isEmpty, true);

      // Verify persistence after delete
      final provider2 = ExpenseProvider();
      await provider2.loadData();
      expect(provider2.getExpensesForMonth(2026, 10).isEmpty, true);
    });

    test('Filtering by month separates dates properly', () async {
      final provider = ExpenseProvider();
      await provider.loadData();

      await provider.addExpense(
        amount: 20000,
        category: 'Makan',
        date: DateTime(2026, 9, 15),
      );
      await provider.addExpense(
        amount: 40000,
        category: 'Makan',
        date: DateTime(2026, 10, 1),
      );

      expect(provider.getTotalForMonth(2026, 9), 20000.0);
      expect(provider.getTotalForMonth(2026, 10), 40000.0);
    });

    test('Category budget limit can be set, retrieved, and removed', () async {
      final provider = ExpenseProvider();
      await provider.loadData();

      expect(provider.getCategoryLimit('Makan'), 0.0);

      await provider.setCategoryLimit('Makan', 1000000.0);
      expect(provider.getCategoryLimit('Makan'), 1000000.0);

      // Verify persistence
      final newProvider = ExpenseProvider();
      await newProvider.loadData();
      expect(newProvider.getCategoryLimit('Makan'), 1000000.0);

      await provider.removeCategoryLimit('Makan');
      expect(provider.getCategoryLimit('Makan'), 0.0);
    });

    test('Spending alerts correctly detect exceeded and warning budget thresholds', () async {
      final provider = ExpenseProvider();
      final date = DateTime(2026, 10, 5);

      await provider.setCategoryLimit('Makan', 100000.0);

      // Below 80%: no alert
      await provider.addExpense(amount: 50000.0, category: 'Makan', date: date);
      var alerts = provider.getSpendingAlerts(2026, 10);
      expect(alerts.where((a) => a.category == 'Makan'), isEmpty);

      // Between 80% and 99%: warning alert
      await provider.addExpense(amount: 35000.0, category: 'Makan', date: date); // total 85,000
      alerts = provider.getSpendingAlerts(2026, 10);
      expect(alerts.where((a) => a.category == 'Makan'), isNotEmpty);
      expect(alerts.firstWhere((a) => a.category == 'Makan').isExceeded, isFalse);

      // 100% or more: exceeded alert
      await provider.addExpense(amount: 20000.0, category: 'Makan', date: date); // total 105,000
      alerts = provider.getSpendingAlerts(2026, 10);
      final makanAlert = alerts.firstWhere((a) => a.category == 'Makan');
      expect(makanAlert.isExceeded, isTrue);
      expect(makanAlert.currentSpent, 105000.0);
      expect(makanAlert.limit, 100000.0);
    });

    test('checkPotentialAlert warns before saving transaction that will exceed limit', () async {
      final provider = ExpenseProvider();
      final date = DateTime(2026, 10, 10);
      await provider.setCategoryLimit('Transport', 50000.0);

      final alert = provider.checkPotentialAlert(
        category: 'Transport',
        newAmount: 60000.0,
        date: date,
      );

      expect(alert, isNotNull);
      expect(alert!.isExceeded, isTrue);
      expect(alert.currentSpent, 60000.0);
    });

    test('Disabling notification toggle silences all alerts', () async {
      final provider = ExpenseProvider();
      final date = DateTime(2026, 10, 15);
      await provider.setCategoryLimit('Belanja', 50000.0);
      await provider.addExpense(amount: 100000.0, category: 'Belanja', date: date);

      expect(provider.getSpendingAlerts(2026, 10), isNotEmpty);

      await provider.setNotificationEnabled(false);
      expect(provider.isNotificationEnabled, isFalse);
      expect(provider.getSpendingAlerts(2026, 10), isEmpty);
      expect(provider.checkPotentialAlert(category: 'Belanja', newAmount: 10000, date: date), isNull);
    });
  });

  group('CurrencyFormatter Tests', () {
    test('format formats currency with Rp prefix and no decimals', () {
      final formatted = CurrencyFormatter.format(50000);
      expect(formatted, contains('50.000'));
      expect(formatted, contains('Rp'));
    });

    test('formatCompact formats millions and thousands correctly', () {
      expect(CurrencyFormatter.formatCompact(1500000), 'Rp 1.5jt');
      expect(CurrencyFormatter.formatCompact(50000), 'Rp 50rb');
      expect(CurrencyFormatter.formatCompact(500), contains('500'));
    });

    test('formatDate and formatMonthYear use Indonesian locale', () {
      final date = DateTime(2026, 10, 3);
      final monthYear = CurrencyFormatter.formatMonthYear(date);
      expect(monthYear, 'Oktober 2026');

      final formattedDate = CurrencyFormatter.formatDate(date);
      expect(formattedDate, contains('Okt'));
      expect(formattedDate, contains('2026'));
    });

    test('formatDayShort returns Hari ini for today', () {
      final now = DateTime.now();
      expect(CurrencyFormatter.formatDayShort(now), 'Hari ini');
    });

    test('formatDigits formats pure digits with thousand separator dots', () {
      expect(CurrencyFormatter.formatDigits(1000000), '1.000.000');
      expect(CurrencyFormatter.formatDigits(50000), '50.000');
      expect(CurrencyFormatter.formatDigits(500), '500');
      expect(CurrencyFormatter.formatDigits(12345678), '12.345.678');
    });

    test('ThousandsSeparatorInputFormatter formats numeric input dynamically', () {
      final formatter = ThousandsSeparatorInputFormatter();

      // Empty input
      final emptyResult = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: ''),
      );
      expect(emptyResult.text, '');

      // Typing 1000000
      final result1 = formatter.formatEditUpdate(
        const TextEditingValue(text: '100000', selection: TextSelection(baseOffset: 6, extentOffset: 6)),
        const TextEditingValue(text: '1000000', selection: TextSelection(baseOffset: 7, extentOffset: 7)),
      );
      expect(result1.text, '1.000.000');
      expect(result1.selection.end, 9);

      // Backspacing separator dot
      final result2 = formatter.formatEditUpdate(
        const TextEditingValue(text: '1.000', selection: TextSelection(baseOffset: 2, extentOffset: 2)),
        const TextEditingValue(text: '1000', selection: TextSelection(baseOffset: 1, extentOffset: 1)),
      );
      expect(result2.text, '000');
    });
  });
}

