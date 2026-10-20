import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';
import '../utils/formatter.dart';
import '../widgets/month_year_picker_dialog.dart';
import '../widgets/category_budget_dialog.dart';
import '../widgets/category_budget_manager_sheet.dart';
import '../widgets/google_avatar.dart';
import '../models/category_alert.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  int _touchedIndex = -1;
  bool _showPie = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
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

  void _showGoogleProfileSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            if (auth.isSignedIn) ...[
              GoogleAvatar(
                photoUrl: auth.photoUrl,
                displayName: auth.displayName,
                size: 64,
                borderWidth: 2,
                borderColor: AppTheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                auth.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                auth.email,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '✓ Akun Google Terhubung',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_rounded,
                      size: 13, color: AppTheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Sinkronisasi Cloud Firebase Aktif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await auth.signOut();
                },
                icon:
                    Icon(Icons.logout_rounded, size: 16, color: AppTheme.danger),
                label: Text(
                  'Keluar dari Akun Google',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.danger,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.danger.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ] else ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum Masuk Akun Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Masuk dengan akun Google untuk menyinkronkan profil Anda',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await auth.signInWithGoogle();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.isDark
                      ? const Color(0xFF1A1000)
                      : Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('G',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    SizedBox(width: 8),
                    Text('Masuk dengan Google',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatarLetter(String name) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'G';
    return Container(
      color: AppTheme.primary.withOpacity(0.15),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final provider = context.watch<ExpenseProvider>();
    final allCategories = provider.allCategories;
    final total =
        provider.getTotalForMonth(_selectedMonth.year, _selectedMonth.month);
    final categoryTotals = provider.getCategoryTotalsForMonth(
        _selectedMonth.year, _selectedMonth.month);
    final alerts =
        provider.getSpendingAlerts(_selectedMonth.year, _selectedMonth.month);
    final categories = categoryTotals.keys.toList();
    final values = categoryTotals.values.toList();
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  // Logo with gold ring
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.5), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/icons/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'XTracker',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'Pencatat Pengeluaran',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // User Profile Avatar button with Google Account support
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final isSignedIn = auth.isSignedIn;
                      final photoUrl = auth.photoUrl;
                      final displayName = auth.displayName;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showGoogleProfileSheet(context, auth);
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            if (isSignedIn)
                              GoogleAvatar(
                                photoUrl: photoUrl,
                                displayName: displayName,
                                size: 38,
                                borderWidth: 1.5,
                                borderColor: AppTheme.primary.withOpacity(0.7),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.15),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              )
                            else
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withOpacity(0.12),
                                  border: Border.all(
                                    color: AppTheme.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            if (isSignedIn)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.border,
                        AppTheme.borderGlow.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Month Selector ──────────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _monthNavBtn(Icons.chevron_left_rounded, _prevMonth),

                        // Tappable month/year label
                        GestureDetector(
                          onTap: _pickMonthYear,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyFormatter.formatMonthYear(
                                      _selectedMonth),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.expand_more_rounded,
                                    color: AppTheme.primary, size: 16),
                              ],
                            ),
                          ),
                        ),

                        _monthNavBtn(Icons.chevron_right_rounded, _nextMonth,
                            disabled: isCurrentMonth),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Spending Alerts (if any) ─────────────────────────────
                  if (alerts.isNotEmpty) ...[
                    _buildAlertsSection(alerts),
                    const SizedBox(height: 16),
                  ],

                  // ── Total Card (Hero) ────────────────────────────────────
                  _buildTotalCard(total, categoryTotals, provider),
                  const SizedBox(height: 16),

                  // ── Chart or Empty ───────────────────────────────────────
                  if (categoryTotals.isNotEmpty) ...[
                    _buildChartSection(
                        categories, values, total, allCategories, provider),
                  ] else ...[
                    _buildEmptyState(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthNavBtn(IconData icon, VoidCallback onTap,
      {bool disabled = false}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: disabled ? Colors.transparent : AppTheme.surfaceGlass,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled
                ? Colors.transparent
                : AppTheme.borderGlow.withOpacity(0.5),
          ),
        ),
        child: Icon(
          icon,
          color: disabled
              ? AppTheme.textMuted.withOpacity(0.3)
              : AppTheme.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total, Map<String, double> categoryTotals,
      ExpenseProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.isDark
              ? const [
                  Color(0xFF141820), // surfaceHigh
                  Color(0xFF0E1118), // surface
                  Color(0xFF080A0F), // bg
                ]
              : [
                  Colors.white,
                  AppTheme.surface,
                  AppTheme.surfaceHigh,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.isDark
              ? AppTheme.primary.withOpacity(0.25)
              : AppTheme.primary.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark
                ? AppTheme.primary.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.8),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TOTAL PENGELUARAN',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                CurrencyFormatter.format(total),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatMonthYear(_selectedMonth),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.3),
                      AppTheme.border.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _statBadge(
                    '${categoryTotals.length}',
                    'Kategori',
                    AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  _statBadge(
                    '${provider.getExpensesForMonth(_selectedMonth.year, _selectedMonth.month).length}',
                    'Transaksi',
                    AppTheme.accent,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(List<CategoryAlert> alerts) {
    final hasExceeded = alerts.any((a) => a.isExceeded);
    final primaryAlertColor = hasExceeded ? AppTheme.danger : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryAlertColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryAlertColor.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryAlertColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasExceeded
                      ? Icons.warning_rounded
                      : Icons.notifications_active_rounded,
                  color: primaryAlertColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasExceeded
                      ? 'Peringatan: Pengeluaran Melebihi Batas'
                      : 'Perhatian: Pengeluaran Kategori Tinggi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...alerts.map((alert) => _buildAlertItem(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(CategoryAlert alert) {
    final isExceeded = alert.isExceeded;
    final alertColor = isExceeded ? AppTheme.danger : AppTheme.primary;
    final progress = alert.percent.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => CategoryBudgetDialog.show(
        context,
        category: alert.category,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: alertColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  AppIcons.getIcon(alert.category),
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: alertColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: alertColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    isExceeded ? 'Melebihi Batas' : 'Mendekati Batas',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: alertColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              alert.message,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(alert.currentSpent),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: alertColor,
                  ),
                ),
                Text(
                  'Batas: ${CurrencyFormatter.format(alert.limit)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: alertColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(alertColor),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(List<String> categories, List<double> values,
      double total, List<String> allCategories, ExpenseProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  CategoryBudgetManagerSheet.show(
                    context,
                    year: _selectedMonth.year,
                    month: _selectedMonth.month,
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Distribusi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ),
                      Text(
                        'Tap untuk atur batas anggaran',
                        style: TextStyle(fontSize: 11, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    _chartToggle(Icons.donut_large_rounded, true),
                    _chartToggle(Icons.bar_chart_rounded, false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_showPie)
            _buildPieChart(categories, values, total, allCategories)
          else
            _buildBarChart(categories, values, allCategories),
          const SizedBox(height: 20),
          ...categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final val = values[i];
            final pct =
                total > 0 ? (val / total * 100).toStringAsFixed(1) : '0';
            final color = AppTheme.getCategoryColor(cat, allCategories);
            return _categoryLegendItem(cat, val, pct, color, provider);
          }),
        ],
      ),
    );
  }

  Widget _categoryLegendItem(String cat, double val, String pct, Color color,
      ExpenseProvider provider) {
    final limit = provider.getCategoryLimit(cat);
    final hasLimit = limit > 0;
    final isExceeded = hasLimit && val >= limit;
    final isNearLimit = hasLimit && !isExceeded && (val >= limit * 0.8);

    return GestureDetector(
      onTap: () => CategoryBudgetDialog.show(
        context,
        category: cat,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isExceeded
              ? AppTheme.danger.withOpacity(0.06)
              : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExceeded
                ? AppTheme.danger.withOpacity(0.4)
                : isNearLimit
                    ? AppTheme.primary.withOpacity(0.4)
                    : color.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
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
                      AppIcons.getIcon(cat),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(val),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (hasLimit) ...[
                            Text(
                              ' / ${CurrencyFormatter.formatCompact(limit)}',
                              style: TextStyle(
                                fontSize: 10,
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
                              ' • Atur Batas',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (hasLimit) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (val / limit).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.surfaceGlass,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExceeded
                        ? AppTheme.danger
                        : isNearLimit
                            ? AppTheme.primary
                            : color,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: const Center(
              child: Text('💸', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada pengeluaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap tombol + untuk mulai mencatat',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {
              CategoryBudgetManagerSheet.show(
                context,
                year: _selectedMonth.year,
                month: _selectedMonth.month,
              );
            },
            icon: Icon(Icons.tune_rounded, size: 16, color: AppTheme.primary),
            label: Text(
              'Atur Batas Anggaran Kategori',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartToggle(IconData icon, bool isPie) {
    final active = _showPie == isPie;
    return GestureDetector(
      onTap: () => setState(() => _showPie = isPie),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              active ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active
              ? Border.all(color: AppTheme.primary.withOpacity(0.4))
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppTheme.primary : AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildPieChart(List<String> cats, List<double> vals, double total,
      List<String> allCategories) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.06),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 62,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (response?.touchedSection != null) {
                      _touchedIndex =
                          response!.touchedSection!.touchedSectionIndex;
                    } else {
                      _touchedIndex = -1;
                    }
                  });
                },
              ),
              sections: cats.asMap().entries.map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final val = vals[i];
                final isTouched = _touchedIndex == i;
                final color = AppTheme.getCategoryColor(cat, allCategories);
                return PieChartSectionData(
                  value: val,
                  color: color,
                  radius: isTouched ? 72 : 62,
                  title: '',
                  borderSide: BorderSide(
                    color: isTouched
                        ? Colors.white.withOpacity(0.4)
                        : Colors.transparent,
                    width: 2,
                  ),
                );
              }).toList(),
              centerSpaceColor: AppTheme.surface,
            ),
          ),
          if (_touchedIndex >= 0 && _touchedIndex < cats.length)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.getCategoryColor(
                          cats[_touchedIndex], allCategories)
                      .withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.getCategoryColor(
                            cats[_touchedIndex], allCategories)
                        .withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppIcons.getIcon(cats[_touchedIndex]),
                      width: 26, height: 26),
                  const SizedBox(height: 4),
                  Text(
                    '${(vals[_touchedIndex] / total * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getCategoryColor(
                          cats[_touchedIndex], allCategories),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/category.png',
                      width: 26, height: 26),
                  const SizedBox(height: 2),
                  Text(
                    '${cats.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'kategori',
                    style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      List<String> cats, List<double> vals, List<String> allCategories) {
    final maxVal = vals.isEmpty ? 100.0 : vals.reduce((a, b) => a > b ? a : b);
    final barWidth = cats.length > 6
        ? 16.0
        : cats.length > 4
            ? 22.0
            : 30.0;

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: maxVal * 1.3,
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.surfaceGlass,
              tooltipBorder: BorderSide(color: AppTheme.borderGlow, width: 1),
              tooltipRoundedRadius: 10,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              tooltipMargin: 6,
              maxContentWidth: 120,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final color =
                    AppTheme.getCategoryColor(cats[groupIndex], allCategories);
                return BarTooltipItem(
                  '',
                  const TextStyle(),
                  children: [
                    TextSpan(
                      text: '${cats[groupIndex]}\n',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: CurrencyFormatter.formatCompact(vals[groupIndex]),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= vals.length) return const SizedBox();
                  final color =
                      AppTheme.getCategoryColor(cats[i], allCategories);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      CurrencyFormatter.formatCompact(vals[i]),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= cats.length) return const SizedBox();
                  final color =
                      AppTheme.getCategoryColor(cats[i], allCategories);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Image.asset(AppIcons.getIcon(cats[i]),
                            width: 20, height: 20),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxVal * 0.5,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      CurrencyFormatter.formatCompact(value),
                      style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal * 0.5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.border.withOpacity(0.4),
              strokeWidth: 1,
              dashArray: [4, 6],
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom:
                  BorderSide(color: AppTheme.border.withOpacity(0.5), width: 1),
              left:
                  BorderSide(color: AppTheme.border.withOpacity(0.5), width: 1),
            ),
          ),
          barGroups: cats.asMap().entries.map((entry) {
            final i = entry.key;
            final color = AppTheme.getCategoryColor(cats[i], allCategories);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: vals[i],
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  width: barWidth,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                    bottom: Radius.zero,
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.3,
                    color: color.withOpacity(0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
        swapAnimationCurve: Curves.easeInOutCubic,
      ),
    );
  }
}
