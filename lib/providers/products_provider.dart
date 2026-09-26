import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    _products = await _apiService.getProducts(
      search: _searchQuery,
      limit: 1580,
    );

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProducts();
  }

  Future<bool> addProduct({
    required int slNo,
    required String barcode,
    required String itemName,
    required String brand,
    required List<int> branchIds,
  }) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.addProduct(
      slNo: slNo,
      barcode: barcode,
      itemName: itemName,
      brand: brand,
      branchIds: branchIds,
    );

    if (success) {
      await loadProducts();
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteProduct(int productId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.deleteProduct(productId);
    if (success) {
      _products.removeWhere((p) => p.id == productId);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
