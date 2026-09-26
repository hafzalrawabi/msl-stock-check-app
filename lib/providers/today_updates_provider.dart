import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';

class TodayUpdatesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  DateTime _startDate = DateTime(2026, 9, 24);
  DateTime _endDate = DateTime(2026, 9, 24);
  String _datePreset = 'Today';

  String _selectedGroup = 'All groups';
  String _selectedOutlet = 'All outlets';
  String _selectedBrand = 'All brands';
  String _searchQuery = '';

  List<StockUpdateRecord> _updates = [];
  bool _isLoading = false;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get datePreset => _datePreset;
  String get selectedGroup => _selectedGroup;
  String get selectedOutlet => _selectedOutlet;
  String get selectedBrand => _selectedBrand;
  String get searchQuery => _searchQuery;

  List<StockUpdateRecord> get updates => _updates;
  bool get isLoading => _isLoading;

  int get totalUpdates => _updates.length;
  int get availableCount => _updates.where((u) => u.isAvailable).length;
  int get notAvailableCount => _updates.where((u) => !u.isAvailable).length;
  int get outletsUpdatedCount => _updates.map((u) => u.branchName).toSet().length;

  Future<void> loadUpdates() async {
    _isLoading = true;
    notifyListeners();

    _updates = await _apiService.getDashboardUpdates(
      dateFrom: _startDate.toIso8601String().split('T').first,
      dateTo: _endDate.toIso8601String().split('T').first,
      brand: _selectedBrand,
    );

    _isLoading = false;
    notifyListeners();
  }

  void setDateRange({required DateTime start, required DateTime end, required String preset}) {
    _startDate = start;
    _endDate = end;
    _datePreset = preset;
    loadUpdates();
  }

  void setFilters({String? group, String? outlet, String? brand, String? search}) {
    if (group != null) _selectedGroup = group;
    if (outlet != null) _selectedOutlet = outlet;
    if (brand != null) _selectedBrand = brand;
    if (search != null) _searchQuery = search;
    loadUpdates();
  }

  void clearUpdates() {
    _updates.clear();
    notifyListeners();
  }
}
