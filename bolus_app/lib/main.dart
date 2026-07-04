import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/colors.dart';
import 'core/constants/strings.dart';
import 'views/auth/auth_view.dart';

void main() async {
  // Flutter binding süreçlerinin başlatılması
  WidgetsFlutterBinding.ensureInitialized();

  // Bilgisayarında Docker üzerinde çalışan yerel Supabase emülatörüne bağlanıyoruz
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
    // Projeyi başlattığında terminalin sana ürettiği yerel publishable key
    anonKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH', 
  );

  // Uygulamayı tüm Riverpod bileşenlerini yönetebilmek için ProviderScope ile sarıyoruz
  runApp(
    const ProviderScope(
      child: BolusApp(),
    ),
  );
}

class BolusApp extends StatelessWidget {
  const BolusApp({super.key});

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
      // Uygulamanın açılış rotasını Giriş/Kayıt ekranına yönlendiriyoruz
      home: const AuthView(),
    );
  }
}
