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
    this.mslPerOutlet = 1008,
    this.status,
  });

  factory BranchGroup.fromJson(Map<String, dynamic> json) {
    return BranchGroup(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? json['group_name'] ?? 'Group',
      outletCount: json['outletCount'] ?? json['outlet_count'] ?? 0,
      mslPerOutlet: json['mslPerOutlet'] ?? json['msl_per_outlet'] ?? 1008,
      status: json['status'],
    );
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
    this.mslCount = 1008,
    this.availableCount = 0,
    this.notAvailableCount = 0,
    this.pendingCount = 0,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? json['branch_name'] ?? json['outlet'] ?? 'Branch',
      groupId: json['groupId'] ?? json['group_id'],
      groupName: json['groupName'] ?? json['group_name'],
      mslCount: json['mslCount'] ?? json['msl_count'] ?? json['msl'] ?? 1008,
      availableCount: json['availableCount'] ?? json['available_count'] ?? json['available'] ?? 0,
      notAvailableCount: json['notAvailableCount'] ?? json['not_available_count'] ?? json['not_avail'] ?? 0,
      pendingCount: json['pendingCount'] ?? json['pending_count'] ?? json['pending'] ?? 0,
    );
  }
}
