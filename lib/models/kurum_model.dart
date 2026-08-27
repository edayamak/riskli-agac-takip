import 'package:cloud_firestore/cloud_firestore.dart';

class KurumModel {
  final String kurumId;
  final String kurumAdi;
  final String aciklama;
  final DateTime olusturmaTarihi;

  KurumModel({
    required this.kurumId,
    required this.kurumAdi,
    this.aciklama = '',
    required this.olusturmaTarihi,
  });

  factory KurumModel.fromMap(String id, Map<String, dynamic> map) {
    return KurumModel(
      kurumId: id,
      kurumAdi: map['kurumAdi'] ?? '',
      aciklama: map['aciklama'] ?? '',
      olusturmaTarihi: (map['olusturmaTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kurumAdi': kurumAdi,
      'aciklama': aciklama,
      'olusturmaTarihi': Timestamp.fromDate(olusturmaTarihi),
    };
  }
}