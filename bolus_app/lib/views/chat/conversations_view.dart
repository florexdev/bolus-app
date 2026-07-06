import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/supabase_providers.dart';
import 'chat_view.dart';

class ConversationsView extends ConsumerStatefulWidget {
  const ConversationsView({super.key});

  @override
  ConsumerState<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends ConsumerState<ConversationsView> {
  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mesajlarım", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(conversationsProvider);
          await ref.read(conversationsProvider.future);
        },
        child: conversationsAsync.when(
          data: (conversations) {
            if (conversations.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Center(
                      child: Text(
                        "Henüz aktif bir sohbet odan yok kanka.\nOrtaklık istekleri onaylandığında burada görünecek.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final room = conversations[index];
                final listingTitle = room.listing?.title ?? "Maliyet Ortaklığı Grubu";
                final category = room.listing?.category ?? "Diğer";

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                    ),
                    title: Text(
                      listingTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      "Kategori: $category • Sohbet Aktif", 
                      style: const TextStyle(color: Colors.grey, fontSize: 12)
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatView(conversationId: room.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              "Sohbetler yüklenirken hata oluştu: ${err.toString()}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }
}
