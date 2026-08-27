import 'package:cloud_firestore/cloud_firestore.dart';

enum RiskTipi { kurumus, hastalikli, devrilmeRiski, budamaIhtiyaci, firtinaRiski }

enum RiskSeviyesi { belirlenmedi, dusuk, orta, yuksek, acil }

enum BildirimDurumu { beklemede, incelendi, gorevAtandi, mudahaleEdildi, kapatildi }

RiskTipi riskTipiFromString(String value) {
  switch (value) {
    case 'kurumus':
      return RiskTipi.kurumus;
    case 'hastalikli':
      return RiskTipi.hastalikli;
    case 'devrilme_riski':
      return RiskTipi.devrilmeRiski;
    case 'budama_ihtiyaci':
      return RiskTipi.budamaIhtiyaci;
    case 'firtina_riski':
      return RiskTipi.firtinaRiski;
    default:
      throw ArgumentError('Bilinmeyen risk tipi: $value');
  }
}

String riskTipiToString(RiskTipi tip) {
  switch (tip) {
    case RiskTipi.kurumus:
      return 'kurumus';
    case RiskTipi.hastalikli:
      return 'hastalikli';
    case RiskTipi.devrilmeRiski:
      return 'devrilme_riski';
    case RiskTipi.budamaIhtiyaci:
      return 'budama_ihtiyaci';
    case RiskTipi.firtinaRiski:
      return 'firtina_riski';
  }
}

RiskSeviyesi riskSeviyesiFromString(String? value) {
  switch (value) {
    case 'dusuk':
      return RiskSeviyesi.dusuk;
    case 'orta':
      return RiskSeviyesi.orta;
    case 'yuksek':
      return RiskSeviyesi.yuksek;
    case 'acil':
      return RiskSeviyesi.acil;
    default:
      return RiskSeviyesi.belirlenmedi;
  }
}

String riskSeviyesiToString(RiskSeviyesi seviye) {
  switch (seviye) {
    case RiskSeviyesi.belirlenmedi:
      return '';
    case RiskSeviyesi.dusuk:
      return 'dusuk';
    case RiskSeviyesi.orta:
      return 'orta';
    case RiskSeviyesi.yuksek:
      return 'yuksek';
    case RiskSeviyesi.acil:
      return 'acil';
  }
}

BildirimDurumu durumFromString(String value) {
  switch (value) {
    case 'beklemede':
      return BildirimDurumu.beklemede;
    case 'incelendi':
      return BildirimDurumu.incelendi;
    case 'gorev_atandi':
      return BildirimDurumu.gorevAtandi;
    case 'mudahale_edildi':
      return BildirimDurumu.mudahaleEdildi;
    case 'kapatildi':
      return BildirimDurumu.kapatildi;
    default:
      throw ArgumentError('Bilinmeyen durum: $value');
  }
}

String durumToString(BildirimDurumu durum) {
  switch (durum) {
    case BildirimDurumu.beklemede:
      return 'beklemede';
    case BildirimDurumu.incelendi:
      return 'incelendi';
    case BildirimDurumu.gorevAtandi:
      return 'gorev_atandi';
    case BildirimDurumu.mudahaleEdildi:
      return 'mudahale_edildi';
    case BildirimDurumu.kapatildi:
      return 'kapatildi';
  }
}

class BildirimModel {
  final String bildirimId;
  final String bildirenKullaniciId;
  final double konumLat;
  final double konumLng;
  final String adres;
  final List<String> fotograflar;
  final String aciklama;
  final RiskTipi riskTipi;
  final RiskSeviyesi riskSeviyesi;
  final BildirimDurumu durum;
  final String? atananKurumId;
  final DateTime olusturmaTarihi;
  final String? videoUrl;
  final List<String> belgeler;

  BildirimModel({
    required this.bildirimId,
    required this.bildirenKullaniciId,
    required this.konumLat,
    required this.konumLng,
    required this.adres,
    required this.fotograflar,
    required this.aciklama,
    required this.riskTipi,
    this.riskSeviyesi = RiskSeviyesi.belirlenmedi,
    this.durum = BildirimDurumu.beklemede,
    this.atananKurumId,
    required this.olusturmaTarihi,
    this.videoUrl,
    this.belgeler = const [],
  });

  factory BildirimModel.fromMap(String id, Map<String, dynamic> map) {
    return BildirimModel(
      bildirimId: id,
      bildirenKullaniciId: map['bildirenKullaniciId'] ?? '',
      konumLat: (map['konumLat'] as num?)?.toDouble() ?? 0.0,
      konumLng: (map['konumLng'] as num?)?.toDouble() ?? 0.0,
      adres: map['adres'] ?? '',
      fotograflar: List<String>.from(map['fotograflar'] ?? []),
      aciklama: map['aciklama'] ?? '',
      riskTipi: riskTipiFromString(map['riskTipi'] ?? 'kurumus'),
      riskSeviyesi: riskSeviyesiFromString(map['riskSeviyesi']),
      durum: durumFromString(map['durum'] ?? 'beklemede'),
      atananKurumId: map['atananKurumId'],
      olusturmaTarihi: (map['olusturmaTarihi'] as Timestamp?)?.toDate()
          ?? DateTime.now(),
      videoUrl: map['videoUrl'],
      belgeler: List<String>.from(map['belgeler'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bildirenKullaniciId': bildirenKullaniciId,
      'konumLat': konumLat,
      'konumLng': konumLng,
      'adres': adres,
      'fotograflar': fotograflar,
      'aciklama': aciklama,
      'riskTipi': riskTipiToString(riskTipi),
      'riskSeviyesi': riskSeviyesiToString(riskSeviyesi),
      'durum': durumToString(durum),
      'atananKurumId': atananKurumId,
      'olusturmaTarihi': Timestamp.fromDate(olusturmaTarihi),
      'videoUrl': videoUrl,
      'belgeler': belgeler,
    };
  }

  // Firestore'a yeni kayıt yazarken sunucu saatini kullanmak için
  static Map<String, dynamic> yeniKayitMap({
    required String bildirenKullaniciId,
    required double konumLat,
    required double konumLng,
    required String adres,
    required List<String> fotograflar,
    required String aciklama,
    required RiskTipi riskTipi,
    String? videoUrl,
    List<String> belgeler = const [],
  }) {
    return {
      'bildirenKullaniciId': bildirenKullaniciId,
      'konumLat': konumLat,
      'konumLng': konumLng,
      'adres': adres,
      'fotograflar': fotograflar,
      'aciklama': aciklama,
      'riskTipi': riskTipiToString(riskTipi),
      'riskSeviyesi': '',
      'durum': 'beklemede',
      'atananKurumId': null,
      'olusturmaTarihi': FieldValue.serverTimestamp(),
      'videoUrl': videoUrl,
      'belgeler': belgeler,
    };
  }
}