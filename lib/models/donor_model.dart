class DonorModel {
  final int id;
  final String name;
  final String phone;
  final String address;
  final double totalDonasi;
  final int frekuensi;
  final String posBreakdown;

  DonorModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.totalDonasi,
    required this.frekuensi,
    required this.posBreakdown,
  });

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    return DonorModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '-',
      address: json['address'] ?? '-',
      totalDonasi: double.tryParse((json['total_donasi'] ?? 0).toString()) ?? 0.0,
      frekuensi: json['frekuensi'] is int ? json['frekuensi'] : int.tryParse(json['frekuensi']?.toString() ?? '0') ?? 0,
      posBreakdown: json['pos_breakdown'] ?? '-',
    );
  }
}
