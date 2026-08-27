import 'package:flutter/material.dart';
import '../../../models/bildirim_model.dart';
import '../../../services/firestore_service.dart';
import 'bildirim_inceleme_screen.dart';
import '../../../models/kullanici_model.dart';

class BildirimListesiView extends StatefulWidget {
  final KullaniciModel yetkili;
  const BildirimListesiView({super.key, required this.yetkili});

  @override
  State<BildirimListesiView> createState() => _BildirimListesiViewState();
}

class _BildirimListesiViewState extends State<BildirimListesiView> {
  final FirestoreService _firestoreService = FirestoreService();

  BildirimDurumu? _secilenFiltre; // null = hepsi

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFiltreBar(),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<BildirimModel>>(
            stream: _firestoreService.tumBildirimlerStream(
              durum: _secilenFiltre,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
              }

              final bildirimler = snapshot.data ?? [];

              if (bildirimler.isEmpty) {
                return const Center(child: Text('Gösterilecek bildirim bulunamadı.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: bildirimler.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final bildirim = bildirimler[index];
                  return _BildirimKarti(bildirim: bildirim, yetkili: widget.yetkili);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltreBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _filtreChip('Tümü', null),
          const SizedBox(width: 8),
          _filtreChip('Beklemede', BildirimDurumu.beklemede),
          const SizedBox(width: 8),
          _filtreChip('İncelendi', BildirimDurumu.incelendi),
          const SizedBox(width: 8),
          _filtreChip('Görev Atandı', BildirimDurumu.gorevAtandi),
          const SizedBox(width: 8),
          _filtreChip('Müdahale Edildi', BildirimDurumu.mudahaleEdildi),
          const SizedBox(width: 8),
          _filtreChip('Kapatıldı', BildirimDurumu.kapatildi),
        ],
      ),
    );
  }

  Widget _filtreChip(String etiket, BildirimDurumu? durum) {
    final secili = _secilenFiltre == durum;
    return ChoiceChip(
      label: Text(etiket),
      selected: secili,
      onSelected: (_) {
        setState(() => _secilenFiltre = durum);
      },
    );
  }
}

class _BildirimKarti extends StatelessWidget {
  final BildirimModel bildirim;
  final KullaniciModel yetkili;
  const _BildirimKarti({required this.bildirim, required this.yetkili});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _durumRengi(bildirim.durum).withValues(alpha: 0.15),
          child: Icon(
            Icons.park,
            color: _durumRengi(bildirim.durum),
          ),
        ),
        title: Text(
          _riskTipiEtiket(bildirim.riskTipi),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              bildirim.adres.isNotEmpty
                  ? bildirim.adres
                  : '${bildirim.konumLat.toStringAsFixed(4)}, ${bildirim.konumLng.toStringAsFixed(4)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              bildirim.aciklama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _durumRozeti(bildirim.durum),
            if (bildirim.riskSeviyesi != RiskSeviyesi.belirlenmedi) ...[
              const SizedBox(height: 4),
              _riskSeviyesiRozeti(bildirim.riskSeviyesi),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BildirimIncelemeScreen(
                bildirim: bildirim,
                yetkili: yetkili,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _durumRozeti(BildirimDurumu durum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _durumRengi(durum).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _durumEtiket(durum),
        style: TextStyle(
          color: _durumRengi(durum),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _riskSeviyesiRozeti(RiskSeviyesi seviye) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _riskSeviyesiEtiket(seviye),
        style: const TextStyle(
          color: Colors.deepOrange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _durumRengi(BildirimDurumu durum) {
    switch (durum) {
      case BildirimDurumu.beklemede:
        return Colors.orange;
      case BildirimDurumu.incelendi:
        return Colors.blue;
      case BildirimDurumu.gorevAtandi:
        return Colors.purple;
      case BildirimDurumu.mudahaleEdildi:
        return Colors.teal;
      case BildirimDurumu.kapatildi:
        return Colors.grey;
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

  String _riskSeviyesiEtiket(RiskSeviyesi seviye) {
    switch (seviye) {
      case RiskSeviyesi.belirlenmedi:
        return '';
      case RiskSeviyesi.dusuk:
        return 'Düşük';
      case RiskSeviyesi.orta:
        return 'Orta';
      case RiskSeviyesi.yuksek:
        return 'Yüksek';
      case RiskSeviyesi.acil:
        return 'Acil';
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