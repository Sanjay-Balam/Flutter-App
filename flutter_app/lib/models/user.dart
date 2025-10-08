import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserRole { owner, manager, employee }

@JsonSerializable()
class User {
  @JsonKey(name: '_id')
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserRole role;
  final String? businessName;
  final String? businessType;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    this.businessName,
    this.businessType,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle the backend response format
    Map<String, dynamic> processedJson = Map<String, dynamic>.from(json);

    // Convert MongoDB _id to id
    if (processedJson.containsKey('_id') && processedJson['_id'] is Map) {
      processedJson['_id'] = processedJson['_id']['\$oid'];
    }

    // Convert date strings to DateTime
    if (processedJson.containsKey('createdAt')) {
      if (processedJson['createdAt'] is Map &&
          processedJson['createdAt'].containsKey('\$date')) {
        processedJson['createdAt'] = processedJson['createdAt']['\$date'];
      }
    }

    if (processedJson.containsKey('updatedAt')) {
      if (processedJson['updatedAt'] is Map &&
          processedJson['updatedAt'].containsKey('\$date')) {
        processedJson['updatedAt'] = processedJson['updatedAt']['\$date'];
      }
    }

    return _$UserFromJson(processedJson);
  }

  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Helper method to get full name
  String get fullName => '$firstName $lastName';

  // Helper method to get display name for business
  String get displayName => businessName ?? fullName;
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Manager';
      case UserRole.employee:
        return 'Employee';
    }
  }
}
