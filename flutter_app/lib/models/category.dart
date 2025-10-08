import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  @JsonKey(name: '_id')
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Handle the backend response format
    Map<String, dynamic> processedJson = Map<String, dynamic>.from(json);

    // Convert MongoDB _id to id
    if (processedJson.containsKey('_id') && processedJson['_id'] is Map) {
      processedJson['_id'] = processedJson['_id']['\$oid'];
    }

    // Convert userId ObjectId to string
    if (processedJson.containsKey('userId') && processedJson['userId'] is Map) {
      processedJson['userId'] = processedJson['userId']['\$oid'];
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

    return _$CategoryFromJson(processedJson);
  }

  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  // Helper method to copy with modifications
  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Category with menu item count (returned from API)
@JsonSerializable()
class CategoryWithCount extends Category {
  final int menuItemsCount;

  const CategoryWithCount({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    required super.icon,
    required super.color,
    super.isActive,
    super.sortOrder,
    super.createdAt,
    super.updatedAt,
    this.menuItemsCount = 0,
  });

  factory CategoryWithCount.fromJson(Map<String, dynamic> json) {
    // Handle the backend response format
    Map<String, dynamic> processedJson = Map<String, dynamic>.from(json);

    // Convert MongoDB _id to id
    if (processedJson.containsKey('_id') && processedJson['_id'] is Map) {
      processedJson['_id'] = processedJson['_id']['\$oid'];
    }

    // Convert userId ObjectId to string
    if (processedJson.containsKey('userId') && processedJson['userId'] is Map) {
      processedJson['userId'] = processedJson['userId']['\$oid'];
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

    return _$CategoryWithCountFromJson(processedJson);
  }

  @override
  Map<String, dynamic> toJson() => _$CategoryWithCountToJson(this);
}
