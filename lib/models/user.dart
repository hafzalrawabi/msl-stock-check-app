class UserModel {
  final int? id;
  final String username;
  final String role;
  final int? branchId;
  final String? branchName;

  UserModel({
    this.id,
    required this.username,
    required this.role,
    this.branchId,
    this.branchName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      username: json['username'] ?? '',
      role: json['role'] ?? 'supervisor',
      branchId: json['branchId'] is int ? json['branchId'] : int.tryParse(json['branchId']?.toString() ?? ''),
      branchName: json['branchName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'branchId': branchId,
      'branchName': branchName,
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
}
