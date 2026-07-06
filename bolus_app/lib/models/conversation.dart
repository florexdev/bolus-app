import 'listing.dart';

class Conversation {
  final String id;
  final String listingId;
  final DateTime? createdAt;
  final Listing? listing;

  Conversation({
    required this.id,
    required this.listingId,
    this.createdAt,
    this.listing,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, {Listing? listing}) {
    return Conversation(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      listing: listing ?? (json['bolus_listings'] != null ? Listing.fromJson(json['bolus_listings'] as Map<String, dynamic>) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
