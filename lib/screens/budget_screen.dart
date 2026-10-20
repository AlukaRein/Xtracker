import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../models/category_alert.dart';
import '../utils/theme.dart';
import '../utils/formatter.dart';
import '../widgets/month_year_picker_dialog.dart';
import '../widgets/category_budget_dialog.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  String _filter = 'all'; // 'all', 'with_limit', 'alerts'
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });
    }
  }

  Future<void> _pickMonthYear() async {
    final picked = await MonthYearPickerDialog.show(
      context,
      initialDate: _selectedMonth,
    );
    if (picked != null) {
      setState(() => _selectedMonth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final provider = context.watch<ExpenseProvider>();
    final allCategories = provider.allCategories;
    final categoryTotals = provider.getCategoryTotalsForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final alerts = provider.getSpendingAlerts(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    // Calculate overall budget stats
    double totalBudget = 0.0;
    double totalSpentOnBudgeted = 0.0;
    int categoriesWithLimit = 0;

    for (final cat in allCategories) {
      final limit = provider.getCategoryLimit(cat);
      if (limit > 0) {
        totalBudget += limit;
        totalSpentOnBudgeted += (categoryTotals[cat] ?? 0.0);
        categoriesWithLimit++;
      }
    }

    final totalSpentMonth = provider.getTotalForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    // Filter categories
    final filteredCategories = allCategories.where((cat) {
      final limit = provider.getCategoryLimit(cat);
      final spent = categoryTotals[cat] ?? 0.0;

      if (_filter == 'with_limit') {
        return limit > 0;
      } else if (_filter == 'alerts') {
        return limit > 0 && spent >= (limit * 0.8);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // AppBar
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.tune_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anggaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'Pagu & Batas Kategori',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppTheme.border,
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Month Selector
                  _buildMonthSelector(),
                  const SizedBox(height: 16),

                  // Overview Summary Card
                  _buildOverviewCard(
                    totalBudget: totalBudget,
                    totalSpentMonth: totalSpentMonth,
                    totalSpentOnBudgeted: totalSpentOnBudgeted,
                    categoriesWithLimit: categoriesWithLimit,
                    totalCategories: allCategories.length,
                  ),
                  const SizedBox(height: 18),

                  // Alerts if any
                  if (alerts.isNotEmpty) ...[
                    _buildAlertsSection(alerts),
                    const SizedBox(height: 18),
                  ],

                  // Filter Chips
                  _buildFilterChips(alerts.length, categoriesWithLimit),
                  const SizedBox(height: 14),

                  // Category Budget List
                  ...filteredCategories.map((cat) {
                    final spent = categoryTotals[cat] ?? 0.0;
                    final limit = provider.getCategoryLimit(cat);
                    final color =
                        AppTheme.getCategoryColor(cat, allCategories);
                    return _buildCategoryBudgetCard(
                      category: cat,
                      spent: spent,
                      limit: limit,
                      color: color,
                    );
                  }),

                  if (filteredCategories.isEmpty)
                    _buildEmptyFilterState(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Month Selector ─────────────────────────────────────────────────────────
  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded,
                color: AppTheme.primary, size: 24),
            onPressed: _prevMonth,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _pickMonthYear,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 15, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.formatMonthYear(_selectedMonth),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded,
                      color: AppTheme.textMuted, size: 20),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isCurrentMonth ? AppTheme.textMuted.withOpacity(0.3) : AppTheme.primary,
              size: 24,
            ),
            onPressed: isCurrentMonth ? null : _nextMonth,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ── Overview Card ─────────────────────────────────────────────────────────
  Widget _buildOverviewCard({
    required double totalBudget,
    required double totalSpentMonth,
    required double totalSpentOnBudgeted,
    required int categoriesWithLimit,
    required int totalCategories,
  }) {
    final hasBudget = totalBudget > 0;
    final ratio = hasBudget ? (totalSpentOnBudgeted / totalBudget).clamp(0.0, 1.0) : 0.0;
    final isExceeded = hasBudget && totalSpentOnBudgeted >= totalBudget;
    final isNearLimit = hasBudget && !isExceeded && ratio >= 0.8;

    final statusColor = isExceeded
        ? AppTheme.danger
        : isNearLimit
            ? AppTheme.primary
            : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasBudget
              ? statusColor.withOpacity(0.35)
              : AppTheme.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppTheme.isDark ? 0.35 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Anggaran Bulanan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (hasBudget ? statusColor : AppTheme.textMuted)
                      .withOpacity(0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasBudget
                      ? '${(ratio * 100).toInt()}% Terpakai'
                      : '$categoriesWithLimit/$totalCategories Dibatasi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: hasBudget ? statusColor : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(hasBudget ? totalSpentOnBudgeted : totalSpentMonth),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (hasBudget) ...[
                const SizedBox(width: 6),
                Text(
                  '/ ${CurrencyFormatter.formatCompact(totalBudget)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: hasBudget ? ratio : 0.0,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceGlass,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasBudget
                    ? (isExceeded
                        ? 'Melebihi total batas anggaran!'
                        : 'Sisa: ${CurrencyFormatter.format(totalBudget - totalSpentOnBudgeted)}')
                    : 'Belum ada batas anggaran yang diatur.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isExceeded ? AppTheme.danger : AppTheme.textMuted,
                ),
              ),
              Text(
                '$categoriesWithLimit kategori diatur',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Alerts Section ────────────────────────────────────────────────────────
  Widget _buildAlertsSection(List<CategoryAlert> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.danger, size: 16),
            const SizedBox(width: 6),
            Text(
              'Perhatian Pengeluaran (${alerts.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...alerts.map((alert) {
          final isExceeded = alert.isExceeded;
          final color = isExceeded ? AppTheme.danger : AppTheme.primary;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isExceeded ? Icons.error_rounded : Icons.info_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Filter Chips ──────────────────────────────────────────────────────────
  Widget _buildFilterChips(int alertsCount, int withLimitCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            id: 'all',
            label: 'Semua Kategori',
            icon: Icons.apps_rounded,
          ),
          const SizedBox(width: 8),
          _filterChip(
            id: 'with_limit',
            label: 'Ada Batas ($withLimitCount)',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(width: 8),
          _filterChip(
            id: 'alerts',
            label: 'Peringatan ($alertsCount)',
            icon: Icons.warning_rounded,
            highlightColor: alertsCount > 0 ? AppTheme.danger : null,
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String id,
    required String label,
    required IconData icon,
    Color? highlightColor,
  }) {
    final active = _filter == id;
    final color = highlightColor ?? AppTheme.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? color.withOpacity(0.15)
              : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : AppTheme.border,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? color : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Budget Card ──────────────────────────────────────────────────
  Widget _buildCategoryBudgetCard({
    required String category,
    required double spent,
    required double limit,
    required Color color,
  }) {
    final hasLimit = limit > 0;
    final isExceeded = hasLimit && spent >= limit;
    final isNearLimit = hasLimit && !isExceeded && (spent >= limit * 0.8);
    final ratio = hasLimit ? (spent / limit).clamp(0.0, 1.0) : 0.0;

    final statusColor = isExceeded
        ? AppTheme.danger
        : isNearLimit
            ? AppTheme.primary
            : color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isExceeded
            ? AppTheme.danger.withOpacity(0.05)
            : AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExceeded
              ? AppTheme.danger.withOpacity(0.4)
              : isNearLimit
                  ? AppTheme.primary.withOpacity(0.4)
                  : AppTheme.border,
          width: (isExceeded || isNearLimit) ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.25)),
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

              // Title and Amounts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isExceeded) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Melebihi',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.danger,
                              ),
                            ),
                          ),
                        ] else if (isNearLimit) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Mendekati',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(spent),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (hasLimit) ...[
                          Text(
                            ' / ${CurrencyFormatter.formatCompact(limit)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isExceeded
                                  ? AppTheme.danger
                                  : AppTheme.textMuted,
                              fontWeight: isExceeded
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          Text(
                            ' • Belum ada batas',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Button to Set / Edit limit
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.lightImpact();
                  CategoryBudgetDialog.show(
                    context,
                    category: category,
                    year: _selectedMonth.year,
                    month: _selectedMonth.month,
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasLimit
                        ? AppTheme.surfaceGlass
                        : AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasLimit
                          ? AppTheme.border
                          : AppTheme.primary.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasLimit ? Icons.edit_rounded : Icons.add_rounded,
                        size: 13,
                        color: hasLimit
                            ? AppTheme.textSecondary
                            : AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasLimit ? 'Ubah' : 'Atur',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hasLimit
                              ? AppTheme.textSecondary
                              : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Progress Bar if limit exists
          if (hasLimit) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: AppTheme.surfaceGlass,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Empty Filter State ────────────────────────────────────────────────────
  Widget _buildEmptyFilterState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.filter_list_off_rounded,
                size: 36, color: AppTheme.textMuted),
            const SizedBox(height: 10),
            Text(
              'Tidak ada kategori sesuai filter',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ubah filter di atas untuk melihat kategori lainnya',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
