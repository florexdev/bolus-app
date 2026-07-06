import 'profile.dart';

class Listing {
  final String id;
  final String userId;
  final String category;
  final String title;
  final String description;
  final double perPersonCost;
  final int maxParticipants;
  final int currentParticipants;
  final bool isActive;
  final DateTime expiresAt;
  final DateTime? createdAt;
  final Profile? owner;
  final String? city;

  Listing({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    required this.perPersonCost,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.isActive,
    required this.expiresAt,
    this.createdAt,
    this.owner,
    this.city,
  });

  factory Listing.fromJson(Map<String, dynamic> json, {Profile? owner}) {
    return Listing(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      perPersonCost: (json['per_person_cost'] as num).toDouble(),
      maxParticipants: json['max_participants'] as int,
      currentParticipants: json['current_participants'] as int,
      isActive: json['is_active'] as bool,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      owner: owner ?? (json['profiles'] != null ? Profile.fromJson(json['profiles'] as Map<String, dynamic>) : null),
      city: json['city'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'title': title,
      'description': description,
      'per_person_cost': perPersonCost,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'is_active': isActive,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'city': city,
    };
  }

  Listing copyWith({
    String? id,
    String? userId,
    String? category,
    String? title,
    String? description,
    double? perPersonCost,
    int? maxParticipants,
    int? currentParticipants,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
    Profile? owner,
    String? city,
  }) {
    return Listing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      perPersonCost: perPersonCost ?? this.perPersonCost,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      owner: owner ?? this.owner,
      city: city ?? this.city,
    );
  }
}
