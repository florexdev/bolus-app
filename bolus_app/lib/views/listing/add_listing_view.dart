import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';

class AddListingView extends StatefulWidget {
  const AddListingView({super.key});

  @override
  State<AddListingView> createState() => _AddListingViewState();
}

class _AddListingViewState extends State<AddListingView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  String _selectedCategory = "Abonelik";
  final List<String> _categories = ["Abonelik", "Yolculuk", "Ev / Oda", "Alışveriş"];
  
  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _createListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception("Oturum açık değil.");

      // Supabase bolus_listings tablosuna veri yazıyoruz
      await _supabase.from('bolus_listings').insert({
        'user_id': currentUser.id,
        'category': _selectedCategory,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'per_person_cost': double.parse(_costController.text.trim()),
        'max_participants': int.parse(_maxParticipantsController.text.trim()),
        'current_participants': 1, // İlanı açan kişi otomatik dahil
        'is_active': true,
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(), // 30 gün geçerli
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İlan başarıyla yayınlandı!"), backgroundColor: AppColors.primary),
        );
        Navigator.of(context).pop(true); // Başarılı olunca ana sayfaya dön ve yenileme sinyali ver
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
                value: _selectedCategory,
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
                validator: (val) => val == null || val.isEmpty ? "Başlık boş bırakılamaz" : null,
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
                validator: (val) => val == null || val.isEmpty ? "Açıklama boş bırakılamaz" : null,
              ),
              const SizedBox(height: 20),

              // Kişi Başı Ücret ve Maksimum Katılımcı
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Kişi Başı Maliyet (TL)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? "Maliyet giriniz" : null,
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
                      validator: (val) => val == null || val.isEmpty ? "Kişi sayısı giriniz" : null,
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
