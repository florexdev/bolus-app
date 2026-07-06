import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/listing.dart';
import '../../models/participant.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/profile.dart';

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Current Auth User Provider
final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
});

// Stream Provider for Active Listings
final listingsStreamProvider = StreamProvider.family<List<Listing>, String>((ref, category) {
  final supabase = ref.watch(supabaseClientProvider);
  final myProfileAsync = ref.watch(myProfileProvider);
  final myProfile = myProfileAsync.value;

  // Set up real-time stream for listings
  var query = supabase
      .from('bolus_listings')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  return query.map((data) {
    var listings = data
        .where((item) => item['is_active'] == true)
        .map((json) => Listing.fromJson(json))
        .toList();
    
    // Filter by owner's city if user has set a city in their profile
    if (myProfile != null && myProfile.city != null && myProfile.city!.isNotEmpty) {
      listings = listings.where((item) => item.city == myProfile.city).toList();
    }

    if (category == 'Hepsi') {
      return listings;
    } else {
      return listings.where((item) => item.category == category).toList();
    }
  });
});

// Future Provider to fetch any user's profile
final profileProvider = FutureProvider.family<Profile?, String>((ref, userId) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (data == null) return null;
    return Profile.fromJson(data);
  } catch (e) {
    return null;
  }
});

// Future Provider for the current user's profile
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileProvider(user.id).future);
});

// Future Provider for Pending Incoming Requests (requests made to current user's listings)
// Uses SQL join for listings and profiles, securely filtered by RLS or client-side filter
final incomingRequestsProvider = FutureProvider<List<Participant>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  // Query participants, joining the listing details and the applicant's profile
  final List<dynamic> response = await supabase
      .from('participants')
      .select('*, bolus_listings(*), profiles:user_id(*)')
      .eq('status', 'pending')
      .order('created_at', ascending: false);

  final List<Participant> allRequests = response
      .map((json) => Participant.fromJson(json as Map<String, dynamic>))
      .toList();

  // Filter: Only return requests where the listing owner is the current user
  return allRequests.where((req) => req.listing?.userId == user.id).toList();
});

// Future Provider for Active Conversations
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  // Fetch all conversations joined with listing details
  final List<dynamic> response = await supabase
      .from('conversations')
      .select('*, bolus_listings(*)')
      .order('created_at', ascending: false);

  final List<Conversation> conversations = response
      .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
      .toList();

  // In a robust implementation, a user can only see conversations for listings
  // they own or where they are an approved participant. RLS should enforce this.
  // We can also perform client-side filtering if needed, but RLS on conversations table is better:
  // "exists (select 1 from participants where listing_id = conversations.listing_id and user_id = auth.uid() and status = 'approved') 
  //  or exists (select 1 from bolus_listings where id = conversations.listing_id and user_id = auth.uid())"
  return conversations;
});

// Stream Provider for messages in a conversation
final chatMessagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, conversationId) {
  final supabase = ref.watch(supabaseClientProvider);

  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at', ascending: true)
      .map((data) => data.map((json) => Message.fromJson(json)).toList());
});

// Future Provider to check if a user has already requested to join a listing
final hasAlreadyRequestedProvider = FutureProvider.family<bool, String>((ref, listingId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final data = await supabase
      .from('participants')
      .select('id')
      .eq('listing_id', listingId)
      .eq('user_id', user.id)
      .maybeSingle();

  return data != null;
});
