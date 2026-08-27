import 'package:flutter/material.dart';
import '../../../models/bildirim_model.dart';
import '../../../services/firestore_service.dart';
import '../../../models/kullanici_model.dart';
import 'gorev_atama_screen.dart';

class BildirimIncelemeScreen extends StatefulWidget {
  final BildirimModel bildirim;
  final KullaniciModel yetkili;

  const BildirimIncelemeScreen({
    super.key,
    required this.bildirim,
    required this.yetkili,
  });

  @override
  State<BildirimIncelemeScreen> createState() =>
      _BildirimIncelemeScreenState();
}

class _BildirimIncelemeScreenState extends State<BildirimIncelemeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  RiskSeviyesi? _secilenRiskSeviyesi;
  bool _islemYapiliyor = false;
  String? _hataMesaji;

  @override
  void initState() {
    super.initState();
    // Eğer daha önce bir risk seviyesi atanmışsa onu göster
    if (widget.bildirim.riskSeviyesi != RiskSeviyesi.belirlenmedi) {
      _secilenRiskSeviyesi = widget.bildirim.riskSeviyesi;
    }
  }

  Future<void> _riskSeviyesiKaydet() async {
    if (_secilenRiskSeviyesi == null) {
      setState(() => _hataMesaji = 'Lütfen bir risk seviyesi seçin.');
      return;
    }

    setState(() {
      _islemYapiliyor = true;
      _hataMesaji = null;
    });

    try {
      await _firestoreService.bildirimIncele(
        bildirimId: widget.bildirim.bildirimId,
        riskSeviyesi: _secilenRiskSeviyesi!,
      );

      if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Risk seviyesi kaydedildi.')),
  );

  // Güncellenmiş bildirimi oluştur (yeni risk seviyesi ve durum ile)
  final guncellenmisBildirim = BildirimModel(
    bildirimId: widget.bildirim.bildirimId,
    bildirenKullaniciId: widget.bildirim.bildirenKullaniciId,
    konumLat: widget.bildirim.konumLat,
    konumLng: widget.bildirim.konumLng,
    adres: widget.bildirim.adres,
    fotograflar: widget.bildirim.fotograflar,
    aciklama: widget.bildirim.aciklama,
    riskTipi: widget.bildirim.riskTipi,
    riskSeviyesi: _secilenRiskSeviyesi!,
    durum: BildirimDurumu.incelendi,
    atananKurumId: widget.bildirim.atananKurumId,
    olusturmaTarihi: widget.bildirim.olusturmaTarihi,
  );

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => GorevAtamaScreen(
        bildirim: guncellenmisBildirim,
        yetkili: widget.yetkili,
      ),
    ),
  );
}
    } catch (e) {
      setState(() {
        _hataMesaji = 'İşlem başarısız oldu. Lütfen tekrar deneyin.';
        _islemYapiliyor = false;
      });
    }
  }

  Future<void> _kaydiKapat() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Kapat'),
        content: const Text(
          'Bu bildirim için müdahale gerekmediğini onaylıyor musunuz? '
          'Kayıt "Kapatıldı" olarak işaretlenecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet, Kapat'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    setState(() {
      _islemYapiliyor = true;
      _hataMesaji = null;
    });

    try {
      await _firestoreService.bildirimKapat(widget.bildirim.bildirimId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt kapatıldı.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _hataMesaji = 'İşlem başarısız oldu. Lütfen tekrar deneyin.';
        _islemYapiliyor = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  final bildirim = widget.bildirim;

  return Scaffold(
    appBar: AppBar(title: const Text('Bildirim İnceleme')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bilgiSatiri('Risk Tipi', _riskTipiEtiket(bildirim.riskTipi)),
            _bilgiSatiri(
              'Mevcut Durum',
              _durumEtiket(bildirim.durum),
            ),
            _bilgiSatiri(
              'Konum',
              bildirim.adres.isNotEmpty
                  ? bildirim.adres
                  : '${bildirim.konumLat.toStringAsFixed(5)}, ${bildirim.konumLng.toStringAsFixed(5)}',
            ),
            _bilgiSatiri(
              'Bildirim Tarihi',
              '${bildirim.olusturmaTarihi.day}/${bildirim.olusturmaTarihi.month}/${bildirim.olusturmaTarihi.year} '
                  '${bildirim.olusturmaTarihi.hour}:${bildirim.olusturmaTarihi.minute.toString().padLeft(2, '0')}',
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

            if (bildirim.fotograflar.isEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Bu bildirime fotoğraf eklenmemiş.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            const Text(
              'Risk Seviyesi Belirle',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                RiskSeviyesi.dusuk,
                RiskSeviyesi.orta,
                RiskSeviyesi.yuksek,
                RiskSeviyesi.acil,
              ].map((seviye) {
                final secili = _secilenRiskSeviyesi == seviye;
                return ChoiceChip(
                  label: Text(_riskSeviyesiEtiket(seviye)),
                  selected: secili,
                  selectedColor: _riskSeviyesiRengi(seviye).withValues(alpha: 0.25),
                  onSelected: (_) {
                    setState(() => _secilenRiskSeviyesi = seviye);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            if (_hataMesaji != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _hataMesaji!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_islemYapiliyor)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Risk Seviyesini Kaydet ve Devam Et'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _riskSeviyesiKaydet,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Müdahale Gerekmiyor, Kaydı Kapat'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.red,
                ),
                onPressed: _kaydiKapat,
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
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

  Color _riskSeviyesiRengi(RiskSeviyesi seviye) {
    switch (seviye) {
      case RiskSeviyesi.belirlenmedi:
        return Colors.grey;
      case RiskSeviyesi.dusuk:
        return Colors.green;
      case RiskSeviyesi.orta:
        return Colors.orange;
      case RiskSeviyesi.yuksek:
        return Colors.deepOrange;
      case RiskSeviyesi.acil:
        return Colors.red;
    }
  }
}