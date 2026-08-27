import 'package:flutter/material.dart';
import '../../../models/kullanici_model.dart';
import '../../../models/gorev_model.dart';
import '../../../services/firestore_service.dart';
import 'gorev_detay_screen.dart';

class GorevlerimView extends StatelessWidget {
  final KullaniciModel kullanici;
  const GorevlerimView({super.key, required this.kullanici});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<GorevModel>>(
      stream: firestoreService.personelGorevleriStream(kullanici.kullaniciId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        }

        final gorevler = snapshot.data ?? [];

        if (gorevler.isEmpty) {
          return const Center(
            child: Text('Şu an size atanmış bir görev bulunmuyor.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: gorevler.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final gorev = gorevler[index];
            return _GorevKarti(gorev: gorev);
          },
        );
      },
    );
  }
}

class _GorevKarti extends StatelessWidget {
  final GorevModel gorev;
  const _GorevKarti({required this.gorev});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _oncelikRengi(gorev.oncelik).withValues(alpha: 0.15),
          child: Icon(Icons.task_alt, color: _oncelikRengi(gorev.oncelik)),
        ),
        title: Text('Öncelik: ${_oncelikEtiket(gorev.oncelik)}'),
        subtitle: Text('Durum: ${_durumEtiket(gorev.durum)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GorevDetayScreen(gorev: gorev),
            ),
          );
        },
      ),
    );
  }

  Color _oncelikRengi(GorevOncelik oncelik) {
    switch (oncelik) {
      case GorevOncelik.dusuk:
        return Colors.green;
      case GorevOncelik.orta:
        return Colors.orange;
      case GorevOncelik.yuksek:
        return Colors.deepOrange;
      case GorevOncelik.acil:
        return Colors.red;
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