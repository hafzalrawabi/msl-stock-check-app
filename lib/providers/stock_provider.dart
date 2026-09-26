import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../models/dashboard_summary.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class StockProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<BranchGroup> _groups = [];
  List<Branch> _branches = [];
  List<Product> _products = [];
  final List<StockUpdateItem> _updates = [];
  final DashboardSummary _dashboardSummary = DashboardSummary();

  BranchGroup? _selectedGroup;
  Branch? _selectedBranch;
  DateTime _selectedDate = DateTime.now();

  String _searchQuery = '';
  String _selectedBrand = 'All Brands';
  String _sortBy = 'Default (SL No.)';
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Getters
  List<BranchGroup> get groups => _groups;
  List<Branch> get branches => _branches;
  List<Product> get products => _filteredProducts;
  List<StockUpdateItem> get updates => _updates;
  DashboardSummary get dashboardSummary => _dashboardSummary;

  BranchGroup? get selectedGroup => _selectedGroup;
  Branch? get selectedBranch => _selectedBranch;
  DateTime get selectedDate => _selectedDate;

  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  String get sortBy => _sortBy;
  bool get isLoading => _isLoading;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  StockProvider() {
    initData();
  }

  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _apiService.getBranchGroups();
      _branches = await _apiService.getBranches();

      if (_groups.isNotEmpty) {
        _selectedGroup = _groups.firstWhere(
          (g) => g.name.contains('Saudia'),
          orElse: () => _groups.first,
        );
      }

      if (_branches.isNotEmpty) {
        _selectedBranch = _branches.firstWhere(
          (b) => b.name.contains('MAITHER'),
          orElse: () => _branches.first,
        );
      }

      await fetchProducts();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _apiService.getProducts(
        branchId: _selectedBranch?.id,
        search: _searchQuery,
        brand: _selectedBrand,
        sortBy: _sortBy,
      );
    } catch (_) {}

    _isLoading = false;
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  List<Product> get _filteredProducts {
    List<Product> list = List.from(_products);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
        p.itemName.toLowerCase().contains(q) ||
        p.barcode.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        p.slNo.toString().contains(q)
      ).toList();
    }

    if (_selectedBrand != 'All Brands') {
      list = list.where((p) => p.brand.toLowerCase() == _selectedBrand.toLowerCase()).toList();
    }

    if (_sortBy == 'A to Z') {
      list.sort((a, b) => a.itemName.compareTo(b.itemName));
    } else if (_sortBy == 'Z to A') {
      list.sort((a, b) => b.itemName.compareTo(a.itemName));
    } else {
      list.sort((a, b) => a.slNo.compareTo(b.slNo));
    }

    return list;
  }

  void setSelectedGroup(BranchGroup group) {
    _selectedGroup = group;
    // Filter branches belonging to group
    final groupBranches = _branches.where((b) => b.groupId == group.id || b.groupName == group.name).toList();
    if (groupBranches.isNotEmpty) {
      _selectedBranch = groupBranches.first;
    }
    fetchProducts();
  }

  void setSelectedBranch(Branch branch) {
    _selectedBranch = branch;
    fetchProducts();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setBrandFilter(String brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void toggleProductAvailability(int productId, bool isAvailable) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      if (_products[index].isAvailable == isAvailable) {
        _products[index].isAvailable = null; // Toggle back to pending
      } else {
        _products[index].isAvailable = isAvailable;
      }
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void updateProductRemarks(int productId, String remarks) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index].remarks = remarks;
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  Future<void> saveAllChanges() async {
    _isLoading = true;
    notifyListeners();

    if (_selectedBranch != null) {
      for (var p in _products) {
        if (p.isAvailable != null) {
          await _apiService.updateStockCheck(
            productId: p.id,
            branchId: _selectedBranch!.id,
            isAvailable: p.isAvailable!,
            remarks: p.remarks,
          );
        }
      }
    }

    _hasUnsavedChanges = false;
    _isLoading = false;
    notifyListeners();
  }

  void discardChanges() {
    fetchProducts();
  }

  void addProductLocal(Product product) {
    _products.insert(0, product);
    notifyListeners();
  }

  void clearUpdates() {
    _updates.clear();
    notifyListeners();
  }
}
