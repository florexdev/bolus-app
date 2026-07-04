import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../auth/auth_view.dart';
import '../listing/add_listing_view.dart';
import '../listing/listing_detail_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Aktif seçili kategoriyi tutacak state değişkeni
  String _selectedCategory = "Hepsi";

  // Kategoriler listesi
  final List<String> _categories = ["Hepsi", "Abonelik", "Yolculuk", "Ev / Oda", "Alışveriş"];

  // Çıkış yapma fonksiyonu
  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthView()),
      );
    }
  }

  // Supabase'den ilanları çeyen canlı Stream fonksiyonu
  Stream<List<Map<String, dynamic>>> _fetchListings() {
    if (_selectedCategory != "Hepsi") {
      return _supabase
          .from('bolus_listings')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) => data.where((item) => item['category'] == _selectedCategory && item['is_active'] == true).toList());
    }

    return _supabase
        .from('bolus_listings')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.where((item) => item['is_active'] == true).toList());
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Çıkış Yap",
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kampüs Bilgisi Karşılama Alanı
            const Text(
              "Selam! 👋",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const Text(
              "Kampüsündeki güncel maliyet ortaklıklarına göz at.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Kategori Butonları
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

            // Canlı İlanlar Listesi
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _fetchListings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Veriler yüklenirken hata oluştu: ${snapshot.error}"));
                  }

                  final listings = snapshot.data ?? [];

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
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddListingView()),
          );
        },
      ),
    );
  }

  // Kategori Filtre Buton Tasarımı
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

  // İlan Kart Tasarımı (Detay Ekranına Bağlandı)
  Widget _buildListingCard(Map<String, dynamic> listing) {
    final category = listing['category'] ?? 'Diğer';
    final title = listing['title'] ?? 'Başlıksız İlan';
    final description = listing['description'] ?? 'Açıklama belirtilmemiş.';
    final cost = listing['per_person_cost']?.toString() ?? '0';
    final currentParticipants = listing['current_participants'] ?? 1;
    final maxParticipants = listing['max_participants'] ?? 1;

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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  "$cost TL / ay",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              description,
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
                    Text("$currentParticipants / $maxParticipants Kişi", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Detay Gör butonuna basılınca yeni ekranı açıyoruz
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
