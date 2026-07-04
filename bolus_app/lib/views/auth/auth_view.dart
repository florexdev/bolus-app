import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/colors.dart';

import '../../core/constants/strings.dart';

import '../home/home_view.dart';


class AuthView extends StatefulWidget {

  const AuthView({super.key});


  @override

  State<AuthView> createState() => _AuthViewState();

}


class _AuthViewState extends State<AuthView> {

  final SupabaseClient _supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  

  bool _isSignUp = false;

  bool _isLoading = false;


  @override

  void dispose() {

    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();

  }


  // Kimlik doğrulama ana fonksiyonu

  Future<void> _handleAuth() async {

    if (!_formKey.currentState!.validate()) return;


    setState(() => _isLoading = true);

    final email = _emailController.text.trim();

    final password = _passwordController.text.trim();


    try {

      if (_isSignUp) {

        // .edu.tr Uzantı Doğrulaması (İstemci Tarafı Güvenlik Duvarı)

        if (!email.endsWith('.edu.tr')) {

          throw Exception("Bölüş sadece üniversite öğrencilerine özeldir.\nLütfen '.edu.tr' uzantılı adresinizi kullanın.");

        }


        // Kayıt Olma İşlemi

        await _supabase.auth.signUp(email: email, password: password);

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            const SnackBar(

              content: Text("Kayıt başarılı! Giriş yapabilirsiniz kanka."),

              backgroundColor: AppColors.primary,

            ),

          );

          setState(() => _isSignUp = false);

        }

      } else {

        // Giriş Yapma İşlemi

        await _supabase.auth.signInWithPassword(email: email, password: password);

        if (mounted) {

          // HATA DÜZELTİLDİ: Dinamik olan HomeView önündeki const kaldırıldı

          Navigator.of(context).pushReplacement(

            MaterialPageRoute(builder: (context) => const HomeView()),

          );

        }

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

      if (mounted) setState(() => _isLoading = false);

    }

  }


  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,

      body: Center(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24.0),

          child: Form(

            key: _formKey,

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                // Logo ve Başlık Alanı

                const Center(

                  child: Text(

                    "🥬",

                    style: TextStyle(fontSize: 72),

                  ),

                ),

                const SizedBox(height: 12),

                const Center(

                  child: Text(

                    AppStrings.appName,

                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),

                  ),

                ),

                Center(

                  child: Text(

                    _isSignUp ? "Kampüse hemen katıl kanka." : "Masrafı bölüşmeye hazır mısın?",

                    style: const TextStyle(fontSize: 14, color: Colors.grey),

                  ),

                ),

                const SizedBox(height: 40),


                // E-posta İnput Alanı

                TextFormField(

                  controller: _emailController,

                  keyboardType: TextInputType.emailAddress,

                  decoration: InputDecoration(

                    labelText: "Öğrenci E-postası (.edu.tr)",

                    prefixIcon: const Icon(Icons.school_outlined, color: AppColors.primary),

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                  ),

                  validator: (value) {

                    if (value == null || value.trim().isEmpty) {

                      return "E-posta alanını boş bırakamazsın.";

                    }

                    if (_isSignUp && !value.trim().endsWith('.edu.tr')) {

                      return "Sadece .edu.tr uzantılı mailler kabul edilir.";

                    }

                    return null;

                  },

                ),

                const SizedBox(height: 16),


                // Şifre İnput Alanı

                TextFormField(

                  controller: _passwordController,

                  obscureText: true,

                  decoration: InputDecoration(

                    labelText: "Şifre",

                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                  ),

                  validator: (value) {

                    if (value == null || value.trim().isEmpty) {

                      return "Şifre alanını boş bırakamazsın.";

                    }

                    if (value.length < 6) {

                      return "Şifre en az 6 karakter olmalıdır.";

                    }

                    return null;

                  },

                ),

                const SizedBox(height: 24),


                // Giriş / Kayıt Butonu

                ElevatedButton(

                  onPressed: _isLoading ? null : _handleAuth,

                  style: ElevatedButton.styleFrom(

                    backgroundColor: AppColors.primary,

                    foregroundColor: Colors.white,

                    padding: const EdgeInsets.symmetric(vertical: 16),

                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                  ),

                  child: _isLoading

                      ? const CircularProgressIndicator(color: Colors.white)

                      : Text(

                          _isSignUp ? "Kayıt Ol" : "Giriş Yap",

                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

                        ),

                ),

                const SizedBox(height: 16),


                // Ekran Değiştirme Alt Butonu

                TextButton(

                  onPressed: () {

                    setState(() {

                      _isSignUp = !_isSignUp;

                      _formKey.currentState?.reset();

                    });

                  },

                  child: Text(

                    _isSignUp ? "Zaten hesabın var mı? Giriş Yap" : "Hesabın yok mu? Hemen Kayıt Ol",

                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}
