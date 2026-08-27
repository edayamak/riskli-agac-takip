import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../models/bildirim_model.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/location_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/firestore_service.dart';
import 'konum_duzenle_screen.dart';

class BildirimFormScreen extends StatefulWidget {
  final KullaniciModel kullanici;
  const BildirimFormScreen({super.key, required this.kullanici});

  @override
  State<BildirimFormScreen> createState() => _BildirimFormScreenState();
}

class _BildirimFormScreenState extends State<BildirimFormScreen> {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
    final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  final _aciklamaController = TextEditingController();

KonumSonucu? _konum;
  bool _konumAliniyor = false;

  final List<File> _secilenFotograflar = [];
  final List<PlatformFile> _secilenBelgeler = [];
  File? _secilenVideo;

  RiskTipi? _secilenRiskTipi;

  bool _gonderiliyor = false;
  String? _hataMesaji;

  @override
  void dispose() {
    _aciklamaController.dispose();
    super.dispose();
  }

  Future<void> _konumuAl() async {
    setState(() {
      _konumAliniyor = true;
      _hataMesaji = null;
    });

    try {
      final konum = await _locationService.konumVeAdresAl();
      setState(() {
        _konum = konum;
        _konumAliniyor = false;
      });
    } catch (e) {
      setState(() {
        _hataMesaji = e.toString().replaceFirst('Exception: ', '');
        _konumAliniyor = false;
      });
    }
  }

  Future<void> _konumuHaritadaDuzenle() async {
    if (_konum == null) return;

    final sonuc = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => KonumDuzenleScreen(
          baslangicLat: _konum!.lat,
          baslangicLng: _konum!.lng,
        ),
      ),
    );

    if (sonuc != null) {
      // Kullanıcının elle işaretlediği yeni koordinatlarla adresi güncelle
      final yeniAdres = await _locationService.adresBul(sonuc.latitude, sonuc.longitude);
      setState(() {
        _konum = KonumSonucu(lat: sonuc.latitude, lng: sonuc.longitude, adres: yeniAdres);
      });
    }
  }

  Future<void> _fotografEkle() async {
    final secilen = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (secilen != null) {
      setState(() {
        _secilenFotograflar.add(File(secilen.path));
      });
    }
  }

  Future<void> _galeridenSec() async {
    final secilen = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (secilen != null) {
      setState(() {
        _secilenFotograflar.add(File(secilen.path));
      });
    }
  }

  void _fotografSil(int index) {
    setState(() {
      _secilenFotograflar.removeAt(index);
    });
  }
