import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/supabase_providers.dart';
import '../../models/listing.dart';
import 'requests_view.dart';

class ListingDetailView extends ConsumerStatefulWidget {
  final Listing listing;

  const ListingDetailView({super.key, required this.listing});

  @override
  ConsumerState<ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends ConsumerState<ListingDetailView> {
  bool _isLoading = false;

  Future<void> _applyToListing() async {
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw Exception("Oturum açık değil.");

      // Check double application again
      final alreadyRequested = await ref.read(hasAlreadyRequestedProvider(widget.listing.id).future);
      if (alreadyRequested) {
        throw Exception("Bu ilana zaten başvuru yaptın.");
      }

      await supabase.from('participants').insert({
        'listing_id': widget.listing.id,
        'user_id': currentUser.id,
        'status': 'pending', 
      });

      // Invalidate duplicate request checker so it refreshes immediately
      ref.invalidate(hasAlreadyRequestedProvider(widget.listing.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Başvuru isteğin ilan sahibine iletildi!"),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
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
    final currentUser = ref.watch(currentUserProvider);
    final isMyListing = widget.listing.userId == currentUser?.id;

    // Fetch the status of applicant request
    final hasAlreadyRequestedAsync = ref.watch(hasAlreadyRequestedProvider(widget.listing.id));
    // Fetch owner profile details
    final ownerProfileAsync = ref.watch(profileProvider(widget.listing.userId));

    final category = widget.listing.category;
    final title = widget.listing.title;
    final description = widget.listing.description;
    final cost = widget.listing.perPersonCost.toStringAsFixed(0);
    final currentParticipants = widget.listing.currentParticipants;
    final maxParticipants = widget.listing.maxParticipants;
    final isFull = currentParticipants >= maxParticipants;

    return Scaffold(
      appBar: AppBar(
        title: const Text("İlan Detayı", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(category),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$cost TL / ay",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),

            // Owner details card
            ownerProfileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName ?? "Bölüş Üyesi",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            Text(
                              profile.email,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "İlan Sahibi",
                          style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SizedBox.shrink(),
            ),

            Row(
              children: [
                const Icon(Icons.people_outline, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Mevcut Durum: $currentParticipants / $maxParticipants Kişi",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              "Bölüşme Detayları",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Smart Action Button Area
            hasAlreadyRequestedAsync.when(
              data: (alreadyApplied) {
                final bool shouldDisable = isFull || alreadyApplied || _isLoading;
                
                String buttonText = "Maliyete Ortak Ol";
                if (isMyListing) {
                  buttonText = "Gelen Başvuruları Gör";
                } else if (alreadyApplied) {
                  buttonText = "Başvuru Yapıldı (Onay Bekliyor)";
                } else if (isFull) {
                  buttonText = "Kontenjan Dolu";
                }

                return ElevatedButton(
                  onPressed: shouldDisable && !isMyListing
                      ? null
                      : () {
                          if (isMyListing) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const RequestsView()),
                            );
                          } else {
                            _applyToListing();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMyListing ? AppColors.secondary : (alreadyApplied ? Colors.grey : AppColors.primary),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          buttonText,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                );
              },
              loading: () => const ElevatedButton(
                onPressed: null,
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => ElevatedButton(
                onPressed: isFull ? null : _applyToListing,
                child: const Text("Maliyete Ortak Ol"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
