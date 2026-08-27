import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bildirim_model.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/firestore_service.dart';

class BildirimlerimView extends StatelessWidget {
  final KullaniciModel kullanici;
  const BildirimlerimView({super.key, required this.kullanici});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<BildirimModel>>(
      stream: firestoreService.kullaniciBildirimleriStream(kullanici.kullaniciId),
builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  if (snapshot.hasError) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Bir hata oluştu: ${snapshot.error}',
          style: const TextStyle(color: AppColors.danger, fontSize: 12),
        ),
      ),
    );
  }

  final bildirimler = snapshot.data ?? [];

        if (bildirimler.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Henüz bir bildiriminiz bulunmuyor.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bildirimler.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _bildirimKarti(bildirimler[index]),
        );
      },
    );
  }

  Widget _bildirimKarti(BildirimModel bildirim) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _riskTipiEtiket(bildirim.riskTipi),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                _durumRozeti(bildirim.durum),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              bildirim.adres.isNotEmpty ? bildirim.adres : 'Adres bilgisi yok',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              bildirim.aciklama,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${bildirim.olusturmaTarihi.day}/${bildirim.olusturmaTarihi.month}/${bildirim.olusturmaTarihi.year}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durumRozeti(BildirimDurumu durum) {
    final renk = _durumRengi(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _durumEtiket(durum),
        style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color _durumRengi(BildirimDurumu durum) {
    switch (durum) {
      case BildirimDurumu.beklemede:
        return AppColors.warning;
      case BildirimDurumu.incelendi:
        return AppColors.primaryLight;
      case BildirimDurumu.gorevAtandi:
        return AppColors.primary;
      case BildirimDurumu.mudahaleEdildi:
        return Colors.teal;
      case BildirimDurumu.kapatildi:
        return AppColors.textSecondary;
    }
  }

  String _durumEtiket(BildirimDurumu durum) {
    switch (durum) {
      case BildirimDurumu.beklemede:
        return 'Beklemede';
      case BildirimDurumu.incelendi:
        return 'İncelendi';
      case BildirimDurumu.gorevAtandi:
        return 'Görev Atandı';
      case BildirimDurumu.mudahaleEdildi:
        return 'Müdahale Edildi';
      case BildirimDurumu.kapatildi:
        return 'Kapatıldı';
    }
  }

  String _riskTipiEtiket(RiskTipi tip) {
    switch (tip) {
      case RiskTipi.kurumus:
        return 'Kurumuş Ağaç';
      case RiskTipi.hastalikli:
        return 'Hastalıklı Ağaç';
      case RiskTipi.devrilmeRiski:
        return 'Devrilme Riski';
      case RiskTipi.budamaIhtiyaci:
        return 'Budama İhtiyacı';
      case RiskTipi.firtinaRiski:
        return 'Fırtına Öncesi Risk';
    }
  }
}