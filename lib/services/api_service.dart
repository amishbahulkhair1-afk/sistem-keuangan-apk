import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/material_model.dart';
import '../models/debt_model.dart';
import '../models/donor_model.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService authService;

  ApiService(this.authService);

  String get _baseUrl => authService.baseUrl;

  Map<String, String> get _headers {
    final map = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authService.token != null) {
      map['Authorization'] = 'Bearer ${authService.token}';
    }
    return map;
  }

  // --- AUTH ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/api/login');
    final response = await http.post(
      uri,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['token'] != null) {
      final user = UserModel.fromJson(data['user']);
      await authService.saveSession(data['token'], user);
      return {'success': true, 'user': user};
    } else {
      return {'success': false, 'message': data['detail'] ?? data['message'] ?? 'Login gagal'};
    }
  }

  // --- MASTER DATA ---
  Future<List<CategoryModel>> getCategories() async {
    final uri = Uri.parse('$_baseUrl/api/categories');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => CategoryModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final uri = Uri.parse('$_baseUrl/api/accounts');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final uri = Uri.parse('$_baseUrl/api/dashboard/stats');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  // --- TRANSAKSI DONASI & PUSAT ---
  Future<List<TransactionModel>> getTransactions({int? categoryId, int limit = 100, String? txType}) async {
    var query = 'limit=$limit';
    if (categoryId != null && categoryId > 0) query += '&category_id=$categoryId';
    if (txType != null) query += '&tx_type=$txType';

    final uri = Uri.parse('$_baseUrl/api/transactions?$query');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => TransactionModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> createTransaction({
    required String tanggal,
    required String jenis,
    required String metode,
    required int categoryId,
    required double nominal,
    String? keterangan,
    String? namaDonatur,
    String? photoPath,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/transactions');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
    });

    request.fields['tanggal'] = tanggal;
    request.fields['jenis'] = jenis;
    request.fields['metode'] = metode;
    request.fields['category_id'] = categoryId.toString();
    request.fields['nominal'] = nominal.toString();
    if (keterangan != null) request.fields['keterangan'] = keterangan;
    if (namaDonatur != null) request.fields['nama_donatur'] = namaDonatur;

    if (photoPath != null && File(photoPath).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_foto',
        photoPath,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final streamedResponse = await request.send();
    return streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201;
  }

  Future<bool> deleteTransaction(int id) async {
    final uri = Uri.parse('$_baseUrl/api/transactions/$id');
    final response = await http.delete(uri, headers: _headers);
    return response.statusCode == 200;
  }

  // --- KAS POS LAPANGAN ---
  Future<Map<String, dynamic>> getPosTransactions({int? categoryId, String? txType}) async {
    var query = '';
    if (categoryId != null && categoryId > 0) query += 'category_id=$categoryId';
    if (txType != null) query += query.isEmpty ? 'tx_type=$txType' : '&tx_type=$txType';

    final uri = Uri.parse('$_baseUrl/api/pos-transactions${query.isEmpty ? '' : '?$query'}');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List txList = data['transactions'] ?? [];
      return {
        'transactions': txList.map((e) => TransactionModel.fromJson(e)).toList(),
        'summary': data['summary'] ?? {},
      };
    }
    return {'transactions': <TransactionModel>[], 'summary': {}};
  }

  Future<bool> createPosTransaction({
    required int categoryId,
    required String transactionDate,
    required String type,
    String? categoryTxType,
    required double amount,
    String? recipientOrSender,
    String? description,
    String? photoPath,
    int? materialId,
    String? materialName,
    String? materialBrand,
    double? materialQuantity,
    double? materialPrice,
    String? materialUnit,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/pos-transactions');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
    });

    request.fields['category_id'] = categoryId.toString();
    request.fields['transaction_date'] = transactionDate;
    request.fields['type'] = type;
    request.fields['category_tx_type'] = categoryTxType ?? 'operasional_lapangan';
    request.fields['amount'] = amount.toString();
    if (recipientOrSender != null) request.fields['recipient_or_sender'] = recipientOrSender;
    if (description != null) request.fields['description'] = description;
    if (materialId != null) request.fields['material_id'] = materialId.toString();
    if (materialName != null) request.fields['material_name'] = materialName;
    if (materialBrand != null) request.fields['material_brand'] = materialBrand;
    if (materialQuantity != null) request.fields['material_quantity'] = materialQuantity.toString();
    if (materialPrice != null) request.fields['material_price'] = materialPrice.toString();
    if (materialUnit != null) request.fields['material_unit'] = materialUnit;

    if (photoPath != null && File(photoPath).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath('receipt_photo', photoPath));
    }

    final streamedResponse = await request.send();
    return streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201;
  }

  Future<bool> deletePosTransaction(int id) async {
    final uri = Uri.parse('$_baseUrl/api/pos-transactions/$id');
    final response = await http.delete(uri, headers: _headers);
    return response.statusCode == 200;
  }

  // --- MATERIAL / LOGISTIK ---
  Future<List<MaterialItemModel>> getMaterials({int? categoryId}) async {
    final query = (categoryId != null && categoryId > 0) ? '?category_id=$categoryId' : '';
    final uri = Uri.parse('$_baseUrl/api/materials$query');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['materials'] ?? [];
      return list.map((e) => MaterialItemModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<MaterialTransactionModel>> getMaterialTransactions({int? categoryId}) async {
    final query = (categoryId != null && categoryId > 0) ? '?category_id=$categoryId' : '';
    final uri = Uri.parse('$_baseUrl/api/materials/transactions$query');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => MaterialTransactionModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> createMaterialTransaction({
    required int materialId,
    required int categoryId,
    required String type, // 'masuk' / 'keluar'
    required double quantity,
    double? unitPrice,
    String? supplierOrSource,
    String? usageFor,
    String? photoPath,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/materials/transactions');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
    });

    request.fields['material_id'] = materialId.toString();
    request.fields['category_id'] = categoryId.toString();
    request.fields['type'] = type;
    request.fields['quantity'] = quantity.toString();
    if (unitPrice != null) request.fields['unit_price'] = unitPrice.toString();
    if (supplierOrSource != null) request.fields['supplier_or_source'] = supplierOrSource;
    if (usageFor != null) request.fields['usage_for'] = usageFor;

    if (photoPath != null && File(photoPath).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));
    }

    final streamedResponse = await request.send();
    return streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201;
  }

  // --- HUTANG & PIUTANG ---
  Future<List<DebtTransactionModel>> getDebts({int? categoryId, String? debtType}) async {
    var query = '';
    if (categoryId != null && categoryId > 0) query += 'category_id=$categoryId';
    if (debtType != null) query += query.isEmpty ? 'debt_type=$debtType' : '&debt_type=$debtType';

    final uri = Uri.parse('$_baseUrl/api/debts${query.isEmpty ? '' : '?$query'}');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => DebtTransactionModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getDebtsRecap({int? categoryId}) async {
    final query = (categoryId != null && categoryId > 0) ? '?category_id=$categoryId' : '';
    final uri = Uri.parse('$_baseUrl/api/debts/recap$query');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List hList = data['hutang_list'] ?? [];
      final List pList = data['piutang_list'] ?? [];
      return {
        'hutang_list': hList.map((e) => DebtPartyRecap.fromJson(e)).toList(),
        'piutang_list': pList.map((e) => DebtPartyRecap.fromJson(e)).toList(),
        'total_sisa_hutang': (data['total_sisa_hutang'] ?? 0).toDouble(),
        'total_sisa_piutang': (data['total_sisa_piutang'] ?? 0).toDouble(),
      };
    }
    return {
      'hutang_list': <DebtPartyRecap>[],
      'piutang_list': <DebtPartyRecap>[],
      'total_sisa_hutang': 0.0,
      'total_sisa_piutang': 0.0,
    };
  }

  Future<bool> createDebt({
    required int categoryId,
    required String type,
    required String partyName,
    required double amount,
    String? description,
    String? photoPath,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/debts');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
    });

    request.fields['category_id'] = categoryId.toString();
    request.fields['type'] = type;
    request.fields['party_name'] = partyName;
    request.fields['amount'] = amount.toString();
    if (description != null) request.fields['description'] = description;

    if (photoPath != null && File(photoPath).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath('receipt_photo', photoPath));
    }

    final streamedResponse = await request.send();
    return streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201;
  }

  // --- DONATUR CRM ---
  Future<List<DonorModel>> getDonors({String? search, String? pos}) async {
    var query = '';
    if (search != null && search.isNotEmpty) query += 'search=$search';
    if (pos != null && pos.isNotEmpty) query += query.isEmpty ? 'pos=$pos' : '&pos=$pos';

    final uri = Uri.parse('$_baseUrl/api/donors${query.isEmpty ? '' : '?$query'}');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => DonorModel.fromJson(e)).toList();
    }
    return [];
  }

  // --- REPORTS & NERACA ---
  Future<Map<String, dynamic>?> getPosBalanceSheet(int categoryId) async {
    final uri = Uri.parse('$_baseUrl/api/reports/neraca-pos/$categoryId');
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getConsolidatedBalanceSheet({int? year, int? month}) async {
    final query = <String, String>{};
    if (year != null) query['year'] = year.toString();
    if (month != null) query['month'] = month.toString();

    final queryString = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final uri = Uri.parse('$_baseUrl/api/reports/neraca$queryString');
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
