import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/gorev_model.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/firestore_service.dart';
import 'gorev_detay_screen.dart';

class SahaAnasayfaView extends StatelessWidget {
  final KullaniciModel kullanici;
  final void Function(int index) sekmeyeGit;

  const SahaAnasayfaView({
    super.key,
    required this.kullanici,
    required this.sekmeyeGit,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<GorevModel>>(
      stream: firestoreService.personelGorevleriStream(kullanici.kullaniciId),
      builder: (context, snapshot) {
        final gorevler = snapshot.data ?? [];

        int say(GorevDurumu durum) => gorevler.where((g) => g.durum == durum).length;

        final bekleyenGorevler = gorevler
            .where((g) => g.durum != GorevDurumu.tamamlandi)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Hoş geldin, ${kullanici.ad}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              bekleyenGorevler.isNotEmpty
                  ? '${bekleyenGorevler.length} göreviniz devam ediyor'
                  : 'Şu an bekleyen bir göreviniz yok',
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
                _istatistikKarti('Atandı', say(GorevDurumu.atandi), AppColors.warning, Icons.assignment_late),
                _istatistikKarti('Devam Ediyor', say(GorevDurumu.devamEdiyor), AppColors.primaryLight, Icons.build_circle),
                _istatistikKarti('Tamamlandı', say(GorevDurumu.tamamlandi), AppColors.success, Icons.check_circle),
                _istatistikKarti('Toplam Görev', gorevler.length, AppColors.primary, Icons.list_alt),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bekleyen Görevler', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => sekmeyeGit(1),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 4),

            if (bekleyenGorevler.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Şu an size atanmış aktif bir görev bulunmuyor.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...bekleyenGorevler.take(4).map((g) => _gorevKarti(context, g)),
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

  Widget _gorevKarti(BuildContext context, GorevModel gorev) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _oncelikRengi(gorev.oncelik).withValues(alpha: 0.15),
          child: Icon(Icons.task_alt, size: 16, color: _oncelikRengi(gorev.oncelik)),
        ),
        title: Text('Öncelik: ${_oncelikEtiket(gorev.oncelik)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('Durum: ${_durumEtiket(gorev.durum)}', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GorevDetayScreen(gorev: gorev)),
          );
        },
      ),
    );
  }

  Color _oncelikRengi(GorevOncelik oncelik) {
    switch (oncelik) {
      case GorevOncelik.dusuk:
        return AppColors.success;
      case GorevOncelik.orta:
        return AppColors.warning;
      case GorevOncelik.yuksek:
        return Colors.deepOrange;
      case GorevOncelik.acil:
        return AppColors.danger;
    }
  }

  String _oncelikEtiket(GorevOncelik oncelik) {
    switch (oncelik) {
      case GorevOncelik.dusuk:
        return 'Düşük';
      case GorevOncelik.orta:
        return 'Orta';
      case GorevOncelik.yuksek:
        return 'Yüksek';
      case GorevOncelik.acil:
        return 'Acil';
    }
  }

  String _durumEtiket(GorevDurumu durum) {
    switch (durum) {
      case GorevDurumu.atandi:
        return 'Atandı';
      case GorevDurumu.devamEdiyor:
        return 'Devam Ediyor';
      case GorevDurumu.tamamlandi:
        return 'Tamamlandı';
    }
  }
}