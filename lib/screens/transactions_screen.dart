import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'form_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final ApiService apiService;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final VoidCallback onRefreshNeeded;

  const TransactionsScreen({
    super.key,
    required this.apiService,
    required this.categories,
    this.selectedCategoryId,
    required this.onRefreshNeeded,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _fetchTransactions();
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    final txType = _selectedFilter == 'all' ? null : _selectedFilter;

    List<TransactionModel> combined = [];
    if (widget.selectedCategoryId != null) {
      final posRes = await widget.apiService.getPosTransactions(
        categoryId: widget.selectedCategoryId,
        txType: txType,
      );
      final List<TransactionModel> posList = (posRes['transactions'] as List<TransactionModel>?) ?? [];
      combined.addAll(posList);
    }

    final list = await widget.apiService.getTransactions(
      categoryId: widget.selectedCategoryId,
      txType: txType,
      limit: 150,
    );
    combined.addAll(list);
    combined.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    if (!mounted) return;
    setState(() {
      _transactions = combined;
      _isLoading = false;
    });
  }

  void _showDetailSheet(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: tx.isIncome ? AppTheme.incomeBg : AppTheme.expenseBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tx.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          size: 14,
                          color: tx.isIncome ? AppTheme.income : AppTheme.expense,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tx.isIncome ? 'Kas Masuk / Donasi' : 'Kas Keluar / Belanja',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tx.isIncome ? AppTheme.income : AppTheme.expense,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    tx.tanggal,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${tx.isIncome ? '+' : '-'} ${Formatters.formatCurrency(tx.nominal)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: tx.isIncome ? AppTheme.income : AppTheme.expense,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFF1F5F9)),
              _buildDetailRow('Pihak / Donatur', tx.donatur),
              _buildDetailRow('Pos Program', tx.posProgram),
              _buildDetailRow('Metode / Jenis', tx.metode),
              if (tx.keterangan != null && tx.keterangan!.isNotEmpty)
                _buildDetailRow('Keterangan', tx.keterangan!),
              if (tx.qrisReffId != null)
                _buildDetailRow('Ref QRIS', tx.qrisReffId!),

              if (tx.buktiFoto != null) ...[
                const SizedBox(height: 16),
                Text('Lampiran Bukti / Nota:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    '${widget.apiService.authService.baseUrl}${tx.buktiFoto}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (ctx, error, stackTrace) => Container(
                      height: 100,
                      decoration: BoxDecoration(color: AppTheme.surfaceMuted, borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Text('Foto tidak dapat dimuat', style: TextStyle(color: AppTheme.textMuted))),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: AppTheme.expense.withValues(alpha: 0.3)),
                        foregroundColor: AppTheme.expense,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Hapus Transaksi?'),
                            content: const Text('Apakah Anda yakin ingin membatalkan dan menghapus transaksi ini?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expense, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          Navigator.pop(ctx);
                          await widget.apiService.deleteTransaction(tx.id);
                          await widget.apiService.deletePosTransaction(tx.id);
                          _fetchTransactions();
                          widget.onRefreshNeeded();
                        }
                      },
                      child: const Text('Hapus Transaksi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain),
            ),
          ),
        ],
      ),
    );
  }

  void _openFormTransaction(String jenis) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => FormTransactionScreen(
          apiService: widget.apiService,
          categories: widget.categories,
          initialCategoryId: widget.selectedCategoryId,
          initialType: jenis,
        ),
      ),
    );

    if (result == true) {
      _fetchTransactions();
      widget.onRefreshNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCat = widget.categories.firstWhere(
      (c) => c.id == widget.selectedCategoryId,
      orElse: () => widget.categories.isNotEmpty ? widget.categories.first : CategoryModel(id: 0, code: '-', name: 'Semua Pos'),
    );

    final totalIn = _transactions.where((t) => t.isIncome).fold<double>(0.0, (s, t) => s + t.nominal);
    final totalOut = _transactions.where((t) => !t.isIncome).fold<double>(0.0, (s, t) => s + t.nominal);
    final netBalance = totalIn - totalOut;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Jurnal Kas & Transaksi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Pos Header Banner & Financial Metric Row
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Pos: [${currentCat.code}] ${currentCat.name}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_transactions.length} Data',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Masuk', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(totalIn),
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.income),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Keluar', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(totalOut),
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.expense),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saldo Bersih', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(netBalance),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: netBalance >= 0 ? AppTheme.primary : AppTheme.expense,
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

          // Action Buttons: Catat Masuk & Catat Keluar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openFormTransaction('income'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.incomeBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.income.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_downward_rounded, color: AppTheme.income, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Catat Kas Masuk',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.income,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _openFormTransaction('expense'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.expenseBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.expense.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_upward_rounded, color: AppTheme.expense, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Catat Kas Keluar',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.expense,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.transparent,
            child: Row(
              children: [
                _buildFilterPill('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterPill('Kas Masuk', 'income'),
                const SizedBox(width: 8),
                _buildFilterPill('Kas Keluar', 'expense'),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 48, color: AppTheme.textLight.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada transaksi di pos ini',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _fetchTransactions,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                          itemCount: _transactions.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
                            final isIncome = tx.isIncome;

                            return InkWell(
                              onTap: () => _showDetailSheet(tx),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFE5EBF2)),
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
                                        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                        color: isIncome ? AppTheme.income : AppTheme.expense,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
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
                                          const SizedBox(height: 3),
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
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isIncome ? '+' : '-'} ${Formatters.formatCurrency(tx.nominal)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: isIncome ? AppTheme.income : AppTheme.expense,
                                          ),
                                        ),
                                        if (tx.buktiFoto != null) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.attach_file_rounded, size: 12, color: AppTheme.primary),
                                              Text(' Nota', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = value);
        _fetchTransactions();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
          boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.primary) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textBody,
          ),
        ),
      ),
    );
  }
}
