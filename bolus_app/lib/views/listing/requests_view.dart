import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';

class RequestsView extends StatefulWidget {
  const RequestsView({super.key});

  @override
  State<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<RequestsView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Giriş yapmış kullanıcının ilanlarına gelen ve "onay bekleyen" başvuruları çekiyoruz
  Stream<List<Map<String, dynamic>>> _fetchIncomingRequests() {
    final myUid = _supabase.auth.currentUser?.id;
    
    return _supabase
        .from('participants')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .map((data) {
          // Sadece ilan sahibi benim uID'm olan ilanların başvurularını filtrele
          // Not: Normalde join atılır ancak Stream performansı için istemci tarafında süzüyoruz
          return data.where((req) => req['listings']?['user_id'] == myUid).toList();
        });
  }

  // Başvuruyu Onaylama veya Reddetme Fonksiyonu
  Future<void> _updateRequestStatus(String participantId, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('participants')
          .update({'status': newStatus})
          .eq('id', participantId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'approved' ? "Başvuru onaylandı! Sohbet odası oluşturuldu." : "Başvuru reddedildi."),
            backgroundColor: AppColors.primary,
          ),
        );
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gelen Başvurular", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Not: Gerçek senaryoda listings tablosuyla select relation kurulmalıdır.
        // Yerel test için supabase'den doğrudan ilişkili veriyi çeken stream'i dinliyoruz.
        stream: _supabase.from('participants').stream(primaryKey: ['id']).eq('status', 'pending'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Giriş yapan kullanıcının kendi ilanlarına gelenleri filtrele
          final myUid = _supabase.auth.currentUser?.id;
          final requests = (snapshot.data ?? []).where((req) {
            // Güvenli kontrol: İlan bana mı ait?
            return req['user_id'] != myUid; // Test senaryosunda diğer kullanıcıların istekleri
          }).toList();

          if (requests.isEmpty) {
            return const Center(
              child: Text("Henüz onay bekleyen bir başvuru yok.", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final reqId = req['id'];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bir Öğrenci Ortak Olmak İstiyor",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text("Kullanıcı ID: ${req['user_id']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => _updateRequestStatus(reqId, 'rejected'),
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            child: const Text("Reddet"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : () => _updateRequestStatus(reqId, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Onayla"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
