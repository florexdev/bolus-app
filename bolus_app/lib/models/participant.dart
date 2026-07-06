import 'listing.dart';
import 'profile.dart';

class Participant {
  final String id;
  final String listingId;
  final String userId;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;
  final Listing? listing;
  final Profile? profile;

  Participant({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.status,
    this.createdAt,
    this.listing,
    this.profile,
  });

  factory Participant.fromJson(Map<String, dynamic> json, {Listing? listing, Profile? profile}) {
    return Participant(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      listing: listing ?? (json['bolus_listings'] != null ? Listing.fromJson(json['bolus_listings'] as Map<String, dynamic>) : null),
      profile: profile ?? (json['profiles'] != null ? Profile.fromJson(json['profiles'] as Map<String, dynamic>) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'user_id': userId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
