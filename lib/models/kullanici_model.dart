import 'package:cloud_firestore/cloud_firestore.dart';

enum KullaniciRol { vatandas, yetkili, sahaPersoneli }

KullaniciRol rolFromString(String value) {
  switch (value) {
    case 'vatandas':
      return KullaniciRol.vatandas;
    case 'yetkili':
      return KullaniciRol.yetkili;
    case 'saha_personeli':
      return KullaniciRol.sahaPersoneli;
    default:
      throw ArgumentError('Bilinmeyen rol: $value');
  }
}

String rolToString(KullaniciRol rol) {
  switch (rol) {
    case KullaniciRol.vatandas:
      return 'vatandas';
    case KullaniciRol.yetkili:
      return 'yetkili';
    case KullaniciRol.sahaPersoneli:
      return 'saha_personeli';
  }
}

class KullaniciModel {
  final String kullaniciId;
  final String ad;
  final String soyad;
  final String telefon;
  final String? email;
  final KullaniciRol rol;
  final String? kurumId;
  final DateTime olusturmaTarihi;
  final String? avatarId;

  KullaniciModel({
    required this.kullaniciId,
    required this.ad,
    required this.soyad,
    required this.telefon,
    this.email,
    required this.rol,
    this.kurumId,
    required this.olusturmaTarihi,
    this.avatarId,
  });

  String get tamAd => '$ad $soyad';

  factory KullaniciModel.fromMap(String id, Map<String, dynamic> map) {
      return KullaniciModel(
        kullaniciId: id,
        ad: map['ad'] ?? '',
        soyad: map['soyad'] ?? '',
        telefon: map['telefon'] ?? '',
        email: map['email'],
        rol: rolFromString(map['rol'] ?? 'vatandas'),
        kurumId: map['kurumId'],
        olusturmaTarihi: (map['olusturmaTarihi'] as Timestamp?)?.toDate()
            ?? DateTime.now(),
        avatarId: map['avatarId'],
      );
    }

  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
      'email': email,
      'rol': rolToString(rol),
      'kurumId': kurumId,
      'olusturmaTarihi': Timestamp.fromDate(olusturmaTarihi),
      'avatarId': avatarId,
    };
  }
}