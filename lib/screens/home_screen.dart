import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'form_transaction_screen.dart';
import 'transactions_screen.dart';
import 'material_screen.dart';
import 'debt_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  Map<String, dynamic> _stats = {};
  List<TransactionModel> _recentTxs = [];
  Map<String, dynamic>? _neracaData;
  bool _isLoading = true;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    setState(() => _isLoading = true);
    final cats = await widget.apiService.getCategories();

    final user = widget.authService.currentUser;
    List<CategoryModel> allowedCats = cats;
    if (user != null && !user.isAdmin && !user.isPimpinan && user.assignedCategories.isNotEmpty) {
      allowedCats = cats.where((c) => user.assignedCategories.contains(c.id)).toList();
    }

    if (!mounted) return;
    setState(() {
      _categories = allowedCats;
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
    });

    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_selectedCategory == null) {
      setState(() => _isLoading = false);
      return;
    }

    final catId = _selectedCategory!.id;
    final posData = await widget.apiService.getPosTransactions(categoryId: catId);
    final txs = await widget.apiService.getTransactions(categoryId: catId, limit: 10);
    final neraca = await widget.apiService.getPosBalanceSheet(catId);

    final List<TransactionModel> posTxs = (posData['transactions'] as List<TransactionModel>?) ?? [];
    final List<TransactionModel> allRecent = [...posTxs, ...txs];
    allRecent.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    if (!mounted) return;
    setState(() {
      _stats = posData['summary'] ?? {};
      _recentTxs = allRecent.take(10).toList();
      _neracaData = neraca;
      _isLoading = false;
    });
  }

  void _openFormTransaction(String jenis) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => FormTransactionScreen(
          apiService: widget.apiService,
          categories: _categories,
          initialCategoryId: _selectedCategory?.id,
          initialType: jenis,
        ),
      ),
    );

    if (result == true) {
      _loadDashboardData();
    }
  }

  void _showPosSelectorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Pos / Akun Program',
                          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _categories.length,
                      itemBuilder: (c, i) {
                        final cat = _categories[i];
                        final isSelected = cat.id == _selectedCategory?.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              cat.code,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textBody,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            cat.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppTheme.primary : AppTheme.textMain,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20)
                              : null,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            Navigator.pop(ctx);
                            _loadDashboardData();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeTab() {
    final saldoKas = (_stats['saldo_kas_pos'] ?? 0.0).toDouble();
    final totalIn = (_stats['total_income'] ?? 0.0).toDouble();
    final totalOut = (_stats['total_expense'] ?? 0.0).toDouble();
    final user = widget.authService.currentUser;

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top User Greeting & Pos Switcher Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Bertugas,',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.name ?? 'Petugas Lapangan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Pos Pill Button
                InkWell(
                  onTap: _showPosSelectorSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.income,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            _selectedCategory?.name ?? 'Pilih Pos',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Modern Luxury Wallet Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: AppTheme.glowShadow(AppTheme.primary),
              ),
              child: Stack(
                children: [
                  // Decorative subtle background pattern
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    bottom: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.wallet_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Saldo Kas Lapangan',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 18,
                            ),
                            onPressed: () => setState(() => _hideBalance = !_hideBalance),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _hideBalance ? 'Rp ••••••••' : Formatters.formatCurrency(saldoKas),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.income.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF6EE7B7), size: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Masuk', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 10)),
                                        Text(
                                          _hideBalance ? '••••••' : Formatters.formatCurrency(totalIn),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 24, color: Colors.white24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.expense.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFFCA5A5), size: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Keluar', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 10)),
                                        Text(
                                          _hideBalance ? '••••••' : Formatters.formatCurrency(totalOut),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aksi Operasional',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                ),
                Text(
                  'Shortcut',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4 Modern Squircle Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildSquircleAction(
                    icon: Icons.add_rounded,
                    label: 'Catat Masuk',
                    sublabel: 'Donasi / Alokasi',
                    color: AppTheme.income,
                    bgColor: AppTheme.incomeBg,
                    onTap: () => _openFormTransaction('income'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSquircleAction(
                    icon: Icons.remove_rounded,
                    label: 'Catat Belanja',
                    sublabel: 'Operasional Riil',
                    color: AppTheme.expense,
                    bgColor: AppTheme.expenseBg,
                    onTap: () => _openFormTransaction('expense'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSquircleAction(
                    icon: Icons.inventory_2_rounded,
                    label: 'Stok Material',
                    sublabel: 'Semen & Besi',
                    color: AppTheme.warning,
                    bgColor: AppTheme.warningBg,
                    onTap: () => setState(() => _currentTabIndex = 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSquircleAction(
                    icon: Icons.handshake_rounded,
                    label: 'Hutang Piutang',
                    sublabel: 'Tracking Toko',
                    color: AppTheme.info,
                    bgColor: AppTheme.infoBg,
                    onTap: () => setState(() => _currentTabIndex = 3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Neraca Konsolidasi Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Neraca Konsolidasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rekap Induk',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Neraca Konsolidasi Card
            _buildNeracaCard(),

            const SizedBox(height: 28),

            // Recent Transactions Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaksi Terkini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentTabIndex = 1),
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_recentTxs.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 40, color: AppTheme.textLight.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada transaksi di pos ini',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._recentTxs.map((tx) {
                final isIncome = tx.isIncome;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isIncome ? AppTheme.incomeBg : AppTheme.expenseBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                          color: isIncome ? AppTheme.income : AppTheme.expense,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.donatur,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tx.tanggal} • ${tx.metode}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'} ${Formatters.formatCurrency(tx.nominal)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isIncome ? AppTheme.income : AppTheme.expense,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSquircleAction({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeracaCard() {
    final pos = _neracaData?['pos'] as Map<String, dynamic>?;
    final aktiva = _neracaData?['aktiva'] as Map<String, dynamic>?;
    final passiva = _neracaData?['passiva'] as Map<String, dynamic>?;
    final reconciliation = _neracaData?['reconciliation'] as Map<String, dynamic>?;

    final posName = pos?['name'] ?? _selectedCategory?.name ?? 'Pos Lapangan';
    final posCode = pos?['code'] ?? _selectedCategory?.code ?? '-';
    final picName = pos?['pic_name'] ?? 'Pengurus Lapangan';

    final totalAktiva = (aktiva?['total_aktiva'] ?? 0.0).toDouble();
    final totalPassiva = (passiva?['total_passiva'] ?? 0.0).toDouble();
    final isBalanced = reconciliation?['is_balanced'] == true;
    final statusText = reconciliation?['status'] ?? (isBalanced ? 'SEIMBANG (KLOP)' : 'DATA TERKONSOLIDASI');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: _showNeracaDetailSheet,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: KOP Tag & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryDark, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Neraca: $posName',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppTheme.textMain,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Kode: $posCode • PJ: $picName',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBalanced ? AppTheme.incomeBg : AppTheme.warningBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBalanced ? AppTheme.income.withValues(alpha: 0.3) : AppTheme.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBalanced ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 13,
                            color: isBalanced ? AppTheme.income : AppTheme.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBalanced ? 'KLOP' : 'SELISIH',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isBalanced ? AppTheme.income : AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Comparison Columns (Aktiva vs Passiva)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Sisi Aktiva
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'I. Aktiva Pos',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatCurrency(totalAktiva),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.textMain,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Kas Lapangan & Piutang',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textLight),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      Container(width: 1, height: 36, color: const Color(0xFFCBD5E1)),
                      const SizedBox(width: 12),

                      // Sisi Passiva
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.info,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'II. Passiva Pos',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatCurrency(totalPassiva),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.textMain,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Hutang & Alokasi Donasi',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textLight),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footer CTA Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        statusText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isBalanced ? AppTheme.income : AppTheme.warning,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Buka Rincian Pos',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNeracaDetailSheet() {
    final pos = _neracaData?['pos'] as Map<String, dynamic>?;
    final aktiva = _neracaData?['aktiva'] as Map<String, dynamic>?;
    final passiva = _neracaData?['passiva'] as Map<String, dynamic>?;
    final reconciliation = _neracaData?['reconciliation'] as Map<String, dynamic>?;

    final posName = pos?['name'] ?? _selectedCategory?.name ?? 'Pos Lapangan';
    final posCode = pos?['code'] ?? _selectedCategory?.code ?? '-';
    final picName = pos?['pic_name'] ?? 'Ainul Fais';
    final categoryType = (pos?['category_type'] == 'proyek_pembangunan')
        ? 'Proyek Pembangunan'
        : 'Non-Pembangunan / Operasional';

    final hartaLancar = (aktiva?['harta_lancar'] as List?) ?? [];
    final biayaOperasional = (aktiva?['biaya_operasional'] as List?) ?? [];
    final kewajiban = (passiva?['kewajiban'] as List?) ?? [];
    final sumberDana = (passiva?['sumber_dana'] as List?) ?? [];

    final totalAktiva = (aktiva?['total_aktiva'] ?? 0.0).toDouble();
    final totalPassiva = (passiva?['total_passiva'] ?? 0.0).toDouble();
    final isBalanced = reconciliation?['is_balanced'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Header with Close Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'NERACA DINAMIS POS LAPANGAN',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'NERACA: ${posName.toUpperCase()} ($posCode)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMain,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pondok Pesantren Annuqayah Latee • PJ: $picName ($categoryType)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Reconciliation Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isBalanced ? AppTheme.incomeBg : AppTheme.warningBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isBalanced ? AppTheme.income.withValues(alpha: 0.3) : AppTheme.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isBalanced ? Icons.verified_rounded : Icons.warning_amber_rounded,
                            color: isBalanced ? AppTheme.income : AppTheme.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Neraca Pos: $posName',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                Text(
                                  reconciliation?['status'] ?? (isBalanced ? 'SEIMBANG (KLOP)' : 'PERIKSA SELISIH'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isBalanced ? AppTheme.income : AppTheme.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: Color(0xFFF1F5F9), height: 16),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SISI I: AKTIVA
                          _buildNeracaSectionHeader('I. AKTIVA (KEKAYAAN & REALISASI BIAYA POS)', Icons.account_balance_rounded),
                          const SizedBox(height: 10),

                          // Sub A: Harta Lancar & Persediaan
                          _buildNeracaSubGroupHeader('A. Harta Lancar & Persediaan'),
                          if (hartaLancar.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: Text('(Belum ada catatan harta lancar)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                            )
                          else
                            ...hartaLancar.map((item) {
                              final code = item['code'] ?? '-';
                              final name = item['name'] ?? '-';
                              final amount = (item['amount'] ?? item['saldo'] ?? 0.0).toDouble();
                              return _buildNeracaRow('[$code] $name', Formatters.formatCurrency(amount));
                            }),

                          // Sub B: Realisasi Biaya
                          if (biayaOperasional.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildNeracaSubGroupHeader('B. Akumulasi Realisasi Biaya Pos'),
                            ...biayaOperasional.map((item) {
                              final code = item['code'] ?? '-';
                              final name = item['name'] ?? '-';
                              final amount = (item['amount'] ?? 0.0).toDouble();
                              return _buildNeracaRow('[$code] $name', Formatters.formatCurrency(amount));
                            }),
                          ],

                          _buildNeracaTotalRow('TOTAL AKTIVA POS', Formatters.formatCurrency(totalAktiva), AppTheme.primary),

                          const SizedBox(height: 24),

                          // SISI II: PASSIVA
                          _buildNeracaSectionHeader('II. PASSIVA (SUMBER DANA & KEWAJIBAN POS)', Icons.pie_chart_rounded),
                          const SizedBox(height: 10),

                          // Sub A: Kewajiban & Hutang
                          _buildNeracaSubGroupHeader('A. Kewajiban & Hutang Pos'),
                          if (kewajiban.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: Text('(Tidak ada kewajiban hutang)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                            )
                          else
                            ...kewajiban.map((item) {
                              final code = item['code'] ?? '-';
                              final name = item['name'] ?? '-';
                              final amount = (item['amount'] ?? 0.0).toDouble();
                              return _buildNeracaRow('[$code] $name', Formatters.formatCurrency(amount));
                            }),

                          const SizedBox(height: 12),

                          // Sub B: Sumber Dana
                          _buildNeracaSubGroupHeader('B. Sumber Dana & Alokasi Lembaga'),
                          if (sumberDana.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: Text('(Belum ada alokasi donasi)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                            )
                          else
                            ...sumberDana.map((item) {
                              final code = item['code'] ?? '-';
                              final name = item['name'] ?? '-';
                              final amount = (item['amount'] ?? 0.0).toDouble();
                              return _buildNeracaRow('[$code] $name', Formatters.formatCurrency(amount));
                            }),

                          _buildNeracaTotalRow('TOTAL PASSIVA POS', Formatters.formatCurrency(totalPassiva), AppTheme.info),

                          const SizedBox(height: 28),

                          // Lembar Pengesahan (Signatures)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PENGESAHAN LAPORAN NERACA POS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Penanggung Jawab Pos:', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textLight)),
                                        const SizedBox(height: 2),
                                        Text(
                                          picName,
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textMain),
                                        ),
                                        Text('Pengurus Lapangan', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Mengetahui:', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textLight)),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ainul Fais',
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textMain),
                                        ),
                                        Text('Auditor Internal Keuangan', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNeracaSubGroupHeader(String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryDark,
        ),
      ),
    );
  }

  Widget _buildNeracaSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textBody),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppTheme.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeracaRow(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeracaTotalRow(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : IndexedStack(
                index: _currentTabIndex,
                children: [
                  _buildHomeTab(),
                  TransactionsScreen(
                    apiService: widget.apiService,
                    categories: _categories,
                    selectedCategoryId: _selectedCategory?.id,
                    onRefreshNeeded: _loadDashboardData,
                  ),
                  MaterialScreen(
                    apiService: widget.apiService,
                    categories: _categories,
                    selectedCategoryId: _selectedCategory?.id,
                  ),
                  DebtScreen(
                    apiService: widget.apiService,
                    categories: _categories,
                    selectedCategoryId: _selectedCategory?.id,
                  ),
                  ProfileScreen(
                    authService: widget.authService,
                    apiService: widget.apiService,
                    categories: _categories,
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentTabIndex,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryLight,
          elevation: 0,
          onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
              label: 'Kas Pos',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: AppTheme.primary),
              label: 'Material',
            ),
            NavigationDestination(
              icon: Icon(Icons.handshake_outlined),
              selectedIcon: Icon(Icons.handshake_rounded, color: AppTheme.primary),
              label: 'Hutang',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
