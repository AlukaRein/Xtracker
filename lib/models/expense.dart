import 'dart:convert';

class Expense {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'],
        amount: map['amount'].toDouble(),
        category: map['category'],
        date: DateTime.parse(map['date']),
        note: map['note'] ?? '',
      );

  String toJson() => jsonEncode(toMap());
  factory Expense.fromJson(String source) =>
      Expense.fromMap(jsonDecode(source));
}
