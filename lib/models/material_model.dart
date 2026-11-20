class MaterialItemModel {
  final int id;
  final int categoryId;
  final String posCode;
  final String posName;
  final String code;
  final String name;
  final String unit;
  final double unitPrice;
  final double initialStock;
  final double totalMasuk;
  final double totalKeluar;
  final double currentStock;
  final double totalValue;

  MaterialItemModel({
    required this.id,
    required this.categoryId,
    required this.posCode,
    required this.posName,
    required this.code,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.initialStock,
    required this.totalMasuk,
    required this.totalKeluar,
    required this.currentStock,
    required this.totalValue,
  });

  factory MaterialItemModel.fromJson(Map<String, dynamic> json) {
    return MaterialItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id'].toString()) ?? 0,
      posCode: json['pos_code'] ?? '-',
      posName: json['pos_name'] ?? '-',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? 'Pcs',
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      initialStock: double.tryParse(json['initial_stock']?.toString() ?? '0') ?? 0.0,
      totalMasuk: double.tryParse(json['total_masuk']?.toString() ?? '0') ?? 0.0,
      totalKeluar: double.tryParse(json['total_keluar']?.toString() ?? '0') ?? 0.0,
      currentStock: double.tryParse(json['current_stock']?.toString() ?? '0') ?? 0.0,
      totalValue: double.tryParse(json['total_value']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class MaterialTransactionModel {
  final int id;
  final int materialId;
  final String materialName;
  final String unit;
  final int categoryId;
  final String posName;
  final String tanggal;
  final String type; // 'masuk' / 'keluar'
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? supplierOrSource;
  final String? usageFor;
  final String? buktiFoto;

  MaterialTransactionModel({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.categoryId,
    required this.posName,
    required this.tanggal,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.supplierOrSource,
    this.usageFor,
    this.buktiFoto,
  });

  factory MaterialTransactionModel.fromJson(Map<String, dynamic> json) {
    return MaterialTransactionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      materialId: json['material_id'] is int ? json['material_id'] : int.tryParse(json['material_id'].toString()) ?? 0,
      materialName: json['material_name'] ?? '-',
      unit: json['unit'] ?? 'Pcs',
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id'].toString()) ?? 0,
      posName: json['pos_name'] ?? '-',
      tanggal: json['transaction_date'] ?? '-',
      type: json['type'] ?? 'masuk',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      supplierOrSource: json['supplier_or_source'],
      usageFor: json['usage_for'],
      buktiFoto: json['bukti_foto'],
    );
  }

  bool get isMasuk => type == 'masuk';
}
