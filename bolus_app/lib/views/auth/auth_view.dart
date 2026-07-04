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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _campusController = TextEditingController();
  
  bool _isSignUp = false;
  bool _isLoading = false;

  // Supabase istemcisini çağırıyoruz
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final campus = _campusController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Lütfen gerekli alanları doldurun.");
      return;
    }

    if (_isSignUp && (fullName.isEmpty || campus.isEmpty)) {
      _showSnackBar("Ad Soyad ve Kampüs alanları boş bırakılamaz.");
      return;
    }

    // Akademik E-posta Kontrolü (.edu.tr)
    if (_isSignUp && !email.endsWith('.edu.tr')) {
      _showSnackBar("Sadece .edu.tr uzantılı akademik e-postalar ile kayıt olunabilir.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // Supabase ile Kayıt Olma (Veriler trigger üzerinden profiles tablosuna akacak)
        await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'campus': campus,
          },
        );
        _showSnackBar("Kayıt başarılı! Giriş moduna geçip oturum açabilirsiniz.", isSuccess: true);
        setState(() {
          _isSignUp = false;
        });
      } else {
        // Supabase ile Giriş Yapma
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        _showSnackBar("Giriş başarılı!", isSuccess: true);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeView()),
          );
        }
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar("Beklenmedik bir hata oluştu.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.primary : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _campusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppStrings.appMotto,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.secondary, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 40),

                if (_isSignUp) ...[
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: "Ad Soyad",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _campusController,
                    decoration: InputDecoration(
                      labelText: "Kampüs / Üniversite",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Öğrenci E-postası (.edu.tr)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Şifre",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isSignUp ? "Kayıt Ol ve Başla" : "Giriş Yap",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp ? "Zaten hesabın var mı? Giriş Yap" : "Hesabın yok mu? Kampüse Katıl",
                    style: const TextStyle(color: AppColors.secondary),
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
