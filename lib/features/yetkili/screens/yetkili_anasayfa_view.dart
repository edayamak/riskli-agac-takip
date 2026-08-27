import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bildirim_model.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/firestore_service.dart';
import 'bildirim_inceleme_screen.dart';
import 'personel_listesi_screen.dart';
import 'kurum_listesi_screen.dart';
import '../../../models/kurum_model.dart';

class YetkiliAnasayfaView extends StatelessWidget {
  final KullaniciModel kullanici;
  final void Function(int index) sekmeyeGit;

  const YetkiliAnasayfaView({
    super.key,
    required this.kullanici,
    required this.sekmeyeGit,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<BildirimModel>>(
      stream: firestoreService.tumBildirimlerStream(),
      builder: (context, snapshot) {
        final bildirimler = snapshot.data ?? [];

        int say(BildirimDurumu durum) =>
            bildirimler.where((b) => b.durum == durum).length;

        final sonBildirimler = bildirimler.take(4).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Hoş geldin, ${kullanici.ad}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Bugünkü genel durum özeti', style: Theme.of(context).textTheme.bodySmall),

            const SizedBox(height: 20),

            // ---------------- ACİL UYARI KUTUSU ----------------
            StreamBuilder<List<BildirimModel>>(
              stream: firestoreService.acilBildirimlerStream(),
              builder: (context, acilSnapshot) {
                final acilBildirimler = acilSnapshot.data ?? [];
                if (acilBildirimler.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => sekmeyeGit(1),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${acilBildirimler.length} bildirim acil/yüksek risk seviyesinde, dikkat gerektiriyor.',
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.danger, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ---------------- İSTATİSTİK KARTLARI ----------------
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _istatistikKarti('Beklemede', say(BildirimDurumu.beklemede), AppColors.warning, Icons.hourglass_empty),
                _istatistikKarti('İncelendi', say(BildirimDurumu.incelendi), AppColors.primaryLight, Icons.search),
                _istatistikKarti('Görev Atandı', say(BildirimDurumu.gorevAtandi), AppColors.primary, Icons.assignment_ind),
                _istatistikKarti(
                  'Tamamlandı',
                  say(BildirimDurumu.mudahaleEdildi) + say(BildirimDurumu.kapatildi),
                  AppColors.success,
                  Icons.check_circle,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---------------- HIZLI ERİŞİM ----------------
            Text('Hızlı Erişim', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _hizliErisimButonu(
                    icon: Icons.list_alt,
                    etiket: 'Bildirim Listesi',
                    onTap: () => sekmeyeGit(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _hizliErisimButonu(
                    icon: Icons.map,
                    etiket: 'Harita',
                    onTap: () => sekmeyeGit(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _hizliErisimButonu(
                    icon: Icons.people,
                    etiket: 'Personel',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PersonelListesiScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---------------- KURUM/PERSONEL İSTATİSTİKLERİ ----------------
            Text('Sistem Bilgileri', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KurumListesiScreen()),
                      );
                    },
                    child: StreamBuilder<List<KurumModel>>(
                      stream: firestoreService.kurumlarStream(),
                      builder: (context, s) => _miniBilgiKarti('Kurum/Birim', (s.data ?? []).length, Icons.apartment),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: firestoreService.sahaPersoneliSayisiStream(),
                    builder: (context, s) => _miniBilgiKarti('Saha Personeli', s.data ?? 0, Icons.groups),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---------------- SON BİLDİRİMLER ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Son Bildirimler', style: Theme.of(context).textTheme.titleMedium),
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
                child: Text('Henüz bildirim yok.', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...sonBildirimler.map((b) => _sonBildirimKarti(context, b)),

            const SizedBox(height: 16),
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

  Widget _hizliErisimButonu({
    required IconData icon,
    required String etiket,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(etiket, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBilgiKarti(String baslik, int sayi, IconData ikon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            Icon(ikon, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$sayi', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(baslik, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sonBildirimKarti(BuildContext context, BildirimModel bildirim) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.park, size: 16, color: AppColors.primary),
        ),
        title: Text(_riskTipiEtiket(bildirim.riskTipi), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(
          bildirim.adres.isNotEmpty ? bildirim.adres : 'Adres bilgisi yok',
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BildirimIncelemeScreen(bildirim: bildirim, yetkili: kullanici),
            ),
          );
        },
      ),
    );
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