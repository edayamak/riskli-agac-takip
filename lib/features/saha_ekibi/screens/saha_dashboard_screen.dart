import 'package:flutter/material.dart';
import '../../../models/kullanici_model.dart';
import '../../yetkili/screens/profil_screen.dart';
import 'saha_anasayfa_view.dart';
import 'gorevlerim_screen.dart';

class SahaEkibiDashboardScreen extends StatefulWidget {
  final KullaniciModel kullanici;
  const SahaEkibiDashboardScreen({super.key, required this.kullanici});

  @override
  State<SahaEkibiDashboardScreen> createState() => _SahaEkibiDashboardScreenState();
}

class _SahaEkibiDashboardScreenState extends State<SahaEkibiDashboardScreen> {
  final PageController _pageController = PageController();
  int _secilenSekme = 0;

  static const List<String> _basliklar = ['Ana Sayfa', 'Görevlerim', 'Profil'];

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
          SahaAnasayfaView(kullanici: widget.kullanici, sekmeyeGit: _sekmeSec),
          GorevlerimView(kullanici: widget.kullanici),
          ProfilView(kullanici: widget.kullanici, rolEtiketi: 'Saha Personeli'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _secilenSekme,
        onTap: _sekmeSec,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Görevlerim'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}