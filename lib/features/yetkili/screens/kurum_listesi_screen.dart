import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/kurum_model.dart';
import '../../../services/firestore_service.dart';

class KurumListesiScreen extends StatelessWidget {
  const KurumListesiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurumlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'Kurum Ekle',
            onPressed: () => _kurumEkleDialogunuAc(context, firestoreService),
          ),
        ],
      ),
      body: StreamBuilder<List<KurumModel>>(
        stream: firestoreService.kurumlarStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final kurumlar = snapshot.data ?? [];

          if (kurumlar.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.apartment, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text(
                      'Henüz kayıtlı kurum yok.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('İlk Kurumu Ekle'),
                      onPressed: () => _kurumEkleDialogunuAc(context, firestoreService),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: kurumlar.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final kurum = kurumlar[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.apartment, color: Colors.white, size: 20),
                  ),
                  title: Text(kurum.kurumAdi, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: kurum.aciklama.isNotEmpty ? Text(kurum.aciklama) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    onPressed: () => _silOnayla(context, firestoreService, kurum),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _kurumEkleDialogunuAc(BuildContext context, FirestoreService firestoreService) async {
    final adController = TextEditingController();
    final aciklamaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Kurum Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adController,
              decoration: const InputDecoration(labelText: 'Kurum Adı *'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aciklamaController,
              decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () async {
              if (adController.text.trim().isEmpty) return;
              await firestoreService.kurumEkle(
                kurumAdi: adController.text.trim(),
                aciklama: aciklamaController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _silOnayla(BuildContext context, FirestoreService firestoreService, KurumModel kurum) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kurumu Sil'),
        content: Text('"${kurum.kurumAdi}" silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (onay == true) {
      await firestoreService.kurumSil(kurum.kurumId);
    }
  }
}