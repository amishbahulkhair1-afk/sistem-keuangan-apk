import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class FormTransactionScreen extends StatefulWidget {
  final ApiService apiService;
  final List<CategoryModel> categories;
  final int? initialCategoryId;
  final String initialType;

  const FormTransactionScreen({
    super.key,
    required this.apiService,
    required this.categories,
    this.initialCategoryId,
    this.initialType = 'income',
  });

  @override
  State<FormTransactionScreen> createState() => _FormTransactionScreenState();
}

class _FormTransactionScreenState extends State<FormTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _jenis;
  late int? _selectedCategoryId;
  String _metode = 'kas_tunai';
  final _nominalController = TextEditingController();
  final _namaPihakController = TextEditingController();
  final _keteranganController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _pickedImagePath;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _jenis = widget.initialType;
    _selectedCategoryId = widget.initialCategoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      setState(() {
        _pickedImagePath = file.path;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pos program terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final nominal = double.tryParse(_nominalController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final success = await widget.apiService.createTransaction(
      tanggal: dateStr,
      jenis: _jenis,
      metode: _metode,
      categoryId: _selectedCategoryId!,
      nominal: nominal,
      keterangan: _keteranganController.text.trim(),
      namaDonatur: _namaPihakController.text.trim(),
      photoPath: _pickedImagePath,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Transaksi berhasil dicatat ke sistem!'),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Gagal menyimpan transaksi'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _jenis == 'income';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isIncome ? 'Catat Kas Masuk (Donasi)' : 'Catat Kas Keluar (Belanja)',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modern Segmented Control
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _jenis = 'income'),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isIncome ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isIncome ? AppTheme.cardShadow : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.south_west_rounded, size: 16, color: isIncome ? AppTheme.income : AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Pemasukan (Masuk)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: isIncome ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 12,
                                    color: isIncome ? AppTheme.income : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _jenis = 'expense'),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isIncome ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: !isIncome ? AppTheme.cardShadow : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.north_east_rounded, size: 16, color: !isIncome ? AppTheme.expense : AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Pengeluaran (Keluar)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: !isIncome ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 12,
                                    color: !isIncome ? AppTheme.expense : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Container
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tanggal Selector Row
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tanggal Transaksi', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatDate(_selectedDate),
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textMain),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 22),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pos Program Selector
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Pos Program / Akun Proyek'),
                      items: widget.categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text('[${c.code}] ${c.name}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),

                    const SizedBox(height: 16),

                    // Nominal Field
                    TextFormField(
                      controller: _nominalController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                      decoration: const InputDecoration(
                        labelText: 'Nominal Transaksi (Rp)',
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Nominal wajib diisi';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Metode Akun Selector
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _metode,
                      decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                      items: const [
                        DropdownMenuItem(value: 'kas_tunai', child: Text('Kas Tunai Lapangan', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'bank_bni', child: Text('Transfer Bank (BNI / Rekening)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'piutang', child: Text('Talangan / Piutang', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) => setState(() => _metode = val ?? 'kas_tunai'),
                    ),

                    const SizedBox(height: 16),

                    // Nama Donatur / Penerima
                    TextFormField(
                      controller: _namaPihakController,
                      decoration: InputDecoration(
                        labelText: isIncome ? 'Nama Donatur / Pengirim' : 'Penerima Dana / Nama Toko',
                        hintText: isIncome ? 'Hamba Allah' : 'Toko Besi / Mandor Tukang',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Keterangan
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan Transaksi',
                        hintText: 'Misal: Beli 5 sak semen, konsumsi tukang',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lampiran Foto Bukti Nota
                    Text(
                      'Foto Bukti / Nota Transaksi',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 10),

                    if (_pickedImagePath != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_pickedImagePath!),
                              height: 170,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: InkWell(
                              onTap: () => setState(() => _pickedImagePath = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppTheme.primary),
                            label: Text('Kamera', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            onPressed: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppTheme.primary),
                            label: Text('Galeri', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            onPressed: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: isIncome ? AppTheme.primaryGradient : const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFE11D48)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.glowShadow(isIncome ? AppTheme.primary : AppTheme.expense),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _isLoading ? null : _submit,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Text(
                              'Simpan Transaksi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
