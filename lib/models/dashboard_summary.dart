class DashboardSummary {
  final int dailyStockCount;
  final int dailyAvailable;
  final int dailyNotAvailable;
  final int weeklyCheckedCount;
  final int totalWeeklyBranches;
  final int monthlyCheckedCount;
  final int totalMonthlyBranches;
  final int monthlyPendingItems;
  final int mslCatalogueCount;
  final int mslGroupAssignments;
  final String dateText;

  DashboardSummary({
    this.dailyStockCount = 0,
    this.dailyAvailable = 0,
    this.dailyNotAvailable = 0,
    this.weeklyCheckedCount = 12,
    this.totalWeeklyBranches = 52,
    this.monthlyCheckedCount = 0,
    this.totalMonthlyBranches = 52,
    this.monthlyPendingItems = 12365,
    this.mslCatalogueCount = 1580,
    this.mslGroupAssignments = 3370,
    this.dateText = 'Today',
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      dailyStockCount: json['dailyStockCount'] ?? json['daily_stock_count'] ?? 0,
      dailyAvailable: json['dailyAvailable'] ?? json['daily_available'] ?? 0,
      dailyNotAvailable: json['dailyNotAvailable'] ?? json['daily_not_available'] ?? 0,
      weeklyCheckedCount: json['weeklyCheckedCount'] ?? json['weekly_checked_count'] ?? 12,
      totalWeeklyBranches: json['totalWeeklyBranches'] ?? json['total_weekly_branches'] ?? 52,
      monthlyCheckedCount: json['monthlyCheckedCount'] ?? json['monthly_checked_count'] ?? 0,
      totalMonthlyBranches: json['totalMonthlyBranches'] ?? json['total_monthly_branches'] ?? 52,
      monthlyPendingItems: json['monthlyPendingItems'] ?? json['monthly_pending_items'] ?? 12365,
      mslCatalogueCount: json['mslCatalogueCount'] ?? json['msl_catalogue_count'] ?? 1580,
      mslGroupAssignments: json['mslGroupAssignments'] ?? json['msl_group_assignments'] ?? 3370,
      dateText: json['dateText'] ?? json['date_text'] ?? 'Today',
    );
  }
}

class StockUpdateItem {
  final int id;
  final String productName;
  final String barcode;
  final String branchName;
  final String groupName;
  final String brand;
  final bool isAvailable;
  final String updatedAt;

  StockUpdateItem({
    required this.id,
    required this.productName,
    required this.barcode,
    required this.branchName,
    required this.groupName,
    required this.brand,
    required this.isAvailable,
    required this.updatedAt,
  });

  factory StockUpdateItem.fromJson(Map<String, dynamic> json) {
    return StockUpdateItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productName: json['product_name'] ?? json['item_name'] ?? json['productName'] ?? '',
      barcode: json['barcode']?.toString() ?? '',
      branchName: json['branch_name'] ?? json['outlet'] ?? json['branchName'] ?? '',
      groupName: json['group_name'] ?? json['market_group'] ?? json['groupName'] ?? '',
      brand: json['brand']?.toString() ?? '',
      isAvailable: json['is_available'] == true || json['is_available'] == 1 || json['status'] == 'Available',
      updatedAt: json['updated_at'] ?? json['date'] ?? '',
    );
  }
}
