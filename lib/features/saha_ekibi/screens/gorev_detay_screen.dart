import 'package:flutter/material.dart';
import '../../../models/gorev_model.dart';
import '../../../models/bildirim_model.dart';
import '../../../services/firestore_service.dart';
import 'mudahale_form_screen.dart';

class GorevDetayScreen extends StatelessWidget {
  final GorevModel gorev;
  const GorevDetayScreen({super.key, required this.gorev});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Görev Detayı')),
      body: FutureBuilder<BildirimModel?>(
        future: firestoreService.bildirimGetir(gorev.bildirimId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bildirim = snapshot.data;

          if (bildirim == null) {
            return const Center(
              child: Text('Bildirim bilgisi bulunamadı.'),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                _bilgiSatiri('Risk Tipi', _riskTipiEtiket(bildirim.riskTipi)),
                _bilgiSatiri(
                  'Risk Seviyesi',
                  _riskSeviyesiEtiket(bildirim.riskSeviyesi),
                ),
                _bilgiSatiri(
                  'Konum',
                  bildirim.adres.isNotEmpty
                      ? bildirim.adres
                      : '${bildirim.konumLat.toStringAsFixed(5)}, ${bildirim.konumLng.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Açıklama',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bildirim.aciklama.isNotEmpty
                        ? bildirim.aciklama
                        : 'Açıklama girilmemiş.',
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.build),
                  label: const Text('Müdahaleyi Başlat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MudahaleFormScreen(
                          gorev: gorev,
                          bildirim: bildirim,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _bilgiSatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              baslik,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(deger)),
        ],
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

  String _riskSeviyesiEtiket(RiskSeviyesi seviye) {
    switch (seviye) {
      case RiskSeviyesi.belirlenmedi:
        return 'Belirlenmedi';
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
}