import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/storage_service.dart';
import '../../../models/gorev_model.dart';
import '../../../models/bildirim_model.dart';
import '../../../models/mudahale_model.dart';
import '../../../services/firestore_service.dart';

class MudahaleFormScreen extends StatefulWidget {
  final GorevModel gorev;
  final BildirimModel bildirim;

  const MudahaleFormScreen({
    super.key,
    required this.gorev,
    required this.bildirim,
  });

  @override
  State<MudahaleFormScreen> createState() => _MudahaleFormScreenState();
}

class _MudahaleFormScreenState extends State<MudahaleFormScreen> {
  final FirestoreService _firestoreService = FirestoreService();
    final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final _notController = TextEditingController();

  MudahaleTipi? _secilenTip;
  File? _oncesiFoto;
  File? _sonrasiFoto;
  File? _videoKaydi;
  final List<PlatformFile> _secilenBelgeler = [];

  bool _kaydediliyor = false;
  String? _hataMesaji;

  static const int _minNotUzunlugu = 10;

  @override
  void dispose() {
    _notController.dispose();
    super.dispose();
  }

  Future<void> _fotoSec(bool oncesi) async {
    final secilen = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (secilen != null) {
      setState(() {
        if (oncesi) {
          _oncesiFoto = File(secilen.path);
        } else {
          _sonrasiFoto = File(secilen.path);
        }
      });
    }
  }

    Future<void> _videoCek() async {
    final secilen = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    if (secilen != null) {
      setState(() => _videoKaydi = File(secilen.path));
    }
  }

  Future<void> _videoyuGaleridenSec() async {
    final secilen = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (secilen != null) {
      setState(() => _videoKaydi = File(secilen.path));
    }
  }

  void _videoyuKaldir() {
    setState(() => _videoKaydi = null);
  }

  Future<void> _belgeEkle() async {
    final FilePickerResult? sonuc = await FilePicker.pickFiles(
      // ignore: deprecated_member_use
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
    );

    if (sonuc != null && sonuc.files.isNotEmpty) {
      setState(() {
        _secilenBelgeler.addAll(sonuc.files);
      });
    }
  }

  void _belgeKaldir(int index) {
    setState(() => _secilenBelgeler.removeAt(index));
  }

  Future<void> _kaydet() async {
    if (_secilenTip == null) {
      setState(() => _hataMesaji = 'Lütfen yapılan işlemi seçin.');
      return;
    }

    if (_notController.text.trim().length < _minNotUzunlugu) {
      setState(() => _hataMesaji =
          'Açıklama en az $_minNotUzunlugu karakter olmalı (şu an ${_notController.text.trim().length} karakter).');
      return;
    }

    setState(() {
      _kaydediliyor = true;
      _hataMesaji = null;
    });

    try {
      // 1. Öncesi/Sonrası fotoğrafları yükle
      String? oncesiUrl;
      if (_oncesiFoto != null) {
        oncesiUrl = await _storageService.dosyaYukle(
          dosya: _oncesiFoto!,
          klasor: 'mudahaleler',
        );
      }

      String? sonrasiUrl;
      if (_sonrasiFoto != null) {
        sonrasiUrl = await _storageService.dosyaYukle(
          dosya: _sonrasiFoto!,
          klasor: 'mudahaleler',
        );
      }

      // 2. Videoyu yükle
      String? videoUrl;
      if (_videoKaydi != null) {
        videoUrl = await _storageService.dosyaYukle(
          dosya: _videoKaydi!,
          klasor: 'videolar',
        );
      }

      // 3. Belgeleri yükle
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

      // 4. Müdahaleyi Firestore'a kaydet
      await _firestoreService.mudahaleOlustur(
        gorevId: widget.gorev.gorevId,
        bildirimId: widget.bildirim.bildirimId,
        personelId: widget.gorev.atananPersonelId,
        mudahaleTipi: _secilenTip!,
        oncesiFotograf: oncesiUrl,
        sonrasiFotograf: sonrasiUrl,
        videoUrl: videoUrl,
        belgeler: belgeUrlleri,
        not: _notController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müdahale kaydedildi. Görev tamamlandı.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _hataMesaji = 'Kayıt başarısız oldu. Lütfen tekrar deneyin.';
        _kaydediliyor = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Müdahale Formu')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yapılan İşlem',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...MudahaleTipi.values.map((tip) {
              return RadioListTile<MudahaleTipi>(
                title: Text(mudahaleTipiEtiket(tip)),
                value: tip,
                groupValue: _secilenTip,
                onChanged: (deger) => setState(() => _secilenTip = deger),
              );
            }),

            const SizedBox(height: 16),
            const Text(
              'Fotoğraflar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _fotoKutusu(
                    baslik: 'Öncesi',
                    dosya: _oncesiFoto,
                    onTap: () => _fotoSec(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _fotoKutusu(
                    baslik: 'Sonrası',
                    dosya: _sonrasiFoto,
                    onTap: () => _fotoSec(false),
                  ),
                ),
              ],
            ),

                        const SizedBox(height: 24),
            const Text(
              'Video Kaydı',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_videoKaydi != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _videoKaydi!.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: _videoyuKaldir,
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Video Çek'),
                      onPressed: _videoCek,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.video_library_outlined),
                      label: const Text('Galeriden Seç'),
                      onPressed: _videoyuGaleridenSec,
                    ),
                  ),
                ],
              ),

             const SizedBox(height: 24),
            const Text(
              'Doküman',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _secilenBelgeler.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _secilenBelgeler[i].name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _belgeKaldir(i),
                      ),
                    ],
                  ),
                ),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Doküman Ekle (PDF, Word, Excel...)'),
              onPressed: _belgeEkle,
            ),

            const SizedBox(height: 24),
            const Text(
              'Açıklama / Not',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'En az $_minNotUzunlugu karakter girilmelidir.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Yapılan işlemle ilgili açıklama girin...',
                border: const OutlineInputBorder(),
                counterText: '${_notController.text.trim().length}/$_minNotUzunlugu',
              ),
              onChanged: (_) => setState(() {}),
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

            if (_kaydediliyor)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Görevi Tamamla ve Kaydet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _kaydet,
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _fotoKutusu({
    required String baslik,
    required File? dosya,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: dosya != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(dosya, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo),
                  Text(baslik, style: const TextStyle(fontSize: 12)),
                ],
              ),
      ),
    );
  }
}