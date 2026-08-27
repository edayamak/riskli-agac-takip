import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/auth_service.dart';
import '../../../models/kurum_model.dart';
import '../../../services/firestore_service.dart';

class PersonelEkleScreen extends StatefulWidget {
  const PersonelEkleScreen({super.key});

  @override
  State<PersonelEkleScreen> createState() => _PersonelEkleScreenState();
}

class _PersonelEkleScreenState extends State<PersonelEkleScreen> {
  final AuthService _authService = AuthService();

  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  
  String? _secilenKurumId;

  KullaniciRol _secilenRol = KullaniciRol.sahaPersoneli;
  String _secilenAvatar = 'avatar_1';
  bool _kaydediliyor = false;
  String? _hataMesaji;

  static const List<String> _avatarListesi = [
    'avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5', 'avatar_6',
  ];

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_adController.text.trim().isEmpty ||
        _soyadController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _sifreController.text.isEmpty) {
      setState(() => _hataMesaji = 'Lütfen zorunlu alanları doldurun.');
      return;
    }

    if (_sifreController.text.length < 6) {
      setState(() => _hataMesaji = 'Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() {
      _kaydediliyor = true;
      _hataMesaji = null;
    });

    try {
      await _authService.personelEkle(
        email: _emailController.text.trim(),
        sifre: _sifreController.text,
        ad: _adController.text.trim(),
        soyad: _soyadController.text.trim(),
        telefon: _telefonController.text.trim(),
        rol: _secilenRol,
        kurumId: _secilenKurumId,
        avatarId: _secilenAvatar,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personel başarıyla eklendi.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _hataMesaji = 'Personel eklenemedi. E-posta zaten kullanımda olabilir.';
        _kaydediliyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personel Ekle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Avatar Seç', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatarListesi.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final avatarId = _avatarListesi[index];
                    final secili = _secilenAvatar == avatarId;
                    return GestureDetector(
                      onTap: () => setState(() => _secilenAvatar = avatarId),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: secili ? AppColors.primary.withValues(alpha: 0.15) : AppColors.background,
                        backgroundImage: AssetImage('assets/images/avatars/$avatarId.png'),
                        child: secili
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 3),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              TextField(controller: _adController, decoration: const InputDecoration(labelText: 'Ad *')),
              const SizedBox(height: 12),
              TextField(controller: _soyadController, decoration: const InputDecoration(labelText: 'Soyad *')),
              const SizedBox(height: 12),
              TextField(
                controller: _telefonController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon', hintText: '+905XXXXXXXXX'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sifreController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre * (en az 6 karakter)'),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<KurumModel>>(
                stream: FirestoreService().kurumlarStream(),
                builder: (context, snapshot) {
                  final kurumlar = snapshot.data ?? [];
                  final secilenKurum = kurumlar.where((k) => k.kurumId == _secilenKurumId).toList();
                  final secilenKurumAdi = secilenKurum.isNotEmpty ? secilenKurum.first.kurumAdi : null;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: kurumlar.isEmpty ? null : () => _kurumSecimSayfasiniAc(context, kurumlar),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Kurum (opsiyonel)',
                        suffixIcon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      ),
                      child: Text(
                        secilenKurumAdi ?? (kurumlar.isEmpty ? 'Henüz kurum eklenmemiş' : 'Kurum seçin'),
                        style: TextStyle(
                          color: secilenKurumAdi != null ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),


              const SizedBox(height: 20),
              const Text('Rol', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<KullaniciRol>(
                      title: const Text('Saha Personeli', style: TextStyle(fontSize: 13)),
                      value: KullaniciRol.sahaPersoneli,
                      groupValue: _secilenRol,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (deger) => setState(() => _secilenRol = deger!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<KullaniciRol>(
                      title: const Text('Yetkili', style: TextStyle(fontSize: 13)),
                      value: KullaniciRol.yetkili,
                      groupValue: _secilenRol,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (deger) => setState(() => _secilenRol = deger!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              if (_hataMesaji != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_hataMesaji!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
                ),

              if (_kaydediliyor)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Personeli Ekle'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _kaydet,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Kurum seçimi için alt sayfa açar.
  // Dokunulduğunda alttan yukarı kayan bir liste sayfası açılıyor (showModalBottomSheet).
    Future<void> _kurumSecimSayfasiniAc(BuildContext context, List<KurumModel> kurumlar) async {
    final secilen = await showModalBottomSheet<String>(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Text('Bir Kurum Seç', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...kurumlar.map((kurum) {
                return ListTile(
                  leading: const Icon(Icons.apartment, color: AppColors.primary),
                  title: Text(kurum.kurumAdi),
                  onTap: () => Navigator.pop(context, kurum.kurumId),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (secilen != null) {
      setState(() => _secilenKurumId = secilen);
    }
  }
}