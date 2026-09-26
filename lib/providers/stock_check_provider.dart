import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class StockCheckProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<BranchGroup> _groups = [];
  List<Branch> _branches = [];
  BranchGroup? _selectedGroup;
  Branch? _selectedBranch;

  List<Product> _products = [];
  List<String> _brands = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedBrand = 'All Brands';
  String _selectedSortBy = 'Default (SL No.)';

  // Dirty state tracking (modified items pending save)
  final Map<int, bool> _pendingUpdates = {}; // productId -> isAvailable
  final Map<int, String> _pendingRemarks = {}; // productId -> remarks

  List<BranchGroup> get groups => _groups;
  List<Branch> get branches => _branches;
  BranchGroup? get selectedGroup => _selectedGroup;
  Branch? get selectedBranch => _selectedBranch;

  List<Product> get products => _products;
  List<String> get brands => _brands;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  String get selectedSortBy => _selectedSortBy;
  bool get hasPendingChanges => _pendingUpdates.isNotEmpty || _pendingRemarks.isNotEmpty;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _groups = await _apiService.getBranchGroups();
    _brands = await _apiService.getBrands();

    if (_groups.isNotEmpty) {
      _selectedGroup = _groups.firstWhere((g) => g.name == 'Saudia Group', orElse: () => _groups.first);
      await loadBranchesForGroup(_selectedGroup!);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectGroup(BranchGroup group) async {
    if (_selectedGroup?.id == group.id) return;
    _selectedGroup = group;
    await loadBranchesForGroup(group);
  }

  Future<void> loadBranchesForGroup(BranchGroup group) async {
    _isLoading = true;
    notifyListeners();

    _branches = await _apiService.getBranches(groupId: group.id);
    if (_branches.isNotEmpty) {
      _selectedBranch = _branches.firstWhere(
        (b) => b.name == 'SAUDI MAITHER',
        orElse: () => _branches.first,
      );
    } else {
      _selectedBranch = null;
    }

    await loadProducts();
  }

  Future<void> selectBranch(Branch branch) async {
    if (_selectedBranch?.id == branch.id) return;
    _selectedBranch = branch;
    await loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    _products = await _apiService.getProducts(
      branchId: _selectedBranch?.id,
      search: _searchQuery,
      brand: _selectedBrand,
      sortBy: _selectedSortBy,
    );

    // Apply pending local edits
    for (var i = 0; i < _products.length; i++) {
      final pid = _products[i].id;
      if (_pendingUpdates.containsKey(pid)) {
        _products[i].isAvailable = _pendingUpdates[pid];
      }
      if (_pendingRemarks.containsKey(pid)) {
        _products[i].remarks = _pendingRemarks[pid];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProducts();
  }

  void applyFilters({required String brand, required String sortBy}) {
    _selectedBrand = brand;
    _selectedSortBy = sortBy;
    loadProducts();
  }

  void resetFilters() {
    _selectedBrand = 'All Brands';
    _selectedSortBy = 'Default (SL No.)';
    _searchQuery = '';
    loadProducts();
  }

  void toggleAvailability(Product product, bool isAvailable) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index].isAvailable = isAvailable;
      _pendingUpdates[product.id] = isAvailable;
      notifyListeners();
    }
  }

  void updateRemarks(Product product, String remarks) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index].remarks = remarks;
      _pendingRemarks[product.id] = remarks;
      notifyListeners();
    }
  }

  void searchByBarcode(String barcode) {
    _searchQuery = barcode;
    loadProducts();
  }

  Future<bool> saveAllChanges() async {
    if (_selectedBranch == null) return false;

    _isLoading = true;
    notifyListeners();

    bool success = true;

    for (final entry in _pendingUpdates.entries) {
      final productId = entry.key;
      final isAvailable = entry.value;
      final remarks = _pendingRemarks[productId];

      final result = await _apiService.submitStockCheck(
        productId: productId,
        branchId: _selectedBranch!.id,
        isAvailable: isAvailable,
        remarks: remarks,
      );

      if (!result) success = false;
    }

    _pendingUpdates.clear();
    _pendingRemarks.clear();

    await loadProducts();
    return success;
  }

  void discardChanges() {
    _pendingUpdates.clear();
    _pendingRemarks.clear();
    loadProducts();
  }
}
