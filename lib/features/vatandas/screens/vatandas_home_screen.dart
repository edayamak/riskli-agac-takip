import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/kullanici_model.dart';
import '../../yetkili/screens/profil_screen.dart';
import 'vatandas_anasayfa_view.dart';
import 'bildirimlerim_view.dart';
import 'bildirim_form_screen.dart';

class VatandasHomeScreen extends StatefulWidget {
  final KullaniciModel kullanici;
  const VatandasHomeScreen({super.key, required this.kullanici});

  @override
  State<VatandasHomeScreen> createState() => _VatandasHomeScreenState();
}

class _VatandasHomeScreenState extends State<VatandasHomeScreen> {
  final PageController _pageController = PageController();
  int _secilenSekme = 0;

  static const List<String> _basliklar = ['Ana Sayfa', 'Bildirimlerim', 'Profil'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _sekmeSec(int index) {
  setState(() => _secilenSekme = index);
  _pageController.jumpToPage(index);
}

  void _bildirimFormunuAc() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BildirimFormScreen(kullanici: widget.kullanici),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_basliklar[_secilenSekme])),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _secilenSekme = index),
        children: [
          VatandasAnasayfaView(kullanici: widget.kullanici, sekmeyeGit: _sekmeSec),
          BildirimlerimView(kullanici: widget.kullanici),
          ProfilView(kullanici: widget.kullanici, rolEtiketi: 'Vatandaş'),
        ],
      ),
      floatingActionButton: _secilenSekme == 0
          ? FloatingActionButton(
              onPressed: _bildirimFormunuAc,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _secilenSekme,
        onTap: _sekmeSec,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Bildirimlerim'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}