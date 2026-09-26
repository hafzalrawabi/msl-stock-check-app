class BranchGroup {
  final int id;
  final String name;
  final int outletCount;
  final int mslPerOutlet;
  final String? status;

  BranchGroup({
    required this.id,
    required this.name,
    this.outletCount = 0,
    this.mslPerOutlet = 0,
    this.status,
  });

  factory BranchGroup.fromJson(Map<String, dynamic> json) {
    return BranchGroup(
      id: _parseInt(json['id'] ?? json['group_id']),
      name: json['name']?.toString() ?? json['group_name']?.toString() ?? 'Group',
      outletCount: _parseInt(json['outletCount'] ?? json['outlet_count'] ?? json['outlets_count']),
      mslPerOutlet: _parseInt(json['mslPerOutlet'] ?? json['msl_per_outlet'] ?? json['msl']),
      status: json['status']?.toString(),
    );
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }
}

class Branch {
  final int id;
  final String name;
  final int? groupId;
  final String? groupName;
  final int mslCount;
  final int availableCount;
  final int notAvailableCount;
  final int pendingCount;

  String get code => name;

  Branch({
    required this.id,
    required this.name,
    this.groupId,
    this.groupName,
    this.mslCount = 0,
    this.availableCount = 0,
    this.notAvailableCount = 0,
    this.pendingCount = 0,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    final id = _parseInt(json['id'] ?? json['branch_id'] ?? json['outlet_id']);
    final name = json['name']?.toString() ??
        json['branch_name']?.toString() ??
        json['outlet_name']?.toString() ??
        json['outlet']?.toString() ??
        json['title']?.toString() ??
        'Branch';

    final groupId = json['groupId'] != null
        ? _parseInt(json['groupId'])
        : (json['group_id'] != null ? _parseInt(json['group_id']) : null);
    final groupName = json['groupName']?.toString() ?? json['group_name']?.toString();

    final avail = _parseInt(json['availableCount'] ?? json['available_count'] ?? json['available'] ?? json['avail'] ?? json['in_stock']);
    final notAvail = _parseInt(json['notAvailableCount'] ?? json['not_available_count'] ?? json['not_available'] ?? json['not_avail'] ?? json['na'] ?? json['out_of_stock']);

    int parsedMsl = _parseInt(json['mslCount'] ?? json['msl_count'] ?? json['msl'] ?? json['total_msl'] ?? json['total_items'] ?? json['total']);
    int parsedPending = _parseInt(json['pendingCount'] ?? json['pending_count'] ?? json['pending'] ?? json['pnd'] ?? json['unchecked']);

    // If MSL count wasn't provided directly in API, calculate it dynamically from avail + notAvail + pending
    if (parsedMsl == 0 && (avail > 0 || notAvail > 0 || parsedPending > 0)) {
      parsedMsl = avail + notAvail + parsedPending;
    }

    // If pending count wasn't provided directly in API but MSL is known, calculate pending = MSL - avail - notAvail
    if (parsedPending == 0 && parsedMsl > (avail + notAvail) && json['pending'] == null && json['pending_count'] == null) {
      parsedPending = parsedMsl - avail - notAvail;
    }

    return Branch(
      id: id,
      name: name,
      groupId: groupId,
      groupName: groupName,
      mslCount: parsedMsl,
      availableCount: avail,
      notAvailableCount: notAvail,
      pendingCount: parsedPending,
    );
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }
}
