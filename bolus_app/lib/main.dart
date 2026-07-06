import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/colors.dart';
import 'core/constants/strings.dart';
import 'views/auth/auth_view.dart';
import 'views/home/home_view.dart';

void main() async {
  // Flutter binding süreçlerinin başlatılması
  WidgetsFlutterBinding.ensureInitialized();

  // Bilgisayarında Docker üzerinde çalışan yerel Supabase emülatörüne bağlanıyoruz
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
    // Projeyi başlattığında terminalin sana ürettiği yerel publishable key
    publishableKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH', 
  );

  // Beni hatırla durumunu SharedPreferences üzerinden kontrol ediyoruz
  final prefs = await SharedPreferences.getInstance();
  final bool rememberMe = prefs.getBool('remember_me') ?? false;

  final session = Supabase.instance.client.auth.currentSession;
  if (session != null && !rememberMe) {
    // Beni hatırla seçilmemişse ama oturum varsa güvenli çıkış yapıyoruz
    await Supabase.instance.client.auth.signOut();
  }

  final Widget initialHome = (Supabase.instance.client.auth.currentUser != null && rememberMe)
      ? const HomeView()
      : const AuthView();

  // Uygulamayı tüm Riverpod bileşenlerini yönetebilmek için ProviderScope ile sarıyoruz
  runApp(
    ProviderScope(
      child: BolusApp(initialHome: initialHome),
    ),
  );
}

class BolusApp extends StatelessWidget {
  final Widget initialHome;
  
  const BolusApp({super.key, required this.initialHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false, // Debug bandını kaldırıyoruz
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background, // Kırık beyaz arka plan
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary, // Zümrüt Yeşili aksan rengi
          secondary: AppColors.secondary, // Slate Mavi/Lacivert
        ),
        useMaterial3: true,
      ),
      // Uygulamanın açılış rotasını belirliyoruz
      home: initialHome,
    );
  }
}
