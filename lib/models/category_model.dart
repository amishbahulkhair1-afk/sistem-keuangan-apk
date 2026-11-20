class CategoryModel {
  final int id;
  final String code;
  final String name;
  final String? qrisUnitDigit;
  final String categoryType;
  final String? picName;
  final String? description;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.code,
    required this.name,
    this.qrisUnitDigit,
    this.categoryType = 'proyek_pembangunan',
    this.picName,
    this.description,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      qrisUnitDigit: json['qris_unit_digit']?.toString(),
      categoryType: json['category_type'] ?? 'proyek_pembangunan',
      picName: json['pic_name'],
      description: json['description'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  String get displayName => '[$code] $name';
}
