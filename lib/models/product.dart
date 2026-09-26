class Product {
  final int id;
  final int slNo;
  final String barcode;
  final String brand;
  final String itemName;
  bool? isAvailable; // true: Available, false: Not Available, null: Pending / N/A
  String? remarks;
  String? erpStock;
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
    this.groups = const [],
    this.branchIds = const [],
    this.isVisible = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    bool? avail;
    if (json['is_available'] != null) {
      if (json['is_available'] is bool) {
        avail = json['is_available'];
      } else if (json['is_available'] == 1 || json['is_available'] == '1' || json['is_available'] == 'true') {
        avail = true;
      } else if (json['is_available'] == 0 || json['is_available'] == '0' || json['is_available'] == 'false') {
        avail = false;
      }
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

    return Product(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      slNo: json['sl_no'] is int ? json['sl_no'] : int.tryParse(json['sl_no']?.toString() ?? '0') ?? 0,
      barcode: json['barcode']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? json['name']?.toString() ?? 'Product',
      isAvailable: avail,
      remarks: json['remarks']?.toString(),
      erpStock: json['erp_stock']?.toString() ?? 'n/a',
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
      'groups': groups,
      'branch_ids': branchIds,
      'is_visible': isVisible,
    };
  }
}
