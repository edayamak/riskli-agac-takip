import 'package:cloud_firestore/cloud_firestore.dart';

enum MudahaleTipi {
  budama,
  dalTemizleme,
  destekleme,
  kesme,
  kontrol,
  gereksiz,
}

MudahaleTipi mudahaleTipiFromString(String value) {
  switch (value) {
    case 'budama':
      return MudahaleTipi.budama;
    case 'dal_temizleme':
      return MudahaleTipi.dalTemizleme;
    case 'destekleme':
      return MudahaleTipi.destekleme;
    case 'kesme':
      return MudahaleTipi.kesme;
    case 'kontrol':
      return MudahaleTipi.kontrol;
    case 'gereksiz':
      return MudahaleTipi.gereksiz;
    default:
      throw ArgumentError('Bilinmeyen müdahale tipi: $value');
  }
}

String mudahaleTipiToString(MudahaleTipi tip) {
  switch (tip) {
    case MudahaleTipi.budama:
      return 'budama';
    case MudahaleTipi.dalTemizleme:
      return 'dal_temizleme';
    case MudahaleTipi.destekleme:
      return 'destekleme';
    case MudahaleTipi.kesme:
      return 'kesme';
    case MudahaleTipi.kontrol:
      return 'kontrol';
    case MudahaleTipi.gereksiz:
      return 'gereksiz';
  }
}

/// Ekranda kullanıcıya gösterilecek okunabilir metin
String mudahaleTipiEtiket(MudahaleTipi tip) {
  switch (tip) {
    case MudahaleTipi.budama:
      return 'Budama yapıldı';
    case MudahaleTipi.dalTemizleme:
      return 'Kuru dallar temizlendi';
    case MudahaleTipi.destekleme:
      return 'Ağaç desteklendi';
    case MudahaleTipi.kesme:
      return 'Ağaç kesildi';
    case MudahaleTipi.kontrol:
      return 'Yerinde kontrol yapıldı';
    case MudahaleTipi.gereksiz:
      return 'İşlem gereksiz görüldü';
  }
}

class MudahaleModel {
  final String mudahaleId;
  final String gorevId;
  final String personelId;
  final MudahaleTipi mudahaleTipi;
  final String? oncesiFotograf;
  final String? sonrasiFotograf;
  final String not;
  final DateTime tarih;
  final String? videoUrl;
  final List<String> belgeler;

  MudahaleModel({
    required this.mudahaleId,
    required this.gorevId,
    required this.personelId,
    required this.mudahaleTipi,
    this.oncesiFotograf,
    this.sonrasiFotograf,
    this.not = '',
    required this.tarih,
    this.videoUrl,
    this.belgeler = const [],
  });

  factory MudahaleModel.fromMap(String id, Map<String, dynamic> map) {
    return MudahaleModel(
      mudahaleId: id,
      gorevId: map['gorevId'] ?? '',
      personelId: map['personelId'] ?? '',
      mudahaleTipi: mudahaleTipiFromString(map['mudahaleTipi'] ?? 'kontrol'),
      oncesiFotograf: map['oncesiFotograf'],
      sonrasiFotograf: map['sonrasiFotograf'],
      not: map['not'] ?? '',
      tarih: (map['tarih'] as Timestamp?)?.toDate() ?? DateTime.now(),
      videoUrl: map['videoUrl'],
      belgeler: List<String>.from(map['belgeler'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gorevId': gorevId,
      'personelId': personelId,
      'mudahaleTipi': mudahaleTipiToString(mudahaleTipi),
      'oncesiFotograf': oncesiFotograf,
      'sonrasiFotograf': sonrasiFotograf,
      'not': not,
      'tarih': Timestamp.fromDate(tarih),
      'videoUrl': videoUrl,
      'belgeler': belgeler,
    };
  }

  static Map<String, dynamic> yeniKayitMap({
    required String gorevId,
    required String personelId,
    required MudahaleTipi mudahaleTipi,
    String? oncesiFotograf,
    String? sonrasiFotograf,
    String not = '',
    String? videoUrl,
    List<String> belgeler = const [],
  }) {
    return {
      'gorevId': gorevId,
      'personelId': personelId,
      'mudahaleTipi': mudahaleTipiToString(mudahaleTipi),
      'oncesiFotograf': oncesiFotograf,
      'sonrasiFotograf': sonrasiFotograf,
      'not': not,
      'tarih': FieldValue.serverTimestamp(),
      'videoUrl': videoUrl,
      'belgeler': belgeler,
    };
  }
}