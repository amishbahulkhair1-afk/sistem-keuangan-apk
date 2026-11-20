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
    final list = await widget.apiService.getTransactions(
      categoryId: widget.selectedCategoryId,
      txType: txType,
      limit: 150,
    );
    if (!mounted) return;
    setState(() {
      _transactions = list;
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tx.isIncome ? AppTheme.incomeBg : AppTheme.expenseBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tx.isIncome ? 'Penerimaan / Donasi' : 'Pengeluaran / Belanja',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tx.isIncome ? AppTheme.income : AppTheme.expense,
                      ),
                    ),
                  ),
                  Text(
                    tx.tanggal,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
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
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9)),
              _buildDetailRow('Pihak Terkait', tx.donatur),
              _buildDetailRow('Pos Program', tx.posProgram),
              _buildDetailRow('Metode Akun', tx.metode),
              if (tx.keterangan != null && tx.keterangan!.isNotEmpty)
                _buildDetailRow('Keterangan', tx.keterangan!),
              if (tx.qrisReffId != null)
                _buildDetailRow('Ref QRIS', tx.qrisReffId!),

              if (tx.buktiFoto != null) ...[
                const SizedBox(height: 16),
                Text('Bukti Foto / Nota:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    '${widget.apiService.authService.baseUrl}${tx.buktiFoto}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => Container(
                      padding: const EdgeInsets.all(20),
                      color: AppTheme.surfaceMuted,
                      child: const Center(child: Text('(Gagal memuat gambar)')),
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
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.expenseBg,
                        foregroundColor: AppTheme.expense,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Hapus Transaksi?'),
                            content: const Text('Saldo kas pos terkait akan disesuaikan otomatis.'),
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
                          await widget.apiService.deleteTransaction(tx.id);
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
    return Scaffold(
      appBar: AppBar(
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
          // Quick Action Header: Catat Masuk & Catat Keluar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openFormTransaction('income'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.incomeBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.income.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, color: AppTheme.income, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Catat Masuk',
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
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.expenseBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.expense.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.expense, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Catat Keluar',
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.transparent,
            child: Row(
              children: [
                _buildFilterPill('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterPill('Masuk (Donasi)', 'income'),
                const SizedBox(width: 8),
                _buildFilterPill('Keluar (Belanja)', 'expense'),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                            '${tx.tanggal} • [${tx.posCode}]',
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
                                              Text(' Bukti', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.primary)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textMain : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.textMain : const Color(0xFFE2E8F0)),
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
