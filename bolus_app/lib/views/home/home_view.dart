import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../auth/auth_view.dart';
import '../listing/add_listing_view.dart';

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

            // Kategori Butonları (Yatay Kaydırılabilir ve Dinamik)
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

            // İlanlar Listesi (Şimdilik Tasarım Amaçlı Statik)
            Expanded(
              child: ListView.builder(
                itemCount: 3, 
                itemBuilder: (context, index) {
                  return _buildListingCard();
                },
              ),
            ),
          ],
        ),
      ),
      // Yeni İlan Ekleme Butonu (AddListingView'a Bağlandı)
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
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

  // İlan Kart Tasarımı
  Widget _buildListingCard() {
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
                  child: const Text(
                    "Abonelik",
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const Text(
                  "45 TL / ay",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "YouTube Premium Aile Üyeliği Ortaklığı",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Grupta son 2 kişilik yer kaldı. edu.tr doğrulaması olanlar önceliklidir.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people_outline, size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text("3 / 5 Kişi", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
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
