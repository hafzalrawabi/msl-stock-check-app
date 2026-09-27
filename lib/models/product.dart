class Product {
  final int id;
  final int slNo;
  final String barcode;
  final String brand;
  final String itemName;
  bool? isAvailable; // true: Available, false: Not Available, null: Pending / N/A
  String? remarks;
  String? erpStock;
  final int shelfStock;
  final int backStock;
  final int totalStock;
  final String unit;
  final List<String> groups;
  final List<int> branchIds;
  bool isVisible;

  Product({
    required this.id,
    this.slNo = 0,
    this.barcode = '',
    this.brand = '',
    required this.itemName,
    this.isAvailable,
    this.remarks,
    this.erpStock,
    this.shelfStock = 0,
    this.backStock = 0,
    this.totalStock = 0,
    this.unit = 'PC',
    this.groups = const [],
    this.branchIds = const [],
    this.isVisible = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    bool? avail;
    if (json['is_available'] != null || json['status'] != null) {
      final raw = json['is_available'] ?? json['status'];
      if (raw == false || raw == 0 || raw == '0' || raw == 'false' || raw == 'Not Available' || raw == 'NOT AVAILABLE') {
        avail = false;
      } else if (raw == true || raw == 1 || raw == '1' || raw == 'true' || raw == 'Available' || raw == 'AVAILABLE') {
        avail = true;
      }
    } else {
      avail = true; // Default to Available if not explicitly marked unavailable
    }

    List<String> parsedGroups = [];
    if (json['groups'] is List) {
      parsedGroups = (json['groups'] as List).map((e) => e.toString()).toList();
    } else if (json['groups_msl'] is List) {
      parsedGroups = (json['groups_msl'] as List).map((e) => e.toString()).toList();
    }

    List<int> parsedBranchIds = [];
    if (json['branch_ids'] is List) {
      parsedBranchIds = (json['branch_ids'] as List).map((e) => int.tryParse(e.toString()) ?? 0).toList();
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    Map<String, dynamic>? ebtMap;
    if (json['ebt_stock'] is Map) {
      ebtMap = Map<String, dynamic>.from(json['ebt_stock']);
    } else if (json['ebtStock'] is Map) {
      ebtMap = Map<String, dynamic>.from(json['ebtStock']);
    }

    final shelfVal = ebtMap != null ? ebtMap['location_stock'] : (json['shelf_stock'] ?? json['shelf'] ?? json['shelfStock']);
    final backVal = ebtMap != null ? ebtMap['back_store_stock'] : (json['back_stock'] ?? json['back'] ?? json['backStock']);
    final totalVal = ebtMap != null ? ebtMap['total_stock'] : (json['total_stock'] ?? json['total'] ?? json['totalStock'] ?? json['erp_stock']);
    final unitVal = ebtMap != null ? ebtMap['uom'] : (json['unit'] ?? json['uom']);

    return Product(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      slNo: parseInt(json['sl_no'] ?? json['sl'] ?? json['slNo']),
      barcode: json['barcode']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? json['name']?.toString() ?? json['itemName']?.toString() ?? 'Product',
      isAvailable: avail,
      remarks: json['remarks']?.toString() ?? json['remark']?.toString(),
      erpStock: (totalVal ?? json['erp_stock'] ?? '0').toString(),
      shelfStock: parseInt(shelfVal),
      backStock: parseInt(backVal),
      totalStock: parseInt(totalVal),
      unit: unitVal?.toString() ?? 'PC',
      groups: parsedGroups,
      branchIds: parsedBranchIds,
      isVisible: json['is_visible'] == true || json['is_visible'] == 1 || json['is_visible'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sl_no': slNo,
      'barcode': barcode,
      'brand': brand,
      'item_name': itemName,
      'is_available': isAvailable,
      'remarks': remarks,
      'erp_stock': erpStock,
      'shelf_stock': shelfStock,
      'back_stock': backStock,
      'total_stock': totalStock,
      'unit': unit,
      'groups': groups,
      'branch_ids': branchIds,
      'is_visible': isVisible,
    };
  }
}
