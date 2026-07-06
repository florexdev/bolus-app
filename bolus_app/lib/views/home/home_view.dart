import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/providers/supabase_providers.dart';
import '../../models/listing.dart';
import '../chat/conversations_view.dart';
import '../listing/add_listing_view.dart';
import '../listing/listing_detail_view.dart';
import '../listing/requests_view.dart';
import '../profile/profile_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  String _selectedCategory = "Hepsi";
  final List<String> _categories = ["Hepsi", "Abonelik", "Yolculuk", "Ev / Oda", "Alışveriş"];

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsStreamProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.appName,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            tooltip: "Mesajlarım",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ConversationsView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            tooltip: "Başvurular",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RequestsView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: "Profilim",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileView()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selam! 👋",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const Text(
              "Kampüsteki güncel maliyet ortaklıklarına göz at.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((category) {
                  return _buildCategoryChip(category, isActive: _selectedCategory == category);
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: listingsAsync.when(
                data: (listings) {
                  if (listings.isEmpty) {
                    return const Center(
                      child: Text(
                        "Bu kategoride henüz aktif bir bölüşme ilanı yok.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return _buildListingCard(listing);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    "Veriler yüklenirken hata oluştu kanka: ${err.toString()}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const AddListingView()),
          );
          if (result == true) {
            // Refresh feed if needed (handled automatically by StreamProvider)
          }
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isActive ? Colors.white : AppColors.secondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _selectedCategory = label;
            });
          }
        },
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    listing.category,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  "${listing.perPersonCost.toStringAsFixed(0)} TL / ay",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              listing.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              listing.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "${listing.currentParticipants} / ${listing.maxParticipants} Kişi",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ListingDetailView(listing: listing),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Text("Detayları Gör", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
