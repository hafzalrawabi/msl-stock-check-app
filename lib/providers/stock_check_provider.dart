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

    debugPrint('\n[StockCheckProvider] Fetching initial groups and brands...');
    _groups = await _apiService.getBranchGroups();
    _brands = await _apiService.getBrands();
    debugPrint('[StockCheckProvider] Loaded ${_groups.length} groups and ${_brands.length} brands.');

    if (_groups.isNotEmpty) {
      _selectedGroup = _groups.first;
      await loadBranchesForGroup(_selectedGroup!);
    }
  }

  Future<void> selectGroup(BranchGroup group) async {
    if (_selectedGroup?.id == group.id) return;
    _selectedGroup = group;
    await loadBranchesForGroup(group);
  }

  Future<void> loadBranchesForGroup(BranchGroup group) async {
    _isLoading = true;
    notifyListeners();

    debugPrint('[StockCheckProvider] Loading branches for Group ID: ${group.id} (${group.name})...');
    _branches = await _apiService.getBranches(groupId: group.id);
    debugPrint('[StockCheckProvider] Loaded ${_branches.length} branches.');

    if (_branches.isNotEmpty) {
      _selectedBranch = _branches.first;
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

    debugPrint('[StockCheckProvider] Loading products for Branch ID: ${_selectedBranch?.id} (${_selectedBranch?.name})...');
    debugPrint('[StockCheckProvider] Params -> Search: "$_searchQuery", Brand: "$_selectedBrand", SortBy: "$_selectedSortBy"');

    _products = await _apiService.getProducts(
      branchId: _selectedBranch?.id,
      search: _searchQuery,
      brand: _selectedBrand,
      sortBy: _selectedSortBy,
    );
    debugPrint('[StockCheckProvider] Loaded ${_products.length} products.');

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
