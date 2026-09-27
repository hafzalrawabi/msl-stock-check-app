import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/branch.dart';
import '../models/dashboard_data.dart';
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://msl.rawabimarket.com/api';
  static void Function()? onSessionExpired;
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 35),
        receiveTimeout: const Duration(seconds: 35),
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
          final msg =
              '''
==================================== API REQUEST ====================================
--> ${options.method.toUpperCase()} ${options.baseUrl}${options.path}
Headers: ${options.headers}
QueryParams: ${options.queryParameters}
Body: ${options.data}
=====================================================================================''';
          debugPrint(msg);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final msg =
              '''
=================================== API RESPONSE ===================================
<-- ${response.statusCode} ${response.requestOptions.baseUrl}${response.requestOptions.path}
Response Data: ${response.data}
=====================================================================================''';
          debugPrint(msg);
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          final msg =
              '''
===================================== API ERROR =====================================
<-- ERROR ${error.response?.statusCode} ${error.requestOptions.baseUrl}${error.requestOptions.path}
Message: ${error.message}
Error Response Data: ${error.response?.data}
=====================================================================================''';
          debugPrint(msg);

          if (error.response?.statusCode == 401) {
            debugPrint(
              '[ApiService] Session expired (401 Unauthorized). Triggering logout.',
            );
            onSessionExpired?.call();
          }

          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Authentication
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
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
      final response = await _dio.get(
        '/branches',
        queryParameters: queryParams,
      );
      List rawList = [];
      if (response.data is List) {
        rawList = response.data;
      } else if (response.data is Map) {
        rawList =
            response.data['branches'] ??
            response.data['data'] ??
            response.data['outlets'] ??
            [];
      }
      debugPrint('[ApiService] Loaded ${rawList.length} branches');
      return rawList.map((e) => Branch.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiService] Error loading branches: $e');
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
      } else if (response.data is Map) {
        rawList =
            response.data['groups'] ??
            response.data['data'] ??
            response.data['branch_groups'] ??
            [];
      }
      debugPrint('[ApiService] Loaded ${rawList.length} branch groups');
      return rawList.map((e) => BranchGroup.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiService] Error loading branch groups: $e');
      return [];
    }
  }

  // Fetch Products
  Future<List<Product>> getProducts({
    int? branchId,
    String? search,
    String? brand,
    String? sortBy,
    int? limit = 100,
    int? page = 1,
    int? mslOnly = 1,
  }) async {
    try {
      String? cleanSort;
      if (sortBy != null && sortBy.isNotEmpty) {
        if (sortBy == 'Default (SL No.)' ||
            sortBy == 'Default' ||
            sortBy == 'Default (SL No)') {
          cleanSort = null;
        } else if (sortBy == 'A to Z') {
          cleanSort = 'name_asc';
        } else if (sortBy == 'Z to A') {
          cleanSort = 'name_desc';
        } else {
          cleanSort = sortBy;
        }
      }

      final queryParams =
          <String, dynamic>{
            'branchId': branchId,
            'search': search,
            'brand': brand == 'All Brands' || brand == 'All brands'
                ? null
                : brand,
            'sortBy': cleanSort,
            'page': page ?? 1,
            'limit': limit ?? 100,
            'mslOnly': mslOnly,
          }..removeWhere(
            (key, value) => value == null || (value is String && value.isEmpty),
          );
      final response = await _dio.get(
        '/products',
        queryParameters: queryParams,
      );
      List rawList = [];
      if (response.data is List) {
        rawList = response.data;
      } else if (response.data is Map) {
        rawList =
            response.data['products'] ??
            response.data['data'] ??
            response.data['items'] ??
            [];
      }
      debugPrint(
        '[ApiService] Loaded ${rawList.length} products for branch $branchId',
      );
      return rawList.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[ApiService] Error loading products: $e');
      return [];
    }
  }

  // GET /api/health - Check API health status
  Future<Map<String, dynamic>> getHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.data is Map<String, dynamic>
          ? response.data
          : {'status': 'ok'};
    } catch (_) {
      return {'status': 'offline'};
    }
  }

  // GET /api/branches/bootstrap - Branches and groups in one call
  Future<Map<String, dynamic>> getBranchesBootstrap() async {
    try {
      final response = await _dio.get('/branches/bootstrap');
      return response.data is Map<String, dynamic> ? response.data : {};
    } catch (_) {
      return {};
    }
  }

  // GET /api/products/bootstrap - Initial stock-check page data
  Future<Map<String, dynamic>> getProductsBootstrap({
    int? branchId,
    int limit = 25,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'branchId': branchId,
        'limit': limit,
        'sortBy': sortBy,
      }..removeWhere((key, value) => value == null);
      final response = await _dio.get(
        '/products/bootstrap',
        queryParameters: queryParams,
      );
      return response.data is Map<String, dynamic> ? response.data : {};
    } catch (_) {
      return {};
    }
  }

  // GET /api/products/matrix - Product x Branch matrix
  Future<List<dynamic>> getProductsMatrix() async {
    try {
      final response = await _dio.get('/products/matrix');
      return response.data is List ? response.data : [];
    } catch (_) {
      return [];
    }
  }

  // GET /api/products/template/bulk - Download bulk upload template
  String getProductsTemplateBulkUrl() {
    return '$baseUrl/products/template/bulk';
  }

  // GET /api/stock/check/:productId/:branchId/images - Images for a stock check
  Future<List<String>> getStockCheckImages(int productId, int branchId) async {
    try {
      final response = await _dio.get(
        '/stock/check/$productId/$branchId/images',
      );
      if (response.data is List) {
        return (response.data as List).map((e) => e.toString()).toList();
      } else if (response.data is Map && response.data['images'] is List) {
        return (response.data['images'] as List)
            .map((e) => e.toString())
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // POST /api/stock/check/:productId/:branchId/images - Upload image for stock check
  Future<bool> uploadStockCheckImage(
    int productId,
    int branchId,
    String imagePath,
  ) async {
    try {
      final fileName = imagePath.split('/').last.split('\\').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: fileName),
        'product_id': productId,
        'branch_id': branchId,
      });

      final response = await _dio.post(
        '/stock/check/$productId/$branchId/images',
        data: formData,
      );
      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          (response.data is Map && response.data['success'] == true);
    } catch (e) {
      debugPrint('[ApiService] Error uploading stock check image: $e');
      return false;
    }
  }

  // GET /api/stock/check/:productId/:branchId/detail - Stock-check detail (remarks, ERP stock)
  Future<Map<String, dynamic>> getStockCheckDetail(
    int productId,
    int branchId,
  ) async {
    try {
      final response = await _dio.get(
        '/stock/check/$productId/$branchId/detail',
      );
      return response.data is Map<String, dynamic> ? response.data : {};
    } catch (_) {
      return {};
    }
  }

  // GET /api/stock/branch/:branchId/summary - Branch stock summary
  Future<Map<String, dynamic>> getBranchStockSummary(int branchId) async {
    try {
      final response = await _dio.get('/stock/branch/$branchId/summary');
      return response.data is Map<String, dynamic> ? response.data : {};
    } catch (_) {
      return {};
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
    String? date,
    String? dateFrom,
    String? dateTo,
    String? brand,
    String? groupId,
    String? outletId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;
      if (brand != null && brand != 'All brands' && brand != 'All Brands')
        queryParams['brand'] = brand;
      if (groupId != null && groupId != 'All groups')
        queryParams['groupId'] = groupId;
      if (outletId != null && outletId != 'All outlets')
        queryParams['outletId'] = outletId;

      final response = await _dio.get(
        '/dashboard/updates',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => StockUpdateRecord.fromJson(e))
            .toList();
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
        'productId': productId,
        'branch_id': branchId,
        'branchId': branchId,
        'is_available': isAvailable,
        'isAvailable': isAvailable,
      };
      if (remarks != null && remarks.isNotEmpty) {
        data['remarks'] = remarks;
      }
      final response = await _dio.put('/stock/check', data: data);
      return response.statusCode == 200 ||
          (response.data is Map &&
              (response.data['success'] == true ||
                  response.data['id'] != null));
    } catch (e) {
      debugPrint('[ApiService] Error updating stock check: $e');
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
      final response = await _dio.post(
        '/products',
        data: {
          'sl_no': slNo,
          'barcode': barcode,
          'item_name': itemName,
          'brand': brand,
          'branch_ids': branchIds,
        },
      );
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

  // Export Stock Status Report from API (/api/export/stock-status)
  Future<List<int>?> exportStockStatusReport({
    int? branchId,
    String? search,
    String? brand,
    bool? mslOnly,
    String? mslStatus,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (branchId != null) queryParams['branchId'] = branchId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (brand != null && brand.isNotEmpty) queryParams['brand'] = brand;
      if (mslOnly == true) queryParams['mslOnly'] = 1;
      if (mslStatus != null && mslStatus.isNotEmpty)
        queryParams['mslStatus'] = mslStatus;

      final response = await _dio.get(
        '/export/stock-status',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        return List<int>.from(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] Error exporting stock status report: $e');
      return null;
    }
  }
}
