import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/branch.dart';
import '../models/dashboard_data.dart';
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://msl.rawabimarket.com/api';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Log or handle error globally
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Authentication
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return e.response?.data;
      }
      throw Exception(e.message ?? 'Login failed');
    }
  }

  // Fetch Dashboard Summary
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final response = await _dio.get('/dashboard/summary');
      if (response.data is Map<String, dynamic>) {
        return DashboardSummary.fromJson(response.data);
      }
      return DashboardSummary();
    } catch (_) {
      return DashboardSummary();
    }
  }

  // Fetch Branches
  Future<List<Branch>> getBranches({int? groupId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (groupId != null) {
        queryParams['groupId'] = groupId;
      }
      final response = await _dio.get('/branches', queryParameters: queryParams);
      List rawList = [];
      if (response.data is List) {
        rawList = response.data;
      } else if (response.data is Map && response.data['branches'] != null) {
        rawList = response.data['branches'];
      }
      return rawList.map((e) => Branch.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // Fetch Branch Groups
  Future<List<BranchGroup>> getBranchGroups() async {
    try {
      final response = await _dio.get('/branches/groups');
      List rawList = [];
      if (response.data is List) {
        rawList = response.data;
      }
      return rawList.map((e) => BranchGroup.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // Fetch Products
  Future<List<Product>> getProducts({
    int? branchId,
    String? search,
    String? brand,
    String? sortBy,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'branchId': branchId,
        'search': search,
        'brand': brand == 'All Brands' || brand == 'All brands' ? null : brand,
        'sortBy': sortBy,
        'limit': limit,
      }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));
      final response = await _dio.get('/products', queryParameters: queryParams);
      List rawList = [];
      if (response.data is List) {
        rawList = response.data;
      } else if (response.data is Map && response.data['products'] != null) {
        rawList = response.data['products'];
      }
      return rawList.map((e) => Product.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // Fetch Brands List
  Future<List<String>> getBrands() async {
    try {
      final response = await _dio.get('/products/brands');
      if (response.data is List) {
        return (response.data as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Fetch Dashboard Updates
  Future<List<StockUpdateRecord>> getDashboardUpdates({
    String? dateFrom,
    String? dateTo,
    String? brand,
    String? groupId,
    String? outletId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;
      if (brand != null && brand != 'All brands' && brand != 'All Brands') queryParams['brand'] = brand;
      if (groupId != null && groupId != 'All groups') queryParams['groupId'] = groupId;
      if (outletId != null && outletId != 'All outlets') queryParams['outletId'] = outletId;

      final response = await _dio.get('/dashboard/updates', queryParameters: queryParams);
      if (response.data is List) {
        return (response.data as List).map((e) => StockUpdateRecord.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Update Stock Check
  Future<bool> updateStockCheck({
    required int productId,
    required int branchId,
    required bool isAvailable,
    String? remarks,
  }) async {
    try {
      final data = <String, dynamic>{
        'product_id': productId,
        'branch_id': branchId,
        'is_available': isAvailable,
      };
      if (remarks != null) {
        data['remarks'] = remarks;
      }
      final response = await _dio.put('/stock/check', data: data);
      return response.statusCode == 200 || response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // Submit Stock Check (alias for updateStockCheck)
  Future<bool> submitStockCheck({
    required int productId,
    required int branchId,
    required bool isAvailable,
    String? remarks,
  }) {
    return updateStockCheck(
      productId: productId,
      branchId: branchId,
      isAvailable: isAvailable,
      remarks: remarks,
    );
  }

  // Add New Product
  Future<bool> addProduct({
    required int slNo,
    required String barcode,
    required String itemName,
    required String brand,
    required List<int> branchIds,
  }) async {
    try {
      final response = await _dio.post('/products', data: {
        'sl_no': slNo,
        'barcode': barcode,
        'item_name': itemName,
        'brand': brand,
        'branch_ids': branchIds,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // Delete Product
  Future<bool> deleteProduct(int productId) async {
    try {
      final response = await _dio.delete('/products/$productId');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

