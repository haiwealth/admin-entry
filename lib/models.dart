import 'dart:convert';

class User {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final Role? role;
  final String? avatar;
  final List<LoginMethod>? loginMethods;
  final bool? isActive;
  final String? lastLoginAt;
  final String? registrationDate;
  final int? loginCount;
  final int? totalCourseEnrollments;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.role,
    this.avatar,
    this.loginMethods,
    this.isActive,
    this.lastLoginAt,
    this.registrationDate,
    this.loginCount,
    this.totalCourseEnrollments,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] != null ? 
        (json['role'] is String ? 
          Role(id: 0, name: json['role'], displayName: json['role'], 
               description: '', permissions: [], isActive: true, 
               isSystemDefault: false, createdAt: '') :
          Role.fromJson(json['role'])) : null,
      avatar: json['avatar'],
      loginMethods: json['login_methods'] != null ?
        (json['login_methods'] as List).map((m) => LoginMethod.fromJson(m)).toList() : null,
      isActive: json['is_active'],
      lastLoginAt: json['last_login_at'],
      registrationDate: json['registration_date'],
      loginCount: json['login_count'],
      totalCourseEnrollments: json['total_course_enrollments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatar,
      'role_id': role?.id,
      'is_active': isActive,
    };
  }
}

class LoginMethod {
  final String provider;
  final String? providerName;
  final bool isActive;
  final String? createdAt;
  final String? lastUsedAt;

  LoginMethod({
    required this.provider,
    this.providerName,
    required this.isActive,
    this.createdAt,
    this.lastUsedAt,
  });

  factory LoginMethod.fromJson(Map<String, dynamic> json) {
    return LoginMethod(
      provider: json['provider'],
      providerName: json['provider_name'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
      lastUsedAt: json['last_used_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'provider_name': providerName,
      'is_active': isActive,
    };
  }
}

class Course {
  final int id;
  final String title;
  final String description;
  final String shortDesc;
  final double price;
  final String level;
  final String language;
  final String category;
  final String thumbnail;
  final String previewVideo;
  final bool isPublished;
  final String createdAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.shortDesc,
    required this.price,
    required this.level,
    required this.language,
    required this.category,
    required this.thumbnail,
    required this.previewVideo,
    required this.isPublished,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      shortDesc: json['short_desc'],
      price: (json['price'] as num).toDouble(),
      level: json['level'],
      language: json['language'],
      category: json['category'],
      thumbnail: json['thumbnail'],
      previewVideo: json['preview_video'],
      isPublished: json['is_published'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'short_desc': shortDesc,
      'price': price,
      'level': level,
      'language': language,
      'category': category,
      'thumbnail': thumbnail,
      'preview_video': previewVideo,
      'is_published': isPublished,
    };
  }
}

class Role {
  final int id;
  final String name;
  final String displayName;
  final String description;
  final List<Permission> permissions;
  final bool isActive;
  final bool isSystemDefault;
  final String createdAt;

  Role({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.permissions,
    required this.isActive,
    required this.isSystemDefault,
    required this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    var permissionsList = <Permission>[];
    if (json['permissions'] != null) {
      // Check if permissions is already a decoded object or a string
      if (json['permissions'] is String) {
        try {
          var decodedPermissions = jsonDecode(json['permissions']);
          if (decodedPermissions is Map && decodedPermissions['permissions'] != null) {
            permissionsList = (decodedPermissions['permissions'] as List)
                .map((p) => Permission.fromJson(p))
                .toList();
          } else if (decodedPermissions is List) {
            permissionsList = decodedPermissions
                .map((p) => Permission.fromJson(p))
                .toList();
          }
        } catch (e) {
          // If JSON decode fails, keep empty permissions list
          print('Failed to parse permissions: $e');
        }
      } else if (json['permissions'] is Map) {
        // If permissions is already a Map
        if (json['permissions']['permissions'] != null) {
          permissionsList = (json['permissions']['permissions'] as List)
              .map((p) => Permission.fromJson(p))
              .toList();
        }
      } else if (json['permissions'] is List) {
        // If permissions is directly a List
        permissionsList = (json['permissions'] as List)
            .map((p) => Permission.fromJson(p))
            .toList();
      }
    }

    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'] ?? '',
      permissions: permissionsList,
      isActive: json['is_active'] ?? true,
      isSystemDefault: json['is_system_default'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'permissions': jsonEncode({'permissions': permissions.map((p) => p.toJson()).toList()}),
      'is_active': isActive,
      'is_system_default': isSystemDefault,
    };
  }
}

class Permission {
  final String resource;
  final String action;
  final String scope;

  Permission({
    required this.resource,
    required this.action,
    required this.scope,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      resource: json['resource'],
      action: json['action'],
      scope: json['scope'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resource': resource,
      'action': action,
      'scope': scope,
    };
  }
}