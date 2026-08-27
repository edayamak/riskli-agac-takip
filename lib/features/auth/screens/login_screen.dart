import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _AcikPanel { yok, vatandas, personel }

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  _AcikPanel _acikPanel = _AcikPanel.yok;

  void _paneliAcKapat(_AcikPanel panel) {
    setState(() {
      _acikPanel = _acikPanel == panel ? _AcikPanel.yok : panel;
    });
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // ---------------- KURUM BAŞLIĞI ----------------
              const Text(
                'TRABZON BÜYÜKŞEHİR BELEDİYESİ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // ---------------- LOGO ----------------
              SizedBox(
                height: 120,
                width: 120,
                child: Image.asset('assets/images/app_nobg.png'),
              ),
              const SizedBox(height: 20),

              // ---------------- BAŞLIK ----------------
              const Text(
                'Riskli Ağaç Takip ve\nMüdahale Sistemi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 36),

              // ---------------- VATANDAŞ GİRİŞİ PANELİ ----------------
              _GirisPaneli(
                baslik: 'Vatandaş Girişi',
                ikon: Icons.person_outline,
                acik: _acikPanel == _AcikPanel.vatandas,
                onTap: () => _paneliAcKapat(_AcikPanel.vatandas),
                icerik: _VatandasGirisFormu(authService: _authService),
              ),
              const SizedBox(height: 12),

// ---------------- PERSONEL GİRİŞİ PANELİ (Yetkili + Saha Ekibi) ----------------
              _GirisPaneli(
                baslik: 'Personel Girişi',
                ikon: Icons.badge_outlined,
                acik: _acikPanel == _AcikPanel.personel,
                onTap: () => _paneliAcKapat(_AcikPanel.personel),
                icerik: _PersonelGirisFormu(authService: _authService),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
          child: Text(
            '© ${DateTime.now().year} Trabzon Büyükşehir Belediyesi\nSürüm 1.0.0',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11, 
              color: AppColors.textSecondary, 
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
/// Tıklanınca açılıp kapanan giriş paneli (accordion).
class _GirisPaneli extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final bool acik;
  final VoidCallback onTap;
  final Widget icerik;

  const _GirisPaneli({
    required this.baslik,
    required this.ikon,
    required this.acik,
    required this.onTap,
    required this.icerik,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: acik ? AppColors.primary : Colors.black.withValues(alpha: 0.08),
          width: acik ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(ikon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      baslik,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  AnimatedRotation(
                    turns: acik ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: icerik,
            ),
            crossFadeState: acik ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// VATANDAŞ GİRİŞİ — Telefon + OTP
// ============================================================

class _VatandasGirisFormu extends StatefulWidget {
  final AuthService authService;
  const _VatandasGirisFormu({required this.authService});

  @override
  State<_VatandasGirisFormu> createState() => _VatandasGirisFormuState();
}

class _VatandasGirisFormuState extends State<_VatandasGirisFormu> {
  final _telefonController = TextEditingController();
  final _kodController = TextEditingController();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();

  String? _verificationId;
  bool _yukleniyor = false;
  String? _hataMesaji;

  String _telefonuFormatla(String yerelNumara) {
    final digits = yerelNumara.replaceAll(RegExp(r'[^0-9]'), '');
    return '+90$digits';
  }

  @override
  void dispose() {
    _telefonController.dispose();
    _kodController.dispose();
    _adController.dispose();
    _soyadController.dispose();
    super.dispose();
  }

  Future<void> _koduGonder() async {
    final yerelNumara = _telefonController.text.trim();

    if (yerelNumara.length < 10) {
      setState(() {
        _hataMesaji = 'Lütfen geçerli bir telefon numarası girin (10 haneli).';
      });
      return;
    }

  final telefon = _telefonuFormatla(yerelNumara);

    setState(() {
      _yukleniyor = true;
      _hataMesaji = null;
    });

    await widget.authService.telefonIleKodGonder(
      telefon: telefon,
      kodGonderildi: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _yukleniyor = false;
        });
      },
      hataOlustu: (hata) {
        setState(() {
          _hataMesaji = hata;
          _yukleniyor = false;
        });
      },
    );
  }

  Future<void> _girisiTamamla() async {
    final kod = _kodController.text.trim();

    if (kod.isEmpty) {
      setState(() => _hataMesaji = 'Lütfen size gelen kodu girin.');
      return;
    }

    setState(() {
      _yukleniyor = true;
      _hataMesaji = null;
    });

    try {
      await widget.authService.otpIleGirisYap(
        verificationId: _verificationId!,
        smsKodu: kod,
        ad: _adController.text.trim().isEmpty ? null : _adController.text.trim(),
        soyad: _soyadController.text.trim().isEmpty ? null : _soyadController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _hataMesaji = 'Kod hatalı ya da süresi doldu. Lütfen tekrar deneyin.';
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _telefonController,
          enabled: _verificationId == null,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: 'Telefon Numarası',
            hintText: '5XX XXX XX XX',
            prefixText: '+90 ',
            counterText: '',
          ),
        ),
        if (_verificationId != null) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _kodController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Doğrulama Kodu (SMS)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adController,
            decoration: const InputDecoration(labelText: 'Ad (opsiyonel, ilk girişte)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _soyadController,
            decoration: const InputDecoration(labelText: 'Soyad (opsiyonel, ilk girişte)'),
          ),
        ],
        const SizedBox(height: 14),
        if (_hataMesaji != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_hataMesaji!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
        if (_yukleniyor)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            onPressed: _verificationId == null ? _koduGonder : _girisiTamamla,
            child: Text(_verificationId == null ? 'OTP Kodu Gönder' : 'Giriş Yap'),
          ),
        if (_verificationId != null && !_yukleniyor)
          TextButton(
            onPressed: () {
              setState(() {
                _verificationId = null;
                _kodController.clear();
                _hataMesaji = null;
              });
            },
            child: const Text('Telefon numarasını değiştir'),
          ),
      ],
    );
  }
}

// ============================================================
// PERSONEL GİRİŞİ — E-posta + Şifre
// ============================================================

class _PersonelGirisFormu extends StatefulWidget {
  final AuthService authService;
  const _PersonelGirisFormu({required this.authService});

  @override
  State<_PersonelGirisFormu> createState() => _PersonelGirisFormuState();
}

class _PersonelGirisFormuState extends State<_PersonelGirisFormu> {
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();

  bool _yukleniyor = false;
  String? _hataMesaji;
  bool _sifreGoster = false;

  @override
  void dispose() {
    _emailController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    final email = _emailController.text.trim();
    final sifre = _sifreController.text;

    if (email.isEmpty || sifre.isEmpty) {
      setState(() => _hataMesaji = 'E-posta ve şifre alanlarını doldurun.');
      return;
    }

    setState(() {
      _yukleniyor = true;
      _hataMesaji = null;
    });

    try {
      await widget.authService.epostaIleGirisYap(email: email, sifre: sifre);
    } catch (e) {
      setState(() {
        _hataMesaji = 'E-posta veya şifre hatalı.';
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-posta'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sifreController,
          obscureText: !_sifreGoster,
          decoration: InputDecoration(
            labelText: 'Şifre',
            suffixIcon: IconButton(
              icon: Icon(_sifreGoster ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _sifreGoster = !_sifreGoster),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_hataMesaji != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_hataMesaji!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
        if (_yukleniyor)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(onPressed: _girisYap, child: const Text('Giriş Yap')),
      ],
    );
  }
}