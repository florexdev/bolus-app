import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import 'chat_view.dart';

class ConversationsView extends StatefulWidget {
  const ConversationsView({super.key});

  @override
  State<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<ConversationsView> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Kullanıcının dahil olduğu sohbet odalarını gerçek zamanlı getiren fonksiyon (Sıralama sütunu düzeltildi)
  Stream<List<Map<String, dynamic>>> _fetchConversations() {
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mesajlarım", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fetchConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Sohbetler yüklenirken hata oluştu: ${snapshot.error}"));
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return const Center(
              child: Text(
                "Henüz aktif bir sohbet odan yok kanka.\nOrtaklık istekleri onaylandığında burada görünecek.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final room = conversations[index];
              final roomId = room['id'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                  ),
                  title: Text(
                    "Sohbet Grubu (İlan ID: ${room['listing_id']?.toString().substring(0, 8)}...)",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Maliyet ortaklığı sohbeti aktif", style: TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                  onTap: () {
                    // Detaylı mesajlaşma ekranına yönlendiriyoruz
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatView(conversationId: roomId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
