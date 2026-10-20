import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(double amount) => _formatter.format(amount);

  static String formatDigits(num amount, {String separator = '.'}) {
    final digits = amount.toInt().toString();
    final buffer = StringBuffer();
    final length = digits.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String formatDayShort(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Hari ini';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Kemarin';
    }
    return DateFormat('EEE, d MMM', 'id_ID').format(date);
  }
}

/// Formatter input teks angka dengan pemisah ribuan per 3 digit otomatis.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final String separator;

  ThousandsSeparatorInputFormatter({this.separator = '.'});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String textToProcess = newValue.text;
    int cursorOffset = newValue.selection.end;

    // Deteksi jika pengguna menekan backspace tepat pada pemisah (misal: titik)
    if (oldValue.text.length - newValue.text.length == 1 &&
        oldValue.selection.end > 0 &&
        oldValue.selection.end <= oldValue.text.length &&
        oldValue.text[oldValue.selection.end - 1] == separator) {
      final deleteIndex = oldValue.selection.end - 2;
      if (deleteIndex >= 0 && deleteIndex < textToProcess.length) {
        textToProcess = textToProcess.substring(0, deleteIndex) +
            textToProcess.substring(deleteIndex + 1);
        cursorOffset = deleteIndex;
      }
    }

    // Ambil digit murni
    final digits = textToProcess.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Hitung berapa digit angka murni sebelum posisi kursor
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorOffset && i < textToProcess.length; i++) {
      if (RegExp(r'\d').hasMatch(textToProcess[i])) {
        digitsBeforeCursor++;
      }
    }

    // Format dengan pemisah ribuan per 3 digit
    final buffer = StringBuffer();
    final length = digits.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();

    // Hitung posisi kursor baru pada teks terformat
    int newCursorOffset = 0;
    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor) {
        newCursorOffset = i + 1;
        break;
      }
    }

    if (digitsBeforeCursor == 0) {
      newCursorOffset = 0;
    } else if (digitCount < digitsBeforeCursor) {
      newCursorOffset = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorOffset.clamp(0, formatted.length),
      ),
    );
  }
}

