import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/supabase_providers.dart';

class AddListingView extends ConsumerStatefulWidget {
  const AddListingView({super.key});

  @override
  ConsumerState<AddListingView> createState() => _AddListingViewState();
}

class _AddListingViewState extends ConsumerState<AddListingView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  String _selectedCategory = "Abonelik";
  final List<String> _categories = ["Abonelik", "Yolculuk", "Ev / Oda", "Alışveriş"];
  
  bool _isLoading = false;

  Future<void> _createListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw Exception("Oturum açık değil.");

      final double perPersonCost = double.parse(_costController.text.trim());
      final int maxParticipants = int.parse(_maxParticipantsController.text.trim());

      if (maxParticipants <= 1) {
        throw Exception("Toplam kişi sınırı kendiniz dahil en az 2 kişi olmalıdır.");
      }

      final myProfile = ref.read(myProfileProvider).value;
      final String? city = myProfile?.city;

      await supabase.from('bolus_listings').insert({
        'user_id': currentUser.id,
        'category': _selectedCategory,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'per_person_cost': perPersonCost,
        'max_participants': maxParticipants,
        'current_participants': 1, // İlanı açan kişi otomatik dahil
        'is_active': true,
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(), // 30 gün geçerli
        'city': city, // Kullanıcının profilindeki şehri ilana kopyalıyoruz
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İlan başarıyla yayınlandı!"), backgroundColor: AppColors.primary),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "")), 
            backgroundColor: Colors.redAccent
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Bölüşme İlanı", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kategori Seçimi
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Kategori",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 20),

              // İlan Başlığı
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "İlan Başlığı",
                  hintText: "Örn: Netflix UHD 4 Kişilik Ortaklık",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Başlık boş bırakılamaz" : null,
              ),
              const SizedBox(height: 20),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Detaylar ve Açıklama",
                  hintText: "Ödemelerin ne zaman yapılacağı, kurallar vb...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Açıklama boş bırakılamaz" : null,
              ),
              const SizedBox(height: 20),

              // Kişi Başı Ücret ve Maksimum Katılımcı
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Kişi Başı Maliyet (TL)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Maliyet giriniz";
                        if (double.tryParse(val.trim()) == null) return "Geçersiz sayı";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxParticipantsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Toplam Kişi Sınırı",
                        hintText: "Örn: 4",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Kişi sayısı giriniz";
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null) return "Geçersiz tam sayı";
                        if (parsed <= 1) return "En az 2 olmalı";
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // İlan Aç Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _createListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("İlanı Kampüste Yayınla", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
