import 'package:flutter/material.dart';
import '../../../models/bildirim_model.dart';
import '../../../models/gorev_model.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/firestore_service.dart';

class GorevAtamaScreen extends StatefulWidget {
  final BildirimModel bildirim;
  final KullaniciModel yetkili;

  const GorevAtamaScreen({
    super.key,
    required this.bildirim,
    required this.yetkili,
  });

  @override
  State<GorevAtamaScreen> createState() => _GorevAtamaScreenState();
}

class _GorevAtamaScreenState extends State<GorevAtamaScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String? _secilenPersonelId;
  GorevOncelik _secilenOncelik = GorevOncelik.orta;

  bool _atamaYapiliyor = false;
  String? _hataMesaji;

  Future<void> _goreviAta() async {
    if (_secilenPersonelId == null) {
      setState(() => _hataMesaji = 'Lütfen bir saha personeli seçin.');
      return;
    }

    setState(() {
      _atamaYapiliyor = true;
      _hataMesaji = null;
    });

    try {
      await _firestoreService.gorevOlustur(
        bildirimId: widget.bildirim.bildirimId,
        atananPersonelId: _secilenPersonelId!,
        atayanYetkiliId: widget.yetkili.kullaniciId,
        oncelik: _secilenOncelik,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görev başarıyla atandı.')),
        );
        // Görev atama akışının en başındaki listeye kadar geri dön
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _hataMesaji = 'Görev atanamadı. Lütfen tekrar deneyin.';
        _atamaYapiliyor = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Görev Ata')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.bildirim.adres.isNotEmpty
                          ? widget.bildirim.adres
                          : '${widget.bildirim.konumLat.toStringAsFixed(5)}, ${widget.bildirim.konumLng.toStringAsFixed(5)}',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Öncelik',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: GorevOncelik.values.map((oncelik) {
                final secili = _secilenOncelik == oncelik;
                return ChoiceChip(
                  label: Text(_oncelikEtiket(oncelik)),
                  selected: secili,
                  onSelected: (_) {
                    setState(() => _secilenOncelik = oncelik);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            const Text(
              'Saha Personeli Seç',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<List<KullaniciModel>>(
                stream: _firestoreService.tumSahaPersoneliStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final personelListesi = snapshot.data ?? [];

                  if (personelListesi.isEmpty) {
                    return const Center(
                      child: Text(
                        'Sistemde kayıtlı saha personeli bulunamadı.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: personelListesi.length,
                    itemBuilder: (context, index) {
                      final personel = personelListesi[index];
                      final secili = _secilenPersonelId == personel.kullaniciId;

                      return Card(
                        color: secili ? Colors.blue.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: personel.avatarId != null
                                ? AssetImage('assets/images/avatars/${personel.avatarId}.png')
                                : null,
                            child: personel.avatarId == null
                                ? Text(
                                    personel.ad.isNotEmpty ? personel.ad[0].toUpperCase() : '?',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  )
                                : null,
                          ),
                          title: Text(personel.tamAd),
                          subtitle: Text(personel.telefon),
                          trailing: secili
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : null,
                          onTap: () {
                            setState(() => _secilenPersonelId = personel.kullaniciId);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            if (_hataMesaji != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _hataMesaji!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_atamaYapiliyor)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.assignment_turned_in),
                label: const Text('Görevi Ata'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _goreviAta,
              ),
          ],
        ),
      ),
    ),
    );
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
}