import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kullanici_model.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Şu an giriş yapmış kullanıcı (hiç giriş yoksa null)
  User? get mevcutKullanici => _auth.currentUser;

  /// Auth durumunu dinlemek için stream (AuthGate bunu kullanacak)
  Stream<User?> get authDurumu => _auth.authStateChanges();

  // ============================================================
  // VATANDAŞ GİRİŞİ — Telefon numarası + OTP (SMS kodu)
  // ============================================================

  /// 1. Adım: Telefon numarasına doğrulama kodu gönderir.
  /// [telefon] uluslararası formatta olmalı, örn: +905551234567
  Future<void> telefonIleKodGonder({
    required String telefon,
    required Function(String verificationId) kodGonderildi,
    required Function(String hata) hataOlustu,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: telefon,
      timeout: const Duration(seconds: 60),

      // Bazı Android cihazlarda SMS otomatik algılanıp giriş otomatik tamamlanabilir
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        hataOlustu(e.message ?? 'Doğrulama başarısız oldu.');
      },

      // Kod gönderildiğinde bu verificationId'yi ekranda saklayıp
      // kullanıcı OTP'yi girdiğinde 2. adımda kullanacağız
      codeSent: (String verificationId, int? resendToken) {
        kodGonderildi(verificationId);
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// 2. Adım: Kullanıcının girdiği OTP kodu ile girişi tamamlar.
  /// Eğer kullanıcı ilk kez giriş yapıyorsa (yeni kayıt), [ad] ve [soyad]
  /// bilgileriyle Firestore'da Kullanicilar dokümanı oluşturur.
  Future<KullaniciModel> otpIleGirisYap({
    required String verificationId,
    required String smsKodu,
    String? ad,
    String? soyad,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsKodu,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Giriş yapılamadı, lütfen tekrar deneyin.');
    }

    return _kullaniciDokumaniGetirYaOlustur(
      uid: user.uid,
      telefon: user.phoneNumber ?? '',
      email: null,
      rol: KullaniciRol.vatandas,
      ad: ad,
      soyad: soyad,
    );
  }

  // ============================================================
  // PERSONEL GİRİŞİ — E-posta + Şifre (Yetkili / Saha Personeli)
  // ============================================================

  /// Personel girişi. Hesap zaten Firestore'da (yetkili tarafından
  /// admin panelinden ya da elle) oluşturulmuş olmalı.
  Future<KullaniciModel> epostaIleGirisYap({
    required String email,
    required String sifre,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: sifre,
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Giriş yapılamadı, lütfen tekrar deneyin.');
    }

    final dokuman = await _firestore
        .collection('Kullanicilar')
        .doc(user.uid)
        .get();

    if (!dokuman.exists) {
      throw Exception(
        'Bu hesaba ait kullanıcı bilgisi bulunamadı. '
        'Lütfen yetkili ile iletişime geçin.',
      );
    }

    return KullaniciModel.fromMap(user.uid, dokuman.data()!);
  }

  /// Yetkili tarafından yeni personel (yetkili ya da saha personeli) eklenmesi.
  /// Mevcut oturumu bozmadan gerçekleştirmek için ikincil bir Firebase App kullanılır.
  Future<void> personelEkle({
    required String email,
    required String sifre,
    required String ad,
    required String soyad,
    required String telefon,
    required KullaniciRol rol,
    String? kurumId,
    String? avatarId,
  }) async {
    FirebaseApp geciciApp;
    try {
      geciciApp = Firebase.app('gecici_personel_ekleme');
    } catch (e) {
      geciciApp = await Firebase.initializeApp(
        name: 'gecici_personel_ekleme',
        options: Firebase.app().options,
      );
    }

    final geciciAuth = FirebaseAuth.instanceFor(app: geciciApp);

    try {
      final userCredential = await geciciAuth.createUserWithEmailAndPassword(
        email: email,
        password: sifre,
      );

      final yeniUid = userCredential.user!.uid;

      final yeniKullanici = KullaniciModel(
        kullaniciId: yeniUid,
        ad: ad,
        soyad: soyad,
        telefon: telefon,
        email: email,
        rol: rol,
        kurumId: kurumId,
        olusturmaTarihi: DateTime.now(),
        avatarId: avatarId,
      );

      await _firestore.collection('Kullanicilar').doc(yeniUid).set(yeniKullanici.toMap());
    } finally {
      // İkincil oturumu her durumda temizle, ana oturuma dokunma
      await geciciAuth.signOut();
    }
  }

  // ============================================================
  // ORTAK YARDIMCI METOTLAR
  // ============================================================

  /// Firestore'da kullanıcı dokümanı varsa getirir, yoksa
  /// (vatandaşın ilk girişinde) yeni bir doküman oluşturur.
  Future<KullaniciModel> _kullaniciDokumaniGetirYaOlustur({
    required String uid,
    required String telefon,
    String? email,
    required KullaniciRol rol,
    String? ad,
    String? soyad,
  }) async {
    final dokumanRef = _firestore.collection('Kullanicilar').doc(uid);
    final dokuman = await dokumanRef.get();

    if (dokuman.exists) {
      return KullaniciModel.fromMap(uid, dokuman.data()!);
    }

    final yeniKullanici = KullaniciModel(
      kullaniciId: uid,
      ad: ad ?? '',
      soyad: soyad ?? '',
      telefon: telefon,
      email: email,
      rol: rol,
      kurumId: null,
      olusturmaTarihi: DateTime.now(),
    );

    await dokumanRef.set(yeniKullanici.toMap());
    return yeniKullanici;
  }

  /// Giriş yapmış kullanıcının Firestore bilgisini (rolü dahil) getirir.
  /// AuthGate bunu kullanarak hangi ekrana yönlendireceğine karar verecek.
  Future<KullaniciModel?> girisYapmisKullaniciBilgisiGetir() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final dokuman = await _firestore
        .collection('Kullanicilar')
        .doc(user.uid)
        .get();

    if (!dokuman.exists) return null;
    return KullaniciModel.fromMap(user.uid, dokuman.data()!);
  }

  Future<void> cikisYap() async {
    await _auth.signOut();
  }

  /// Kullanıcının kendi hesabını kalıcı olarak silmesi (Profil ekranı için).
  /// Güvenlik nedeniyle Firebase, uzun süredir giriş yapılmış hesaplarda
  /// önce yeniden giriş istenmesini talep edebilir.
  Future<void> hesabiSil() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('Kullanicilar').doc(user.uid).delete();
    await user.delete();
  }
}