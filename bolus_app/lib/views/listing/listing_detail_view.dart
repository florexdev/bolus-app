import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';

class ListingDetailView extends StatefulWidget {
  final Map<String, dynamic> listing;

  const ListingDetailView({super.key, required this.listing});

  @override
  State<ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends State<ListingDetailView> {
  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _applyToListing() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception("Oturum açık değil.");

      if (widget.listing['user_id'] == currentUser.id) {
        throw Exception("Kendi açtığın ilana başvuru yapamazsın kanka.");
      }

      // participants tablosuna başvuru satırı ekliyoruz
      await _supabase.from('participants').insert({
        'listing_id': widget.listing['id'],
        'user_id': currentUser.id,
        'status': 'pending', // Onay bekliyor durumu
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Başvuru isteğin ilan sahibine iletildi!"),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.listing['category'] ?? 'Diğer';
    final title = widget.listing['title'] ?? 'Başlıksız İlan';
    final description = widget.listing['description'] ?? 'Açıklama yok.';
    final cost = widget.listing['per_person_cost']?.toString() ?? '0';
    final currentParticipants = widget.listing['current_participants'] ?? 1;
    final maxParticipants = widget.listing['max_participants'] ?? 1;
    final isFull = currentParticipants >= maxParticipants;

    return Scaffold(
      appBar: AppBar(
        title: const Text("İlan Detayı", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kategori Etiketi ve Fiyat (Hatalı kısım spaceBetween olarak düzeltildi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(category),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$cost TL / ay",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Başlık
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),

            // Kontenjan Bilgisi
            Row(
              children: [
                const Icon(Icons.people_outline, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Mevcut Durum: $currentParticipants / $maxParticipants Kişi",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Detaylı Açıklama
            const Text(
              "Bölüşme Detayları",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
            ),
            const Spacer(),

            // Başvuru Butonu
            ElevatedButton(
              onPressed: (_isLoading || isFull) ? null : _applyToListing,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isFull ? "Kontenjan Dolu" : "Maliyete Ortak Ol",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
