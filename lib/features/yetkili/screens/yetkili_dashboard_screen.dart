import 'package:flutter/material.dart';
import '../../../models/kullanici_model.dart';
import 'yetkili_anasayfa_view.dart';
import 'bildirim_listesi_screen.dart';
import 'harita_screen.dart';
import 'profil_screen.dart';

class YetkiliDashboardScreen extends StatefulWidget {
  final KullaniciModel kullanici;
  const YetkiliDashboardScreen({super.key, required this.kullanici});

  @override
  State<YetkiliDashboardScreen> createState() => _YetkiliDashboardScreenState();
}

class _YetkiliDashboardScreenState extends State<YetkiliDashboardScreen> {
  final PageController _pageController = PageController();
  int _secilenSekme = 0;

  static const List<String> _basliklar = [
    'Ana Sayfa',
    'Bildirimler',
    'Harita',
    'Profil',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _sekmeSec(int index) {
  setState(() => _secilenSekme = index);
  _pageController.jumpToPage(index);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_basliklar[_secilenSekme])),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _secilenSekme = index),
        children: [
          YetkiliAnasayfaView(kullanici: widget.kullanici, sekmeyeGit: _sekmeSec),
          BildirimListesiView(yetkili: widget.kullanici),
          HaritaView(yetkili: widget.kullanici),
          ProfilView(kullanici: widget.kullanici, rolEtiketi: 'Yetkili Personel'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _secilenSekme,
        onTap: _sekmeSec,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Bildirimler'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}