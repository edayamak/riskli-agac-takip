import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/kurum_model.dart';

class ProfilView extends StatefulWidget {
  final KullaniciModel kullanici;
  final String rolEtiketi;
  const ProfilView({super.key, required this.kullanici, required this.rolEtiketi});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _adController;
  late final TextEditingController _soyadController;
  late final TextEditingController _telefonController;

  File? _profilFotografi;

  bool _duzenlemeModu = false;
  bool _kaydediliyor = false;
  String? _hataMesaji;

  // Kendi eklediğin dosya adlarına göre bu listeyi güncelle
  static const List<String> _avatarListesi = [
    'avatar_1', 'avatar_2', 'avatar_3', 'avatar_4',
    'avatar_5', 'avatar_6','avatar_7'];

  @override
  void initState() {
    super.initState();
    _adController = TextEditingController(text: widget.kullanici.ad);
    _soyadController = TextEditingController(text: widget.kullanici.soyad);
    _telefonController = TextEditingController(text: widget.kullanici.telefon);
  }

  Future<void> _fotografSecenekleriGoster() async {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  title: const Text('Fotoğraf Çek'),
                  onTap: () {
                    Navigator.pop(context);
                    _fotografSec(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  title: const Text('Galeriden Seç'),
                  onTap: () {
                    Navigator.pop(context);
                    _fotografSec(ImageSource.gallery);
                  },
                ),
                ListTile(
                leading: const Icon(Icons.face_outlined, color: AppColors.primary),
                title: const Text('Hazır Avatarlardan Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _avatarSecimDialogunuAc();
                },
              ),
              if (_profilFotografi != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: const Text('Fotoğrafı Kaldır', style: TextStyle(color: AppColors.danger)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _profilFotografi = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fotografSec(ImageSource kaynak) async {
    final secilen = await _imagePicker.pickImage(source: kaynak, imageQuality: 70);
    if (secilen != null) {
      setState(() => _profilFotografi = File(secilen.path));
    }
  }

  Future<void> _avatarSecimDialogunuAc() async {
    final secilen = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bir Avatar Seç',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: _avatarListesi.map((avatarId) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, avatarId),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.background,
                        backgroundImage: AssetImage('assets/images/avatars/$avatarId.png'),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (secilen != null) {
      _avatarKaydet(secilen);
    }
  }

  Future<void> _avatarKaydet(String avatarId) async {
    setState(() {
      _profilFotografi = null; // avatar seçilince yerel fotoğrafı iptal et
    });

    try {
      await _firestoreService.avatarGuncelle(
        kullaniciId: widget.kullanici.kullaniciId,
        avatarId: avatarId,
      );
      // StreamBuilder Firestore'daki değişikliği otomatik yakalayıp ekranı günceller,
      // burada ekstra bir setState'e gerek yok.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar kaydedilemedi, tekrar deneyin.')),
        );
      }
    }
  }

  void _fotografiTamEkranGoster() {
    if (_profilFotografi == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.file(_profilFotografi!),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    setState(() {
      _kaydediliyor = true;
      _hataMesaji = null;
    });
    try {
      await _firestoreService.kullaniciGuncelle(
        kullaniciId: widget.kullanici.kullaniciId,
        ad: _adController.text.trim(),
        soyad: _soyadController.text.trim(),
        telefon: _telefonController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _duzenlemeModu = false;
          _kaydediliyor = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilgiler güncellendi.')),
        );
      }
    } catch (e) {
      setState(() {
        _hataMesaji = 'Güncelleme başarısız oldu.';
        _kaydediliyor = false;
      });
    }
  }

  Future<void> _hesabiSilOnayla() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınız kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hesabı Sil', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      await _authService.hesabiSil();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesap silinemedi. Güvenlik nedeniyle tekrar giriş yapıp deneyin.'),
          ),
        );
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    return StreamBuilder<KullaniciModel?>(
      stream: _firestoreService.kullaniciStream(widget.kullanici.kullaniciId),
      builder: (context, snapshot) {
        final guncelKullanici = snapshot.data ?? widget.kullanici;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _profilFotografi != null ? _fotografiTamEkranGoster : null,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: _profilFotografi != null
                  ? FileImage(_profilFotografi!) as ImageProvider
                  : (guncelKullanici.avatarId != null
                      ? AssetImage('assets/images/avatars/${guncelKullanici.avatarId}.png')
                      : null),
              child: (_profilFotografi == null && guncelKullanici.avatarId == null)
                  ? Text(
                      guncelKullanici.ad.isNotEmpty ? guncelKullanici.ad[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary),
                    )
                  : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _fotografSecenekleriGoster,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(guncelKullanici.tamAd, style: Theme.of(context).textTheme.titleLarge)),
        Center(child: Text(widget.rolEtiketi, style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kişisel Bilgiler', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: Icon(_duzenlemeModu ? Icons.close : Icons.edit_outlined),
                      onPressed: () => setState(() => _duzenlemeModu = !_duzenlemeModu),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_duzenlemeModu) ...[
                  TextField(controller: _adController, decoration: const InputDecoration(labelText: 'Ad')),
                  const SizedBox(height: 12),
                  TextField(controller: _soyadController, decoration: const InputDecoration(labelText: 'Soyad')),
                  const SizedBox(height: 12),
                  TextField(controller: _telefonController, decoration: const InputDecoration(labelText: 'Telefon')),
                  const SizedBox(height: 16),
                  if (_hataMesaji != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_hataMesaji!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  _kaydediliyor
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(onPressed: _kaydet, child: const Text('Kaydet')),
                ] else ...[
                  _bilgiSatiri('Ad Soyad', guncelKullanici.tamAd, Icons.person_outline),
                  _bilgiSatiri('Telefon', guncelKullanici.telefon, Icons.phone_outlined),
                  _bilgiSatiri('E-posta', guncelKullanici.email ?? '-', Icons.email_outlined),
                  if (guncelKullanici.rol != KullaniciRol.vatandas)
                    FutureBuilder<KurumModel?>(
                      future: guncelKullanici.kurumId != null
                          ? _firestoreService.kurumGetir(guncelKullanici.kurumId!)
                          : Future.value(null),
                      builder: (context, snapshot) {
                        final kurumAdi = snapshot.data?.kurumAdi;
                        return _bilgiSatiri(
                          'Kurum/Birim',
                          kurumAdi ?? 'Atanmamış',
                          Icons.apartment_outlined,
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Çıkış Yap'),
          onPressed: () => _authService.cikisYap(),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          label: const Text('Hesabı Sil', style: TextStyle(color: AppColors.danger)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
          onPressed: _hesabiSilOnayla,
        ),
      ],
        );
      },
    );
  }

  Widget _bilgiSatiri(String baslik, String deger, IconData ikon) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(ikon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            SizedBox(width: 80, child: Text(baslik, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            Expanded(child: Text(deger, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
    }
}