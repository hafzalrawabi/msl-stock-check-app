import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../models/branch.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  DashboardSummary _summary = DashboardSummary();
  List<BranchGroup> _groups = [];
  List<Branch> _outletReports = [];
  BranchGroup? _selectedGroup;

  List<Product> _matrixProducts = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime(2026, 9, 24);

  DashboardSummary get summary => _summary;
  List<BranchGroup> get groups => _groups;
  List<Branch> get outletReports => _outletReports;
  BranchGroup? get selectedGroup => _selectedGroup;
  List<Product> get matrixProducts => _matrixProducts;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _summary = await _apiService.getDashboardSummary();
    _groups = await _apiService.getBranchGroups();

    if (_groups.isNotEmpty) {
      _selectedGroup = _groups.firstWhere((g) => g.name == 'Al Rawabi Group', orElse: () => _groups.first);
      await loadOutletReports();
    }

    _matrixProducts = await _apiService.getProducts(limit: 50);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectGroup(BranchGroup group) async {
    _selectedGroup = group;
    await loadOutletReports();
  }

  Future<void> loadOutletReports() async {
    if (_selectedGroup == null) return;
    _outletReports = await _apiService.getBranches(groupId: _selectedGroup!.id);
    notifyListeners();
  }

  void updateDate(DateTime newDate) {
    _selectedDate = newDate;
    init();
  }
}
