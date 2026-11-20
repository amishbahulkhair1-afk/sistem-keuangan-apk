class TransactionModel {
  final int id;
  final String tanggal;
  final String jenis; // 'income' / 'expense'
  final int categoryId;
  final String posProgram;
  final String posCode;
  final String metode;
  final String donatur;
  final double nominal;
  final String? keterangan;
  final String? buktiFoto;
  final String? qrisReffId;

  TransactionModel({
    required this.id,
    required this.tanggal,
    required this.jenis,
    required this.categoryId,
    required this.posProgram,
    required this.posCode,
    required this.metode,
    required this.donatur,
    required this.nominal,
    this.keterangan,
    this.buktiFoto,
    this.qrisReffId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      tanggal: json['tanggal'] ?? json['transaction_date'] ?? '-',
      jenis: json['jenis'] ?? json['type'] ?? 'income',
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id'].toString()) ?? 0,
      posProgram: json['pos_program'] ?? json['pos_name'] ?? '-',
      posCode: json['pos_code'] ?? '-',
      metode: json['metode'] ?? json['category_tx_type'] ?? '-',
      donatur: json['donatur'] ?? json['recipient_or_sender'] ?? '-',
      nominal: json['nominal'] != null
          ? double.tryParse(json['nominal'].toString()) ?? 0.0
          : (double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0),
      keterangan: json['keterangan'] ?? json['description'],
      buktiFoto: json['bukti_foto'],
      qrisReffId: json['qris_reff_id'],
    );
  }

  bool get isIncome => jenis == 'income' || jenis == 'masuk';
}
