import 'package:flutter/material.dart';
import '../utils/theme.dart';

class MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const MonthYearPickerDialog({
    super.key,
    required this.initialDate,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (_) => MonthYearPickerDialog(initialDate: initialDate),
    );
  }

  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
  late int _tempYear;
  late int _tempMonth;
  final DateTime _now = DateTime.now();

  static const List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _tempYear = widget.initialDate.year;
    _tempMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilih Bulan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceGlass,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppTheme.textMuted,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Year selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGlass,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _tempYear--),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    '$_tempYear',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_tempYear < _now.year) {
                        setState(() => _tempYear++);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _tempYear >= _now.year
                            ? Colors.transparent
                            : AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _tempYear >= _now.year
                              ? Colors.transparent
                              : AppTheme.border,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: _tempYear >= _now.year
                            ? AppTheme.textMuted.withOpacity(0.3)
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Month grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (_, i) {
                final m = i + 1;
                final isDisabled = _tempYear == _now.year && m > _now.month;

                return GestureDetector(
                  onTap: isDisabled ? null : () => setState(() => _tempMonth = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: _tempMonth == m
                          ? AppTheme.primary.withOpacity(0.15)
                          : isDisabled
                              ? Colors.transparent
                              : AppTheme.surfaceGlass,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _tempMonth == m
                            ? AppTheme.primary.withOpacity(0.6)
                            : isDisabled
                                ? AppTheme.border.withOpacity(0.3)
                                : AppTheme.border,
                        width: _tempMonth == m ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _months[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: _tempMonth == m
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _tempMonth == m
                            ? AppTheme.primary
                            : isDisabled
                                ? AppTheme.textMuted.withOpacity(0.3)
                                : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Confirm button
            GestureDetector(
              onTap: () {
                Navigator.pop(context, DateTime(_tempYear, _tempMonth));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Pilih',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1000),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
