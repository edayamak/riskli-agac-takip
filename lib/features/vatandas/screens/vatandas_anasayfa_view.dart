import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bildirim_model.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/firestore_service.dart';



class VatandasAnasayfaView extends StatelessWidget {
  final KullaniciModel kullanici;
  final void Function(int index) sekmeyeGit;

  const VatandasAnasayfaView({
    super.key,
    required this.kullanici,
    required this.sekmeyeGit,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<BildirimModel>>(
      stream: firestoreService.kullaniciBildirimleriStream(kullanici.kullaniciId),
      builder: (context, snapshot) {
        final bildirimler = snapshot.data ?? [];

        int say(BildirimDurumu durum) =>
            bildirimler.where((b) => b.durum == durum).length;

        final devamEdenSayisi = bildirimler
            .where((b) => b.durum != BildirimDurumu.kapatildi)
            .length;

        final sonBildirimler = bildirimler.take(3).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            Text('Hoş geldin, ${kullanici.ad}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              devamEdenSayisi > 0
                  ? '$devamEdenSayisi bildiriminiz takip ediliyor'
                  : 'Riskli bir ağaç mı gördünüz?',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 20),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _istatistikKarti('Toplam Bildirim', bildirimler.length, AppColors.primary, Icons.park),
                _istatistikKarti(
                  'Devam Eden',
                  bildirimler.where((b) => b.durum != BildirimDurumu.kapatildi && b.durum != BildirimDurumu.mudahaleEdildi).length,
                  AppColors.warning,
                  Icons.hourglass_empty,
                ),
                _istatistikKarti(
                  'Tamamlanan',
                  say(BildirimDurumu.mudahaleEdildi) + say(BildirimDurumu.kapatildi),
                  AppColors.success,
                  Icons.check_circle,
                ),
                _istatistikKarti(
                  'Bu Ay',
                  bildirimler.where((b) {
                    final simdi = DateTime.now();
                    return b.olusturmaTarihi.year == simdi.year && b.olusturmaTarihi.month == simdi.month;
                  }).length,
                  AppColors.primaryLight,
                  Icons.calendar_today,
                ),
              ],
            ),

            

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Son Bildirimlerim', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => sekmeyeGit(1),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (sonBildirimler.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Henüz bildirim göndermediniz. Sağ alttaki + butonuyla ilk bildirimini oluşturabilirsin.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...sonBildirimler.map((b) => _mkKart(b)),
          ],
        );
      },
    );
  }

  Widget _istatistikKarti(String baslik, int sayi, Color renk, IconData ikon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(ikon, color: renk),
            Text('$sayi', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: renk)),
            Text(baslik, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _mkKart(BildirimModel b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.park, size: 16, color: AppColors.primary),
        ),
        title: Text(
          b.adres.isNotEmpty ? b.adres : 'Adres bilgisi yok',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${b.olusturmaTarihi.day}/${b.olusturmaTarihi.month}/${b.olusturmaTarihi.year}',
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}