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
  String _selectedStatus = 'All Status';
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Getters
  List<BranchGroup> get groups => _groups;
  List<Branch> get branches => _branches;

  List<Branch> get filteredBranches {
    if (_selectedGroup == null) return _branches;

    final String cleanGroupName = _selectedGroup!.name
        .replaceAll(RegExp(r'\s*\(\d+\)'), '')
        .trim()
        .toLowerCase();

    final groupBranches = _branches.where((b) {
      if (b.groupId != null && b.groupId == _selectedGroup!.id) {
        return true;
      }
      if (b.groupName != null && b.groupName!.isNotEmpty) {
        final cleanBranchGroup = b.groupName!
            .replaceAll(RegExp(r'\s*\(\d+\)'), '')
            .trim()
            .toLowerCase();
        if (cleanBranchGroup == cleanGroupName || cleanBranchGroup.contains(cleanGroupName) || cleanGroupName.contains(cleanBranchGroup)) {
          return true;
        }
      }
      return false;
    }).toList();

    return groupBranches.isNotEmpty ? groupBranches : _branches;
  }

  List<Product> get products => _filteredProducts;
  List<StockUpdateItem> get updates => _updates;
  DashboardSummary get dashboardSummary => _dashboardSummary;

  BranchGroup? get selectedGroup => _selectedGroup;
  Branch? get selectedBranch => _selectedBranch;
  DateTime get selectedDate => _selectedDate;

  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  String get sortBy => _sortBy;
  String get selectedStatus => _selectedStatus;
  bool get isLoading => _isLoading;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  List<String> get availableBrands {
    final set = <String>{};
    for (var p in _products) {
      if (p.brand.trim().isNotEmpty) {
        set.add(p.brand.trim());
      }
    }
    final list = set.toList()..sort();
    return ['All Brands', ...list];
  }

  StockProvider() {
    initData();
  }

  Future<void> initData() async {
    _isLoading = true;
    _selectedDate = DateTime.now();
    notifyListeners();

    debugPrint('\n[FETCH DATA] Initializing dashboard & stock data...');
    try {
      final bootstrap = await _apiService.getBranchesBootstrap();
      if (bootstrap.isNotEmpty) {
        if (bootstrap['groups'] is List) {
          _groups = (bootstrap['groups'] as List).map((e) => BranchGroup.fromJson(e)).toList();
        }
        if (bootstrap['branches'] is List) {
          _branches = (bootstrap['branches'] as List).map((e) => Branch.fromJson(e)).toList();
        } else if (bootstrap['outlets'] is List) {
          _branches = (bootstrap['outlets'] as List).map((e) => Branch.fromJson(e)).toList();
        }
      }

      if (_groups.isEmpty) {
        _groups = await _apiService.getBranchGroups();
      }
      if (_branches.isEmpty) {
        _branches = await _apiService.getBranches();
      }

      debugPrint('[FETCH DATA] Loaded ${_groups.length} groups and ${_branches.length} branches.');

      if (_groups.isNotEmpty && _selectedGroup == null) {
        _selectedGroup = _groups.first;
      }

      final availableBranches = filteredBranches;
      if (availableBranches.isNotEmpty) {
        _selectedBranch = availableBranches.first;
      } else if (_branches.isNotEmpty) {
        _selectedBranch = _branches.first;
      }

      if (_selectedBranch != null) {
        await fetchProducts();
      }
    } catch (e) {
      debugPrint('[FETCH DATA ERROR] Exception during initData: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  final Map<int, List<Product>> _branchCache = {};

  Future<void> fetchProducts({bool showLoader = true}) async {
    final branchId = _selectedBranch?.id;
    final hasCachedData = branchId != null && _branchCache.containsKey(branchId);

    // If cached products exist, show them immediately without blocking UI
    if (hasCachedData && _products.isEmpty) {
      _products = List.from(_branchCache[branchId]!);
      notifyListeners();
    }

    if (!hasCachedData && showLoader && _products.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    debugPrint('\n[FETCH DATA] Requesting product catalogue for Branch ID: $branchId (${_selectedBranch?.name})...');

    try {
      final fetched = await _apiService.getProducts(
        branchId: branchId,
        search: _searchQuery,
        brand: _selectedBrand,
        sortBy: _sortBy,
      );

      _products = fetched;
      if (branchId != null) {
        _branchCache[branchId] = List.from(fetched);
      }
      debugPrint('[FETCH DATA SUCCESS] Received ${_products.length} products for ${_selectedBranch?.name}');
    } catch (e) {
      debugPrint('[FETCH DATA ERROR] Error fetching products: $e');
    }

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

    if (_selectedStatus == 'Available') {
      list = list.where((p) => p.isAvailable == true).toList();
    } else if (_selectedStatus == 'Not Available') {
      list = list.where((p) => p.isAvailable == false).toList();
    } else if (_selectedStatus == 'Pending') {
      list = list.where((p) => p.isAvailable == null).toList();
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

  void applyFilters({String? brand, String? sort, String? status}) {
    if (brand != null) _selectedBrand = brand;
    if (sort != null) _sortBy = sort;
    if (status != null) _selectedStatus = status;
    notifyListeners();
  }

  Future<void> setSelectedGroup(BranchGroup group) async {
    if (_selectedGroup?.id == group.id) return;
    _selectedGroup = group;
    _products.clear();
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedBranches = await _apiService.getBranches(groupId: group.id);
      if (fetchedBranches.isNotEmpty) {
        _branches = fetchedBranches;
      }
    } catch (_) {}

    final availableBranches = filteredBranches;
    if (availableBranches.isNotEmpty) {
      _selectedBranch = availableBranches.first;
    } else if (_branches.isNotEmpty) {
      _selectedBranch = _branches.first;
    } else {
      _selectedBranch = null;
    }

    await fetchProducts();
  }

  void setSelectedBranch(Branch branch) {
    if (_selectedBranch?.id == branch.id) return;
    _selectedBranch = branch;
    
    // Show cached branch data instantly if available
    if (_branchCache.containsKey(branch.id)) {
      _products = List.from(_branchCache[branch.id]!);
      notifyListeners();
      fetchProducts(showLoader: false);
    } else {
      _products.clear();
      fetchProducts(showLoader: true);
    }
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
      final updateFutures = <Future>[];
      for (var p in _products) {
        if (p.isAvailable != null) {
          updateFutures.add(
            _apiService.updateStockCheck(
              productId: p.id,
              branchId: _selectedBranch!.id,
              isAvailable: p.isAvailable!,
              remarks: p.remarks,
            ),
          );
        }
      }
      // Execute all pending stock updates concurrently in parallel for maximum speed
      if (updateFutures.isNotEmpty) {
        await Future.wait(updateFutures);
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
