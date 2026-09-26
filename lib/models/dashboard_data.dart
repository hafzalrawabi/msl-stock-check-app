class DashboardSummary {
  final int dailyStockAvailable;
  final int dailyStockNotAvailable;
  final int weeklyCheckedCount;
  final int weeklyTotalCount;
  final int weeklyCheckedGroupsCount;
  final int monthlyCheckedCount;
  final int monthlyTotalCount;
  final int monthlyPendingCount;
  final int totalCatalogueProducts;
  final int totalGroupAssignments;

  DashboardSummary({
    this.dailyStockAvailable = 0,
    this.dailyStockNotAvailable = 0,
    this.weeklyCheckedCount = 12,
    this.weeklyTotalCount = 52,
    this.weeklyCheckedGroupsCount = 30,
    this.monthlyCheckedCount = 0,
    this.monthlyTotalCount = 52,
    this.monthlyPendingCount = 12365,
    this.totalCatalogueProducts = 1580,
    this.totalGroupAssignments = 3370,
  });

  static int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value != null) {
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      dailyStockAvailable: _parseInt(json['dailyStockAvailable'] ?? json['daily_available'] ?? json['daily_stock_available'], 0),
      dailyStockNotAvailable: _parseInt(json['dailyStockNotAvailable'] ?? json['daily_not_available'] ?? json['daily_stock_not_available'], 0),
      weeklyCheckedCount: _parseInt(json['weeklyCheckedCount'] ?? json['weekly_checked'] ?? json['weekly_checked_count'], 12),
      weeklyTotalCount: _parseInt(json['weeklyTotalCount'] ?? json['weekly_total'] ?? json['weekly_total_count'], 52),
      weeklyCheckedGroupsCount: _parseInt(json['weeklyCheckedGroupsCount'] ?? json['weekly_groups'] ?? json['weekly_checked_groups_count'], 30),
      monthlyCheckedCount: _parseInt(json['monthlyCheckedCount'] ?? json['monthly_checked'] ?? json['monthly_checked_count'], 0),
      monthlyTotalCount: _parseInt(json['monthlyTotalCount'] ?? json['monthly_total'] ?? json['monthly_total_count'], 52),
      monthlyPendingCount: _parseInt(json['monthlyPendingCount'] ?? json['monthly_pending'] ?? json['monthly_pending_count'], 12365),
      totalCatalogueProducts: _parseInt(json['totalCatalogueProducts'] ?? json['total_products'] ?? json['total_catalogue_products'], 1580),
      totalGroupAssignments: _parseInt(json['totalGroupAssignments'] ?? json['total_assignments'] ?? json['total_group_assignments'], 3370),
    );
  }
}

class StockUpdateRecord {
  final int id;
  final int productId;
  final String barcode;
  final String itemName;
  final String brand;
  final String groupName;
  final String branchName;
  final bool isAvailable;
  final String? remarks;
  final DateTime updatedAt;
  final String updatedBy;

  StockUpdateRecord({
    required this.id,
    required this.productId,
    required this.barcode,
    required this.itemName,
    required this.brand,
    required this.groupName,
    required this.branchName,
    required this.isAvailable,
    this.remarks,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory StockUpdateRecord.fromJson(Map<String, dynamic> json) {
    return StockUpdateRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: json['product_id'] ?? json['productId'] ?? 0,
      barcode: json['barcode']?.toString() ?? '',
      itemName: json['item_name'] ?? json['itemName'] ?? json['product_name'] ?? '',
      brand: json['brand'] ?? json['brand_name'] ?? '',
      groupName: json['group_name'] ?? json['groupName'] ?? '',
      branchName: json['branch_name'] ?? json['branchName'] ?? json['outlet_name'] ?? '',
      isAvailable: json['is_available'] == true || json['is_available'] == 1 || json['isAvailable'] == true,
      remarks: json['remarks'],
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      updatedBy: json['updated_by'] ?? json['updatedBy'] ?? json['username'] ?? 'admin',
    );
  }
}
