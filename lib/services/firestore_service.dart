import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bildirim_model.dart';
import '../models/gorev_model.dart';
import '../models/mudahale_model.dart';
import '../models/kullanici_model.dart';
import '../models/kurum_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // BİLDİRİMLER
  // ============================================================

  /// Yeni bir riskli ağaç bildirimi oluşturur (vatandaş tarafından).
  Future<String> bildirimOlustur({
    required String bildirenKullaniciId,
    required double konumLat,
    required double konumLng,
    required String adres,
    required List<String> fotograflar,
    required String aciklama,
    required RiskTipi riskTipi,
    String? videoUrl,
    List<String> belgeler = const [],
  }) async {
    final veri = BildirimModel.yeniKayitMap(
      bildirenKullaniciId: bildirenKullaniciId,
      konumLat: konumLat,
      konumLng: konumLng,
      adres: adres,
      fotograflar: fotograflar,
      aciklama: aciklama,
      riskTipi: riskTipi,
      videoUrl: videoUrl,
      belgeler: belgeler,
    );

    final docRef = await _db.collection('Bildirimler').add(veri);
    return docRef.id;
  }

  /// Belirli bir kullanıcının kendi bildirimlerini gerçek zamanlı dinler.
  Stream<List<BildirimModel>> kullaniciBildirimleriStream(String kullaniciId) {
    return _db
        .collection('Bildirimler')
        .where('bildirenKullaniciId', isEqualTo: kullaniciId)
        .orderBy('olusturmaTarihi', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BildirimModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Yetkili paneli için: tüm bildirimleri (opsiyonel durum filtresiyle) dinler.
  Stream<List<BildirimModel>> tumBildirimlerStream({BildirimDurumu? durum}) {
    Query query = _db
        .collection('Bildirimler')
        .orderBy('olusturmaTarihi', descending: true);

    if (durum != null) {
      query = query.where('durum', isEqualTo: durumToString(durum));
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            BildirimModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Tek bir bildirimi ID ile getirir (detay ekranı için).
  Future<BildirimModel?> bildirimGetir(String bildirimId) async {
    final doc = await _db.collection('Bildirimler').doc(bildirimId).get();
    if (!doc.exists) return null;
    return BildirimModel.fromMap(doc.id, doc.data()!);
  }

  /// Yetkili, bildirimi inceleyip risk seviyesi belirler.
  Future<void> bildirimIncele({
    required String bildirimId,
    required RiskSeviyesi riskSeviyesi,
  }) async {
    await _db.collection('Bildirimler').doc(bildirimId).update({
      'riskSeviyesi': riskSeviyesiToString(riskSeviyesi),
      'durum': durumToString(BildirimDurumu.incelendi),
    });

    await _durumGecmisiEkle(
      bildirimId: bildirimId,
      eskiDurum: 'beklemede',
      yeniDurum: 'incelendi',
    );
  }

  /// Yetkili, müdahale gerekmediğine karar verirse kaydı kapatır.
  Future<void> bildirimKapat(String bildirimId) async {
    await _db.collection('Bildirimler').doc(bildirimId).update({
      'durum': durumToString(BildirimDurumu.kapatildi),
    });

    await _durumGecmisiEkle(
      bildirimId: bildirimId,
      eskiDurum: 'incelendi',
      yeniDurum: 'kapatildi',
    );
  }

  /// Bildirim durumunu günceller (görev atandığında ya da müdahale
  /// tamamlandığında çağrılır).
  Future<void> bildirimDurumGuncelle({
    required String bildirimId,
    required BildirimDurumu yeniDurum,
    String? atananKurumId,
  }) async {
    final guncelleme = <String, dynamic>{
      'durum': durumToString(yeniDurum),
    };
    if (atananKurumId != null) {
      guncelleme['atananKurumId'] = atananKurumId;
    }

    await _db.collection('Bildirimler').doc(bildirimId).update(guncelleme);
  }

  // ============================================================
  // GÖREVLER
  // ============================================================

  /// Yetkili, bildirime karşılık bir saha ekibine görev atar.
  Future<String> gorevOlustur({
    required String bildirimId,
    required String atananPersonelId,
    required String atayanYetkiliId,
    required GorevOncelik oncelik,
  }) async {
    final veri = GorevModel.yeniKayitMap(
      bildirimId: bildirimId,
      atananPersonelId: atananPersonelId,
      atayanYetkiliId: atayanYetkiliId,
      oncelik: oncelik,
    );

    final docRef = await _db.collection('Gorevler').add(veri);

    // Bildirimin durumunu da güncelle
    await bildirimDurumGuncelle(
      bildirimId: bildirimId,
      yeniDurum: BildirimDurumu.gorevAtandi,
    );

    await _durumGecmisiEkle(
      bildirimId: bildirimId,
      eskiDurum: 'incelendi',
      yeniDurum: 'gorev_atandi',
    );

    return docRef.id;
  }

  /// Saha personelinin kendi görevlerini gerçek zamanlı dinlemesi.
  Stream<List<GorevModel>> personelGorevleriStream(String personelId) {
    return _db
        .collection('Gorevler')
        .where('atananPersonelId', isEqualTo: personelId)
        .orderBy('atanmaTarihi', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GorevModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> gorevDurumGuncelle({
    required String gorevId,
    required GorevDurumu yeniDurum,
  }) async {
    final guncelleme = <String, dynamic>{
      'durum': gorevDurumToString(yeniDurum),
    };

    if (yeniDurum == GorevDurumu.tamamlandi) {
      guncelleme['tamamlanmaTarihi'] = FieldValue.serverTimestamp();
    }

    await _db.collection('Gorevler').doc(gorevId).update(guncelleme);
  }

  // ============================================================
  // MÜDAHALELER
  // ============================================================

  /// Saha personeli müdahaleyi tamamlayıp kaydeder.
  Future<String> mudahaleOlustur({
    required String gorevId,
    required String bildirimId,
    required String personelId,
    required MudahaleTipi mudahaleTipi,
    String? oncesiFotograf,
    String? sonrasiFotograf,
    String not = '',
    String? videoUrl,
    List<String> belgeler = const [],
  }) async {
    final veri = MudahaleModel.yeniKayitMap(
      gorevId: gorevId,
      personelId: personelId,
      mudahaleTipi: mudahaleTipi,
      oncesiFotograf: oncesiFotograf,
      sonrasiFotograf: sonrasiFotograf,
      not: not,
      videoUrl: videoUrl,
      belgeler: belgeler,
    );

    final docRef = await _db.collection('Mudahaleler').add(veri);

    // Görevi tamamlandı yap
    await gorevDurumGuncelle(gorevId: gorevId, yeniDurum: GorevDurumu.tamamlandi);

    // Bildirimi güncelle: gereksizse "kapatıldı", değilse "müdahale edildi"
    final yeniDurum = mudahaleTipi == MudahaleTipi.gereksiz
        ? BildirimDurumu.kapatildi
        : BildirimDurumu.mudahaleEdildi;

    await bildirimDurumGuncelle(bildirimId: bildirimId, yeniDurum: yeniDurum);

    await _durumGecmisiEkle(
      bildirimId: bildirimId,
      eskiDurum: 'gorev_atandi',
      yeniDurum: durumToString(yeniDurum),
    );

    return docRef.id;
  }

  // ============================================================
  // KULLANICILAR (yardımcı sorgular)
  // ============================================================

  /// Kurum filtresi olmadan TÜM saha personelini listeler.
  /// (Test/geliştirme aşamasında kurumId her zaman dolu olmayabileceği için)
  Stream<List<KullaniciModel>> tumSahaPersoneliStream() {
    return _db
        .collection('Kullanicilar')
        .where('rol', isEqualTo: 'saha_personeli')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KullaniciModel.fromMap(doc.id, doc.data()))
            .toList());
  }

    /// Tüm personeli (yetkili + saha personeli) listeler, isim sırasına göre.
  Stream<List<KullaniciModel>> personelListesiStream() {
    return _db
        .collection('Kullanicilar')
        .where('rol', whereIn: ['yetkili', 'saha_personeli'])
        .snapshots()
        .map((snapshot) {
          final liste = snapshot.docs
              .map((doc) => KullaniciModel.fromMap(doc.id, doc.data()))
              .toList();
          liste.sort((a, b) => a.ad.compareTo(b.ad));
          return liste;
        });
  }

  // ============================================================
  // KURUMLAR
  // ============================================================

  Stream<List<KurumModel>> kurumlarStream() {
    return _db.collection('Kurumlar').orderBy('kurumAdi').snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => KurumModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> kurumEkle({required String kurumAdi, String aciklama = ''}) async {
    await _db.collection('Kurumlar').add({
      'kurumAdi': kurumAdi,
      'aciklama': aciklama,
      'olusturmaTarihi': FieldValue.serverTimestamp(),
    });
  }

  Future<void> kurumSil(String kurumId) async {
    await _db.collection('Kurumlar').doc(kurumId).delete();
  }

    /// Tek bir kurumun bilgisini getirir (Profil ekranında görüntülemek için).
  Future<KurumModel?> kurumGetir(String kurumId) async {
    final doc = await _db.collection('Kurumlar').doc(kurumId).get();
    if (!doc.exists) return null;
    return KurumModel.fromMap(doc.id, doc.data()!);
  }

    /// Yetkilinin bir personelin rol/kurum bilgisini güncellemesi.
  Future<void> personelGuncelle({
    required String kullaniciId,
    required KullaniciRol rol,
    String? kurumId,
  }) async {
    await _db.collection('Kullanicilar').doc(kullaniciId).update({
      'rol': rolToString(rol),
      'kurumId': kurumId,
    });
  }

  /// Personel kaydını Firestore'dan siler.
  /// NOT: Bu yalnızca Firestore profilini siler; ilgili Firebase Authentication
  /// hesabını silmek için Admin SDK / Cloud Function gerekir (client tarafından yapılamaz).
  Future<void> personelSil(String kullaniciId) async {
    await _db.collection('Kullanicilar').doc(kullaniciId).delete();
  }

  /// Kullanıcının kendi profilini güncellemesi (Profil ekranı için)
  Future<void> kullaniciGuncelle({
    required String kullaniciId,
    required String ad,
    required String soyad,
    required String telefon,
  }) async {
    await _db.collection('Kullanicilar').doc(kullaniciId).update({
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
    });
  }
  /// Kullanıcının hazır avatarlardan birini seçmesi.
  Future<void> avatarGuncelle({
    required String kullaniciId,
    required String avatarId,
  }) async {
    await _db.collection('Kullanicilar').doc(kullaniciId).update({
      'avatarId': avatarId,
    });
  }
  /// Tek bir kullanıcının bilgilerini gerçek zamanlı dinler (Profil ekranı için).
  Stream<KullaniciModel?> kullaniciStream(String kullaniciId) {
    return _db.collection('Kullanicilar').doc(kullaniciId).snapshots().map(
      (doc) => doc.exists ? KullaniciModel.fromMap(doc.id, doc.data()!) : null,
    );
  }

  /// Acil ya da yüksek risk seviyesindeki, henüz kapanmamış bildirimleri getirir.
  Stream<List<BildirimModel>> acilBildirimlerStream() {
    return _db
        .collection('Bildirimler')
        .where('riskSeviyesi', whereIn: ['acil', 'yuksek'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BildirimModel.fromMap(doc.id, doc.data()))
            .where((b) => b.durum != BildirimDurumu.kapatildi)
            .toList());
  }

  /// Saha personeli sayısını dinler (ana sayfa istatistiği için).
  Stream<int> sahaPersoneliSayisiStream() {
    return _db
        .collection('Kullanicilar')
        .where('rol', isEqualTo: 'saha_personeli')
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ============================================================
  // DURUM GEÇMİŞİ (LOG)
  // ============================================================

  Future<void> _durumGecmisiEkle({
    required String bildirimId,
    required String eskiDurum,
    required String yeniDurum,
  }) async {
    await _db.collection('DurumGecmisi').add({
      'bildirimId': bildirimId,
      'eskiDurum': eskiDurum,
      'yeniDurum': yeniDurum,
      'tarih': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> bildirimGecmisiStream(String bildirimId) {
    return _db
        .collection('DurumGecmisi')
        .where('bildirimId', isEqualTo: bildirimId)
        .orderBy('tarih', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

    /// Tek bir kullanıcıyı ID ile getirir (harita pin'i için avatar bilgisi).
  Future<KullaniciModel?> kullaniciGetir(String kullaniciId) async {
    final doc = await _db.collection('Kullanicilar').doc(kullaniciId).get();
    if (!doc.exists) return null;
    return KullaniciModel.fromMap(doc.id, doc.data()!);
  }
}