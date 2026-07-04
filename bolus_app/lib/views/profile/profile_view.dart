import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../auth/auth_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _supabase.auth.currentUser;
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? "Öğrenci E-postası bulunamadı";
    final userId = _user?.id ?? "ID bulunamadı";
    final universityDomain = email.contains('@') ? email.split('@')[1] : "Doğrulanmış Kampüs";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Profil Avatarı (Hatalı const'lar tamamen temizlendi)
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.school_outlined, size: 50, color: AppColors.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Kullanıcı Bilgi Kartı
            Card(
              elevation: 0,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildProfileRow(Icons.email_outlined, "E-posta", email),
                    const Divider(height: 24),
                    _buildProfileRow(Icons.account_balance_outlined, "Kampüs / Üniversite", universityDomain),
                    const Divider(height: 24),
                    _buildProfileRow(Icons.fingerprint_outlined, "Öğrenci No / UID", userId.length > 12 ? "${userId.substring(0, 12)}..." : userId),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Akademik Güvenlik Bilgisi
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const ListTile(
                leading: Icon(Icons.shield_outlined, color: AppColors.primary),
                title: Text("Akademik Güvenlik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Hesabın .edu.tr uzantısı ile korunmaktadır.", style: TextStyle(fontSize: 12)),
              ),
            ),
            
            const Spacer(),

            // Oturumu Kapat Butonu
            ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text("Oturumu Kapat", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary)),
            ],
          ),
        ),
      ],
    );
  }
}
