import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/debt_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class DebtScreen extends StatefulWidget {
  final ApiService apiService;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;

  const DebtScreen({
    super.key,
    required this.apiService,
    required this.categories,
    this.selectedCategoryId,
  });

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DebtPartyRecap> _hutangList = [];
  List<DebtPartyRecap> _piutangList = [];
  List<DebtTransactionModel> _transactions = [];
  double _totalHutang = 0.0;
  double _totalPiutang = 0.0;
  bool _isLoading = true;
  String _searchQuery = '';
  String _txFilter = 'all'; // 'all', 'hutang', 'piutang'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DebtScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final recap = await widget.apiService.getDebtsRecap(categoryId: widget.selectedCategoryId);
    final txs = await widget.apiService.getDebts(categoryId: widget.selectedCategoryId);
    if (!mounted) return;
    setState(() {
      _hutangList = recap['hutang_list'] ?? [];
      _piutangList = recap['piutang_list'] ?? [];
      _totalHutang = recap['total_sisa_hutang'] ?? 0.0;
      _totalPiutang = recap['total_sisa_piutang'] ?? 0.0;
      _transactions = txs;
      _isLoading = false;
    });
  }

  void _showAddDebtDialog({String? initialType, String? initialPartyName}) {
    String type = initialType ?? 'hutang_pinjam';
    final partyController = TextEditingController(text: initialPartyName ?? '');
    final amountController = TextEditingController();
    final descController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Catat Hutang / Piutang',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: type,
                  decoration: InputDecoration(
                    labelText: 'Jenis Transaksi',
                    prefixIcon: const Icon(Icons.swap_horiz_rounded, size: 20, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'hutang_pinjam', child: Text('Hutang Baru (Pinjam ke Pihak Luar)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'hutang_bayar', child: Text('Bayar Hutang (Pelunasan ke Pihak Luar)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'piutang_pinjam', child: Text('Piutang Baru (Pinjamkan ke Pihak Lain)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'piutang_bayar', child: Text('Terima Piutang (Pihak Lain Membayar)', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => type = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: partyController,
                  decoration: InputDecoration(
                    labelText: 'Nama Pihak / Toko / Person',
                    hintText: 'Misal: Toko Berkah / Mandor Syarif',
                    prefixIcon: const Icon(Icons.store_mall_directory_rounded, size: 20, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Nominal Transaksi (Rp)',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.payments_rounded, size: 20, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Keterangan Tambahan',
                    hintText: 'Misal: Talangan belanja semen 50 sak',
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.glowShadow(AppTheme.primary),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isSubmitting
                          ? null
                          : () async {
                              final amount = double.tryParse(amountController.text) ?? 0.0;
                              if (amount <= 0 || partyController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Lengkapi nama pihak dan nominal yang valid')),
                                );
                                return;
                              }

                              setDialogState(() => isSubmitting = true);
                              final success = await widget.apiService.createDebt(
                                categoryId: widget.selectedCategoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : 1),
                                type: type,
                                partyName: partyController.text.trim(),
                                amount: amount,
                                description: descController.text.trim(),
                              );

                              if (!mounted) return;
                              Navigator.pop(ctx);

                              if (success) {
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    content: const Text('Transaksi hutang/piutang berhasil disimpan!'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppTheme.expense,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    content: const Text('Gagal menyimpan transaksi'),
                                  ),
                                );
                              }
                            },
                      child: Center(
                        child: isSubmitting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text(
                                'Simpan Transaksi',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProofDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Container(
                    height: 180,
                    color: AppTheme.surfaceMuted,
                    child: const Center(child: Text('Foto bukti tidak dapat dimuat')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCat = widget.categories.firstWhere(
      (c) => c.id == widget.selectedCategoryId,
      orElse: () => widget.categories.isNotEmpty ? widget.categories.first : CategoryModel(id: 0, code: '-', name: 'Semua Pos'),
    );

    final filteredHutang = _hutangList.where((h) {
      if (_searchQuery.isEmpty) return true;
      return h.partyName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredPiutang = _piutangList.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.partyName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredTransactions = _transactions.where((t) {
      if (_txFilter == 'hutang') return t.isHutang;
      if (_txFilter == 'piutang') return !t.isHutang;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hutang & Piutang Pos',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Catat Transaksi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
        onPressed: () => _showAddDebtDialog(),
      ),
      body: Column(
        children: [
          // Pos Header Banner
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.handshake_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Pos: [${currentCat.code}] ${currentCat.name}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Text(
                      '${_hutangList.length + _piutangList.length} Pihak Terdaftar',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.expenseBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.expense.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kewajiban Hutang', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(
                              Formatters.formatCurrency(_totalHutang),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.expense,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.incomeBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.income.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hak Piutang', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(
                              Formatters.formatCurrency(_totalPiutang),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.income,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Modern Segmented Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              labelColor: AppTheme.textMain,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                Tab(text: 'Rekap Pihak (${_hutangList.length + _piutangList.length})'),
                Tab(text: 'Riwayat Transaksi (${_transactions.length})'),
              ],
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Tab Rekap Pihak
                      _buildRecapTab(filteredHutang, filteredPiutang),

                      // 2. Tab Riwayat Transaksi
                      _buildHistoryTab(filteredTransactions),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapTab(List<DebtPartyRecap> hutangList, List<DebtPartyRecap> piutangList) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5EBF2)),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari nama pihak / toko...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textLight),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Section 1: Kewajiban Hutang Lapangan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kewajiban Hutang (Pos Meminjam)',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textMain),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.expenseBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '${hutangList.length} Pihak',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.expense),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hutangList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5EBF2)),
                ),
                child: Center(
                  child: Text('Tidak ada kewajiban hutang aktif', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12)),
                ),
              )
            else
              ...hutangList.map((h) => _buildPartyCard(
                    party: h,
                    isHutang: true,
                    onAction: () => _showAddDebtDialog(initialType: 'hutang_bayar', initialPartyName: h.partyName),
                  )),

            const SizedBox(height: 24),

            // Section 2: Hak Piutang Lapangan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hak Piutang (Dipinjam Pihak Luar)',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textMain),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.incomeBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '${piutangList.length} Pihak',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.income),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (piutangList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5EBF2)),
                ),
                child: Center(
                  child: Text('Tidak ada hak piutang aktif', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12)),
                ),
              )
            else
              ...piutangList.map((p) => _buildPartyCard(
                    party: p,
                    isHutang: false,
                    onAction: () => _showAddDebtDialog(initialType: 'piutang_bayar', initialPartyName: p.partyName),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyCard({
    required DebtPartyRecap party,
    required bool isHutang,
    required VoidCallback onAction,
  }) {
    final double paidRatio = party.totalPinjam > 0 ? (party.totalBayar / party.totalPinjam).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isHutang ? AppTheme.expenseBg : AppTheme.incomeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    party.partyName.isNotEmpty ? party.partyName[0].toUpperCase() : 'P',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isHutang ? AppTheme.expense : AppTheme.income,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.partyName,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHutang
                          ? 'Total Pinjam: ${Formatters.formatCurrency(party.totalPinjam)}'
                          : 'Total Dipinjamkan: ${Formatters.formatCurrency(party.totalPinjam)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sisa Saldo',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted),
                  ),
                  Text(
                    Formatters.formatCurrency(party.saldo),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isHutang ? AppTheme.expense : AppTheme.income,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar of repayment
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: paidRatio,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                isHutang ? AppTheme.expense : AppTheme.income,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sudah Dibayar: ${Formatters.formatCurrency(party.totalBayar)} (${(paidRatio * 100).toStringAsFixed(0)}%)',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isHutang ? AppTheme.expenseBg : AppTheme.incomeBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isHutang ? AppTheme.expense.withValues(alpha: 0.2) : AppTheme.income.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isHutang ? Icons.payment_rounded : Icons.move_to_inbox_rounded,
                        size: 13,
                        color: isHutang ? AppTheme.expense : AppTheme.income,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isHutang ? 'Bayar / Lunasi' : 'Terima Bayar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isHutang ? AppTheme.expense : AppTheme.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(List<DebtTransactionModel> list) {
    return Column(
      children: [
        // Filter Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildTxFilterPill('Semua', 'all'),
              const SizedBox(width: 8),
              _buildTxFilterPill('Hutang', 'hutang'),
              const SizedBox(width: 8),
              _buildTxFilterPill('Piutang', 'piutang'),
            ],
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_edu_rounded, size: 48, color: AppTheme.textLight.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('Belum ada transaksi hutang/piutang', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                    itemCount: list.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = list[index];
                      final isHutang = tx.isHutang;
                      final isBayar = tx.type.endsWith('bayar');

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isHutang ? AppTheme.expenseBg : AppTheme.incomeBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isHutang ? Icons.money_off_rounded : Icons.attach_money_rounded,
                                color: isHutang ? AppTheme.expense : AppTheme.income,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.partyName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppTheme.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatDebtType(tx.type)}${tx.description != null && tx.description!.isNotEmpty ? " • ${tx.description}" : ""}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatCurrency(tx.amount),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isBayar ? AppTheme.income : AppTheme.expense,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tx.tanggal,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                                    ),
                                    if (tx.buktiFoto != null && tx.buktiFoto!.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => _showProofDialog('${widget.apiService.authService.baseUrl}${tx.buktiFoto}', tx.partyName),
                                        child: const Icon(Icons.receipt_rounded, size: 12, color: AppTheme.primary),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _formatDebtType(String type) {
    switch (type) {
      case 'hutang_pinjam':
        return 'Pinjaman Baru';
      case 'hutang_bayar':
        return 'Pelunasan Hutang';
      case 'piutang_pinjam':
        return 'Pinjamkan Dana';
      case 'piutang_bayar':
        return 'Penerimaan Piutang';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildTxFilterPill(String label, String value) {
    final isSelected = _txFilter == value;
    return InkWell(
      onTap: () => setState(() => _txFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
          boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.primary) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textBody,
          ),
        ),
      ),
    );
  }
}