Future<void> _belgeEkle() async {
    final FilePickerResult? sonuc = await FilePicker.pickFiles(
      // ignore: deprecated_member_use
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (sonuc != null && sonuc.files.isNotEmpty) {
      setState(() {
        _secilenBelgeler.addAll(sonuc.files);
      });
    }
  }

  void _belgeSil(int index) {
    setState(() {
      _secilenBelgeler.removeAt(index);
    });
  }

  Future<void> _videoEkle() async {
    final secilen = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    if (secilen != null) {
      setState(() => _secilenVideo = File(secilen.path));
    }
  }

  Future<void> _videoGaleridenSec() async {
    final secilen = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (secilen != null) {
      setState(() => _secilenVideo = File(secilen.path));
    }
  }

  void _videoSil() {
    setState(() => _secilenVideo = null);
  }

  Future<void> _bildirimiGonder() async {
    // Doğrulamalar
    if (_konum == null) {
      setState(() => _hataMesaji = 'Lütfen önce konum bilgisi alın.');
      return;
    }
    if (_aciklamaController.text.trim().length < 10) {
      setState(() => _hataMesaji = 'Açıklama en az 10 karakter olmalı, ağacın durumunu biraz daha detaylandırın.');
      return;
    }
    if (_secilenRiskTipi == null) {
      setState(() => _hataMesaji = 'Lütfen risk tipini seçin.');
      return;
    }

    setState(() {
      _gonderiliyor = true;
      _hataMesaji = null;
    });

    try {
      // 1. Fotoğrafları yükle
      final fotografUrlleri = await _storageService.cokluFotografYukle(
        dosyalar: _secilenFotograflar,
        klasor: 'bildirimler',
      );

      // 2. Belgeleri yükle
      final List<String> belgeUrlleri = [];
      for (final belge in _secilenBelgeler) {
        if (belge.path != null) {
          final url = await _storageService.dosyaYukle(
            dosya: File(belge.path!),
            klasor: 'belgeler',
          );
          belgeUrlleri.add(url);
        }
      }

      // 3. Videoyu yükle
      String? videoUrl;
      if (_secilenVideo != null) {
        videoUrl = await _storageService.dosyaYukle(
          dosya: _secilenVideo!,
          klasor: 'videolar',
        );
      }

      // 4. Bildirimi Firestore'a kaydet
      await _firestoreService.bildirimOlustur(
        bildirenKullaniciId: widget.kullanici.kullaniciId,
        konumLat: _konum!.lat,
        konumLng: _konum!.lng,
        adres: _konum!.adres,
        fotograflar: fotografUrlleri,
        videoUrl: videoUrl,
        belgeler: belgeUrlleri,
        aciklama: _aciklamaController.text.trim(),
        riskTipi: _secilenRiskTipi!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildiriminiz başarıyla gönderildi.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _hataMesaji = 'Bildirim gönderilemedi. Lütfen tekrar deneyin.';
        _gonderiliyor = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Riskli Ağaç Bildir')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- KONUM ----------------
            const Text(
              'Konum',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_konum != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _konum!.adres.isNotEmpty
                            ? _konum!.adres
                            : '${_konum!.lat.toStringAsFixed(5)}, ${_konum!.lng.toStringAsFixed(5)}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _konumuHaritadaDuzenle,
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Konumu Haritada Düzenle'),
              ),
            ] else
              OutlinedButton.icon(
                onPressed: _konumAliniyor ? null : _konumuAl,
                icon: _konumAliniyor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _konumAliniyor ? 'Konum alınıyor...' : 'Konumumu Al',
                ),
              ),

            const SizedBox(height: 24),

            // ---------------- FOTOĞRAFLAR ----------------
            const Text(
              'Fotoğraflar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _secilenFotograflar.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _secilenFotograflar[i],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _fotografSil(i),
                        ),
                      ),
                    ],
                  ),
                InkWell(
                  onTap: _fotografEkle,
                  onLongPress: _galeridenSec,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_a_photo),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Fotoğraf eklemek için dokun, galeriden seçmek için basılı tut',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            
            const SizedBox(height: 24),

            // ---------------- BELGELER ----------------
            const Text(
              'Belgeler (opsiyonel)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _belgeEkle,
              icon: const Icon(Icons.attach_file),
              label: const Text('Belge Ekle'),
            ),
            if (_secilenBelgeler.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...List.generate(_secilenBelgeler.length, (i) {
                final belge = _secilenBelgeler[i];
                return Card(
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      belge.name,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _belgeSil(i),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // ---------------- VİDEO ----------------
            const Text(
              'Video (opsiyonel)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_secilenVideo != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: Text(
                    _secilenVideo!.path.split('/').last,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _videoSil,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _videoEkle,
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Video Çek'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _videoGaleridenSec,
                      icon: const Icon(Icons.video_library_outlined),
                      label: const Text('Galeriden Seç'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),


            // ---------------- AÇIKLAMA ----------------
            const Text(
              'Açıklama',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _aciklamaController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ağacın durumunu kısaca açıklayın...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- RİSK TİPİ ----------------
            const Text(
              'Risk Tipi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RiskTipi.values.map((tip) {
                final secili = _secilenRiskTipi == tip;
                return ChoiceChip(
                  label: Text(_riskTipiEtiket(tip)),
                  selected: secili,
                  onSelected: (_) {
                    setState(() => _secilenRiskTipi = tip);
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

            if (_gonderiliyor)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _bildirimiGonder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Bildirimi Gönder'),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    );
  }

  String _riskTipiEtiket(RiskTipi tip) {
    switch (tip) {
      case RiskTipi.kurumus:
        return 'Kurumuş';
      case RiskTipi.hastalikli:
        return 'Hastalıklı';
      case RiskTipi.devrilmeRiski:
        return 'Devrilme Riski';
      case RiskTipi.budamaIhtiyaci:
        return 'Budama İhtiyacı';
      case RiskTipi.firtinaRiski:
        return 'Fırtına Öncesi Risk';
    }
  }
}