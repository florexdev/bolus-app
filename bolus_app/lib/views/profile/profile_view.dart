import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/supabase_providers.dart';
import '../auth/auth_view.dart';
import 'edit_profile_view.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  Future<void> _signOut() async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final myProfileAsync = ref.watch(myProfileProvider);

    final String fallbackEmail = user?.email ?? "E-posta bulunamadı";
    final String fallbackUserId = user?.id ?? "ID bulunamadı";
    final String fallbackUniversity = fallbackEmail.contains('@') 
        ? fallbackEmail.split('@')[1] 
        : "Doğrulanmış Kampüs";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          myProfileAsync.when(
            data: (profile) => IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: "Profili Düzenle",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditProfileView(currentProfile: profile),
                  ),
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: myProfileAsync.when(
        data: (profile) {
          final email = profile?.email ?? fallbackEmail;
          final fullName = profile?.fullName ?? "Bölüş Üyesi";
          final university = profile?.university ?? fallbackUniversity;
          final city = profile?.city ?? "Şehir seçilmedi";
          final myo = profile?.myo;
          final bio = profile?.bio;
          final avatarUrl = profile?.avatarUrl;
          final userId = profile?.id ?? fallbackUserId;

          // Masked student-like UID: e.g. BLS-E83D6334
          final formattedUid = userId.length > 8 
              ? "BLS-${userId.split('-').last.toUpperCase()}"
              : userId;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Profil Avatarı (NetworkImage support)
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? const Icon(Icons.school_outlined, size: 50, color: AppColors.primary)
                            : null,
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
                const SizedBox(height: 16),
                
                // İsim Soyisim
                Center(
                  child: Text(
                    fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                ),

                // Biyografi (varsa)
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Kullanıcı Bilgi Kartı
                Expanded(
                  child: ListView(
                    children: [
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
                              _buildProfileRow(Icons.location_on_outlined, "Şehir", city),
                              const Divider(height: 24),
                              _buildProfileRow(Icons.account_balance_outlined, "Üniversite", university),
                              if (myo != null && myo.isNotEmpty) ...[
                                const Divider(height: 24),
                                _buildProfileRow(Icons.business_outlined, "Meslek Yüksekokulu (MYO)", myo),
                              ],
                              const Divider(height: 24),
                              _buildProfileRow(
                                Icons.fingerprint_outlined, 
                                "Öğrenci Kodu", 
                                formattedUid,
                                trailing: IconButton(
                                  icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: userId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Orijinal UID panoya kopyalandı!")),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

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
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text("Profil bilgileri yüklenemedi: ${err.toString()}"),
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value, {Widget? trailing}) {
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
        ?trailing,
      ],
    );
  }
}
