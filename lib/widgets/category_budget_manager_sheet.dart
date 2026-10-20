import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../utils/theme.dart';
import '../utils/formatter.dart';
import 'category_budget_dialog.dart';

class CategoryBudgetManagerSheet extends StatelessWidget {
  final int year;
  final int month;

  const CategoryBudgetManagerSheet({
    super.key,
    required this.year,
    required this.month,
  });

  static void show(BuildContext context, {required int year, required int month}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryBudgetManagerSheet(year: year, month: month),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final allCategories = provider.allCategories;
    final categoryTotals = provider.getCategoryTotalsForMonth(year, month);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppTheme.isDark ? 0.5 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batas Anggaran Kategori',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Atur batas maksimal pengeluaran bulanan',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
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
          const SizedBox(height: 18),

          // Category list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: allCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = allCategories[index];
                final spent = categoryTotals[category] ?? 0.0;
                final limit = provider.getCategoryLimit(category);
                final hasLimit = limit > 0;
                final isExceeded = hasLimit && spent >= limit;
                final isNear = hasLimit && !isExceeded && spent >= limit * 0.8;
                final categoryColor =
                    AppTheme.getCategoryColor(category, allCategories);

                return GestureDetector(
                  onTap: () => CategoryBudgetDialog.show(
                    context,
                    category: category,
                    year: year,
                    month: month,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isExceeded
                          ? AppTheme.danger.withOpacity(0.06)
                          : AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isExceeded
                            ? AppTheme.danger.withOpacity(0.4)
                            : isNear
                                ? AppTheme.primary.withOpacity(0.4)
                                : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: categoryColor.withOpacity(0.25)),
                          ),
                          child: Center(
                            child: Image.asset(
                              AppIcons.getIcon(category),
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    hasLimit
                                        ? 'Batas: ${CurrencyFormatter.format(limit)}'
                                        : 'Batas belum diatur',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: hasLimit
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isExceeded
                                          ? AppTheme.danger
                                          : hasLimit
                                              ? AppTheme.primary
                                              : AppTheme.textMuted,
                                    ),
                                  ),
                                  if (spent > 0) ...[
                                    Text(
                                      ' • Terpakai: ${CurrencyFormatter.formatCompact(spent)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: hasLimit
                                ? (isExceeded
                                    ? AppTheme.danger.withOpacity(0.12)
                                    : AppTheme.primary.withOpacity(0.12))
                                : AppTheme.surfaceGlass,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasLimit
                                  ? (isExceeded
                                      ? AppTheme.danger.withOpacity(0.3)
                                      : AppTheme.primary.withOpacity(0.3))
                                  : AppTheme.border,
                            ),
                          ),
                          child: Text(
                            hasLimit ? 'Ubah' : '+ Atur',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: hasLimit
                                  ? (isExceeded
                                      ? AppTheme.danger
                                      : AppTheme.primary)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
