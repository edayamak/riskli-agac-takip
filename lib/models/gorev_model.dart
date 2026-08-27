import 'package:cloud_firestore/cloud_firestore.dart';

enum GorevOncelik { dusuk, orta, yuksek, acil }

enum GorevDurumu { atandi, devamEdiyor, tamamlandi }

GorevOncelik oncelikFromString(String value) {
  switch (value) {
    case 'dusuk':
      return GorevOncelik.dusuk;
    case 'orta':
      return GorevOncelik.orta;
    case 'yuksek':
      return GorevOncelik.yuksek;
    case 'acil':
      return GorevOncelik.acil;
    default:
      throw ArgumentError('Bilinmeyen öncelik: $value');
  }
}

String oncelikToString(GorevOncelik oncelik) {
  switch (oncelik) {
    case GorevOncelik.dusuk:
      return 'dusuk';
    case GorevOncelik.orta:
      return 'orta';
    case GorevOncelik.yuksek:
      return 'yuksek';
    case GorevOncelik.acil:
      return 'acil';
  }
}

GorevDurumu gorevDurumFromString(String value) {
  switch (value) {
    case 'atandi':
      return GorevDurumu.atandi;
    case 'devam_ediyor':
      return GorevDurumu.devamEdiyor;
    case 'tamamlandi':
      return GorevDurumu.tamamlandi;
    default:
      throw ArgumentError('Bilinmeyen görev durumu: $value');
  }
}

String gorevDurumToString(GorevDurumu durum) {
  switch (durum) {
    case GorevDurumu.atandi:
      return 'atandi';
    case GorevDurumu.devamEdiyor:
      return 'devam_ediyor';
    case GorevDurumu.tamamlandi:
      return 'tamamlandi';
  }
}

class GorevModel {
  final String gorevId;
  final String bildirimId;
  final String atananPersonelId;
  final String atayanYetkiliId;
  final GorevOncelik oncelik;
  final GorevDurumu durum;
  final DateTime atanmaTarihi;
  final DateTime? tamamlanmaTarihi;

  GorevModel({
    required this.gorevId,
    required this.bildirimId,
    required this.atananPersonelId,
    required this.atayanYetkiliId,
    this.oncelik = GorevOncelik.orta,
    this.durum = GorevDurumu.atandi,
    required this.atanmaTarihi,
    this.tamamlanmaTarihi,
  });

  factory GorevModel.fromMap(String id, Map<String, dynamic> map) {
    return GorevModel(
      gorevId: id,
      bildirimId: map['bildirimId'] ?? '',
      atananPersonelId: map['atananPersonelId'] ?? '',
      atayanYetkiliId: map['atayanYetkiliId'] ?? '',
      oncelik: oncelikFromString(map['oncelik'] ?? 'orta'),
      durum: gorevDurumFromString(map['durum'] ?? 'atandi'),
      atanmaTarihi: (map['atanmaTarihi'] as Timestamp?)?.toDate()
          ?? DateTime.now(),
      tamamlanmaTarihi: (map['tamamlanmaTarihi'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bildirimId': bildirimId,
      'atananPersonelId': atananPersonelId,
      'atayanYetkiliId': atayanYetkiliId,
      'oncelik': oncelikToString(oncelik),
      'durum': gorevDurumToString(durum),
      'atanmaTarihi': Timestamp.fromDate(atanmaTarihi),
      'tamamlanmaTarihi': tamamlanmaTarihi != null
          ? Timestamp.fromDate(tamamlanmaTarihi!)
          : null,
    };
  }

  static Map<String, dynamic> yeniKayitMap({
    required String bildirimId,
    required String atananPersonelId,
    required String atayanYetkiliId,
    required GorevOncelik oncelik,
  }) {
    return {
      'bildirimId': bildirimId,
      'atananPersonelId': atananPersonelId,
      'atayanYetkiliId': atayanYetkiliId,
      'oncelik': oncelikToString(oncelik),
      'durum': 'atandi',
      'atanmaTarihi': FieldValue.serverTimestamp(),
      'tamamlanmaTarihi': null,
    };
  }
}