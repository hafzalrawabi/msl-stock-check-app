import 'dart:async';

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

  // Pagination & Loading
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _page = 1;
  final int _limit = 25;

  bool _hasUnsavedChanges = false;

  // Timer for search debouncing
  Timer? _searchDebounceTimer;

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
        if (cleanBranchGroup == cleanGroupName ||
            cleanBranchGroup.contains(cleanGroupName) ||
            cleanGroupName.contains(cleanBranchGroup)) {
          return true;
        }
      }
      return false;
    }).toList();

    return groupBranches.isNotEmpty ? groupBranches : _branches;
  }

  // Returns server-driven products list directly
  List<Product> get products => _products;
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
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreProducts => _hasMoreProducts;
  int get page => _page;
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
      debugPrint('[INIT ERROR] $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Direct Server Fetch (Triggers API search regardless of loaded items)
  Future<void> fetchProducts({bool showLoader = true}) async {
    final branchId = _selectedBranch?.id;

    _page = 1;
    _hasMoreProducts = true;

    if (showLoader) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final fetched = await _apiService.getProducts(
        branchId: branchId,
        search: _searchQuery,
        brand: _selectedBrand,
        sortBy: _sortBy,
        page: _page,
        limit: _limit,
      );

      _products = fetched;

      if (fetched.length < _limit) {
        _hasMoreProducts = false;
      }
    } catch (e) {
      debugPrint('[FETCH ERROR] $e');
    }

    _isLoading = false;
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  /// Debouncing API Search (Triggers search query on backend after 400ms delay)
  void setSearchQuery(String query) {
    _searchQuery = query;

    // Cancel existing timer if user is still typing
    if (_searchDebounceTimer?.isActive ?? false) {
      _searchDebounceTimer!.cancel();
    }

    // Debounce duration: Wait 400ms before making API request
    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      fetchProducts(showLoader: true);
    });
  }

  /// Load Next Batch on Infinite Scroll
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts || _isLoading) return;

    final branchId = _selectedBranch?.id;
    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _page + 1;

    try {
      final fetched = await _apiService.getProducts(
        branchId: branchId,
        search: _searchQuery,
        brand: _selectedBrand,
        sortBy: _sortBy,
        page: nextPage,
        limit: _limit,
      );

      if (fetched.isNotEmpty) {
        _page = nextPage;

        // Ensure no duplicated entries when appending
        final existingIds = _products.map((p) => p.id).toSet();
        final newItems = fetched.where((p) => !existingIds.contains(p.id)).toList();

        _products.addAll(newItems);
      }

      if (fetched.length < _limit) {
        _hasMoreProducts = false;
      }
    } catch (e) {
      debugPrint('[LOAD MORE ERROR] $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void applyFilters({String? brand, String? sort, String? status}) {
    if (brand != null) _selectedBrand = brand;
    if (sort != null) _sortBy = sort;
    if (status != null) _selectedStatus = status;

    fetchProducts();
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
    _products.clear();
    fetchProducts(showLoader: true);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setBrandFilter(String brand) {
    _selectedBrand = brand;
    fetchProducts();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    fetchProducts();
  }

  void toggleProductAvailability(int productId, bool isAvailable) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      if (_products[index].isAvailable == isAvailable) {
        _products[index].isAvailable = null;
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

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}