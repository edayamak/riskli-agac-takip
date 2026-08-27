import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/kullanici_model.dart';
import '../../../models/kurum_model.dart';
import '../../../services/firestore_service.dart';

class PersonelDuzenleScreen extends StatefulWidget {
  final KullaniciModel personel;
  const PersonelDuzenleScreen({super.key, required this.personel});

  @override
  State<PersonelDuzenleScreen> createState() => _PersonelDuzenleScreenState();
}

class _PersonelDuzenleScreenState extends State<PersonelDuzenleScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late KullaniciRol _secilenRol;
  String? _secilenKurumId;
  bool _kaydediliyor = false;
  String? _hataMesaji;

  @override
  void initState() {
    super.initState();
    _secilenRol = widget.personel.rol;
    _secilenKurumId = widget.personel.kurumId;
  }

  Future<void> _kurumSecimSayfasiniAc(List<KurumModel> kurumlar) async {
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Bir Kurum Seç', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

  Future<void> _kaydet() async {
    setState(() {
      _kaydediliyor = true;
      _hataMesaji = null;
    });

    try {
      await _firestoreService.personelGuncelle(
        kullaniciId: widget.personel.kullaniciId,
        rol: _secilenRol,
        kurumId: _secilenKurumId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personel bilgileri güncellendi.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _hataMesaji = 'Güncelleme başarısız oldu.';
        _kaydediliyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personel Düzenle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.background,
                  backgroundImage: widget.personel.avatarId != null
                      ? AssetImage('assets/images/avatars/${widget.personel.avatarId}.png')
                      : null,
                  child: widget.personel.avatarId == null
                      ? Text(
                          widget.personel.ad.isNotEmpty ? widget.personel.ad[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(widget.personel.tamAd, style: Theme.of(context).textTheme.titleLarge),
              ),
              Center(
                child: Text(widget.personel.email ?? '', style: Theme.of(context).textTheme.bodySmall),
              ),

              const SizedBox(height: 28),
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
              const Text('Kurum/Birim', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              StreamBuilder<List<KurumModel>>(
                stream: _firestoreService.kurumlarStream(),
                builder: (context, snapshot) {
                  final kurumlar = snapshot.data ?? [];
                  final secilenKurum = kurumlar.where((k) => k.kurumId == _secilenKurumId).toList();
                  final secilenKurumAdi = secilenKurum.isNotEmpty ? secilenKurum.first.kurumAdi : null;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: kurumlar.isEmpty ? null : () => _kurumSecimSayfasiniAc(kurumlar),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Kurum',
                        suffixIcon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      ),
                      child: Text(
                        secilenKurumAdi ?? (kurumlar.isEmpty ? 'Henüz kurum eklenmemiş' : 'Atanmamış'),
                        style: TextStyle(
                          color: secilenKurumAdi != null ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),
              if (_hataMesaji != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_hataMesaji!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
                ),

              if (_kaydediliyor)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Kaydet'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _kaydet,
                ),
            ],
          ),
        ),
      ),
    );
  }
}