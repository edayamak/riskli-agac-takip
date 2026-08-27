import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/kullanici_model.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/vatandas/screens/vatandas_home_screen.dart';
import '../../features/yetkili/screens/yetkili_dashboard_screen.dart';
import '../../features/saha_ekibi/screens/saha_dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authDurumu,
      builder: (context, authSnapshot) {
        // Firebase bağlantısı henüz cevap vermedi
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _YuklemeEkrani();
        }

        // Giriş yapılmamış -> Giriş ekranına yönlendir
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen();
        }

        // Giriş yapılmış -> Firestore'dan kullanıcı bilgisini (rolü) çek
        return FutureBuilder<KullaniciModel?>(
          future: _authService.girisYapmisKullaniciBilgisiGetir(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _YuklemeEkrani();
            }

            final kullanici = userSnapshot.data;

            // Firestore'da kullanıcı dokümanı yoksa (beklenmeyen durum) güvenli tarafta kal
            if (kullanici == null) {
              return const _HataEkrani(
                mesaj: 'Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.',
              );
            }

            // Role göre doğru ana ekrana yönlendir
            switch (kullanici.rol) {
              case KullaniciRol.vatandas:
                return VatandasHomeScreen(kullanici: kullanici);
              case KullaniciRol.yetkili:
                return YetkiliDashboardScreen(kullanici: kullanici);
              case KullaniciRol.sahaPersoneli:
                return SahaEkibiDashboardScreen(kullanici: kullanici);
            }
          },
        );
      },
    );
  }
}

class _YuklemeEkrani extends StatelessWidget {
  const _YuklemeEkrani();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HataEkrani extends StatelessWidget {
  final String mesaj;
  const _HataEkrani({required this.mesaj});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(mesaj, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}