class DebtTransactionModel {
  final int id;
  final int categoryId;
  final String posCode;
  final String posName;
  final String tanggal;
  final String type; // 'hutang_pinjam', 'hutang_bayar', 'piutang_pinjam', 'piutang_bayar'
  final String partyName;
  final double amount;
  final String? description;
  final String? buktiFoto;

  DebtTransactionModel({
    required this.id,
    required this.categoryId,
    required this.posCode,
    required this.posName,
    required this.tanggal,
    required this.type,
    required this.partyName,
    required this.amount,
    this.description,
    this.buktiFoto,
  });

  factory DebtTransactionModel.fromJson(Map<String, dynamic> json) {
    return DebtTransactionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id'].toString()) ?? 0,
      posCode: json['pos_code'] ?? '-',
      posName: json['pos_name'] ?? '-',
      tanggal: json['transaction_date'] ?? '-',
      type: json['type'] ?? 'hutang_pinjam',
      partyName: json['party_name'] ?? '-',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      description: json['description'],
      buktiFoto: json['bukti_foto'],
    );
  }

  bool get isHutang => type.startsWith('hutang');
}

class DebtPartyRecap {
  final String partyName;
  final double totalPinjam;
  final double totalBayar;
  final double saldo;

  DebtPartyRecap({
    required this.partyName,
    required this.totalPinjam,
    required this.totalBayar,
    required this.saldo,
  });

  factory DebtPartyRecap.fromJson(Map<String, dynamic> json) {
    return DebtPartyRecap(
      partyName: json['party_name'] ?? '-',
      totalPinjam: double.tryParse((json['total_pinjam'] ?? json['total_piutang'] ?? 0).toString()) ?? 0.0,
      totalBayar: double.tryParse((json['total_bayar'] ?? 0).toString()) ?? 0.0,
      saldo: double.tryParse((json['saldo'] ?? 0).toString()) ?? 0.0,
    );
  }
}
