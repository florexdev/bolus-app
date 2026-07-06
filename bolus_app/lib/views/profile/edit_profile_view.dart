import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/supabase_providers.dart';
import '../../models/profile.dart';

class EditProfileView extends ConsumerStatefulWidget {
  final Profile? currentProfile;

  const EditProfileView({super.key, this.currentProfile});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();

  XFile? _imageFile;
  String? _currentAvatarUrl;

  Map<String, dynamic> _universityData = {};
  List<String> _cities = [];
  String? _selectedCity;

  List<dynamic> _universities = [];
  String? _selectedUniversity;

  List<dynamic> _myos = [];
  String? _selectedMyo;

  bool _isJsonLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentProfile != null) {
      _fullNameController.text = widget.currentProfile!.fullName ?? '';
      _bioController.text = widget.currentProfile!.bio ?? '';
      _currentAvatarUrl = widget.currentProfile!.avatarUrl;
    }
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    try {
      final String response = await rootBundle.loadString('universiteler_ve_myolar.json');
      final Map<String, dynamic> data = json.decode(response);
      
      setState(() {
        _universityData = data;
        _cities = data.keys.toList()..sort();
        
        final profile = widget.currentProfile;
        if (profile != null && profile.city != null && _universityData.containsKey(profile.city)) {
          _selectedCity = profile.city;
          _universities = _universityData[_selectedCity]['universiteler'] ?? [];
          
          final uniObj = _universities.firstWhere(
            (u) => u['universite_adi'] == profile.university,
            orElse: () => null,
          );
          
          if (uniObj != null) {
            _selectedUniversity = uniObj['universite_adi'];
            _myos = uniObj['myolar'] ?? [];
            
            final myoObj = _myos.firstWhere(
              (m) => m['myo_adi'] == profile.myo,
              orElse: () => null,
            );
            if (myoObj != null) {
              _selectedMyo = myoObj['myo_adi'];
            }
          }
        }
        _isJsonLoading = false;
      });
    } catch (e) {
      setState(() => _isJsonLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Üniversite verileri yüklenemedi: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fotoğraf seçilemedi: $e")),
        );
      }
    }
  }

  void _onCityChanged(String? newCity) {
    if (newCity == null) return;
    setState(() {
      _selectedCity = newCity;
      _universities = _universityData[newCity]['universiteler'] ?? [];
      _selectedUniversity = null;
      _myos = [];
      _selectedMyo = null;
    });
  }

  void _onUniversityChanged(String? newUni) {
    if (newUni == null) return;
    final uniObj = _universities.firstWhere((u) => u['universite_adi'] == newUni);
    setState(() {
      _selectedUniversity = newUni;
      _myos = uniObj['myolar'] ?? [];
      _selectedMyo = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw Exception("Oturum açık değil.");

      String? avatarUrl = _currentAvatarUrl;

      // Local görsel seçildiyse Supabase Storage'a yüklüyoruz
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileExtension = _imageFile!.path.split('.').last.toLowerCase();
        final fileName = '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

        await supabase.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$fileExtension',
            upsert: true,
          ),
        );

        avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      await supabase.from('profiles').update({
        'full_name': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatar_url': avatarUrl,
        'city': _selectedCity,
        'university': _selectedUniversity,
        'myo': _selectedMyo,
      }).eq('id', currentUser.id);

      // Invalidate profiles cache to trigger refresh across views
      ref.invalidate(myProfileProvider);
      ref.invalidate(profileProvider(currentUser.id));
      ref.invalidate(listingsStreamProvider("Hepsi"));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil başarıyla güncellendi!"), backgroundColor: AppColors.primary),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${e.toString().replaceAll("Exception:", "")}"), 
            backgroundColor: Colors.redAccent
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;
    if (_imageFile != null) {
      avatarImage = FileImage(File(_imageFile!.path));
    } else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage(_currentAvatarUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profili Düzenle", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isJsonLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Fotoğraf seçme alanı
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        "Fotoğrafı Değiştirmek İçin Dokun",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ad Soyad
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: "Ad Soyad",
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? "Ad Soyad boş bırakılamaz" : null,
                    ),
                    const SizedBox(height: 20),

                    // Biyografi
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Biyografi",
                        hintText: "Kendinden bahset...",
                        prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Divider(height: 40),
                    const Text(
                      "Kampüs & Konum Bilgileri",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 16),

                    // Şehir Seçimi Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      decoration: InputDecoration(
                        labelText: "Şehir",
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _cities.map((city) {
                        return DropdownMenuItem(value: city, child: Text(city));
                      }).toList(),
                      onChanged: _onCityChanged,
                      validator: (val) => val == null ? "Şehir seçmelisiniz kanka" : null,
                    ),
                    const SizedBox(height: 20),

                    // Üniversite Seçimi Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUniversity,
                      decoration: InputDecoration(
                        labelText: "Üniversite",
                        prefixIcon: const Icon(Icons.school_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _universities.map((uni) {
                        final String uniName = uni['universite_adi'];
                        return DropdownMenuItem(
                          value: uniName,
                          child: Text(
                            uniName.length > 28 ? "${uniName.substring(0, 28)}..." : uniName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedCity == null ? null : _onUniversityChanged,
                      validator: (val) => val == null ? "Üniversite seçmelisiniz kanka" : null,
                    ),
                    const SizedBox(height: 20),

                    // MYO Seçimi Dropdown (Tercihe Bağlı)
                    if (_myos.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMyo,
                        decoration: InputDecoration(
                          labelText: "Meslek Yüksekokulu (Tercihe Bağlı)",
                          prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _myos.map((myo) {
                          final String myoName = myo['myo_adi'];
                          return DropdownMenuItem(
                            value: myoName,
                            child: Text(
                              myoName.length > 28 ? "${myoName.substring(0, 28)}..." : myoName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedMyo = val),
                      ),
                    const SizedBox(height: 32),

                    // Kaydet Butonu
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Profilimi Kaydet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
