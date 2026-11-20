class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String accessLevel;
  final int? assignedCategoryId;
  final List<int> assignedCategories;
  final String? assignedCategoryCode;
  final String? assignedCategoryName;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.accessLevel,
    this.assignedCategoryId,
    this.assignedCategories = const [],
    this.assignedCategoryCode,
    this.assignedCategoryName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<int> cats = [];
    if (json['assigned_categories'] != null) {
      if (json['assigned_categories'] is List) {
        cats = (json['assigned_categories'] as List)
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
      }
    } else if (json['assigned_category_id'] != null) {
      cats = [int.tryParse(json['assigned_category_id'].toString()) ?? 0];
    }

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'petugas_lapangan',
      accessLevel: json['access_level'] ?? 'full',
      assignedCategoryId: json['assigned_category_id'] != null
          ? int.tryParse(json['assigned_category_id'].toString())
          : null,
      assignedCategories: cats,
      assignedCategoryCode: json['assigned_category_code'],
      assignedCategoryName: json['assigned_category_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'access_level': accessLevel,
      'assigned_category_id': assignedCategoryId,
      'assigned_categories': assignedCategories,
      'assigned_category_code': assignedCategoryCode,
      'assigned_category_name': assignedCategoryName,
    };
  }

  bool get isAdmin => role == 'admin_keuangan';
  bool get isPimpinan => role == 'pimpinan';
  bool get isPetugasLapangan => role == 'petugas_lapangan';
}
