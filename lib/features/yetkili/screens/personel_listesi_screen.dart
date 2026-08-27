import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/firestore_service.dart';
import 'personel_ekle_screen.dart';
import 'personel_duzenle_screen.dart';

class PersonelListesiScreen extends StatelessWidget {
  const PersonelListesiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Listesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Personel Ekle',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonelEkleScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<KullaniciModel>>(
        stream: firestoreService.personelListesiStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final personelListesi = snapshot.data ?? [];

          if (personelListesi.isEmpty) {
            return const Center(child: Text('Kayıtlı personel bulunamadı.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: personelListesi.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final personel = personelListesi[index];
              return _PersonelKarti(personel: personel);
            },
          );
        },
      ),
    );
  }
}

class _PersonelKarti extends StatelessWidget {
  final KullaniciModel personel;
  const _PersonelKarti({required this.personel});

  Future<void> _silOnayla(BuildContext context) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli Sil'),
        content: Text('${personel.tamAd} adlı personelin profili silinecek. Emin misiniz?'),
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
      await FirestoreService().personelSil(personel.kullaniciId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personel silindi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolEtiketi = personel.rol == KullaniciRol.yetkili ? 'Yetkili Personel' : 'Saha Personeli';
    final rolRengi = personel.rol == KullaniciRol.yetkili ? AppColors.primary : AppColors.success;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.background,
          backgroundImage: personel.avatarId != null
              ? AssetImage('assets/images/avatars/${personel.avatarId}.png')
              : null,
          child: personel.avatarId == null
              ? Text(
                  personel.ad.isNotEmpty ? personel.ad[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                )
              : null,
        ),
        title: Text(personel.tamAd, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: rolRengi.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(rolEtiketi, style: TextStyle(color: rolRengi, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Text(personel.telefon.isNotEmpty ? personel.telefon : 'Telefon yok', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () => _silOnayla(context),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PersonelDuzenleScreen(personel: personel)),
          );
        },
      ),
    );
  }
}