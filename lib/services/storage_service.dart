import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Bir fotoğrafı Firebase Storage'a yükler, herkese açık indirme
  /// linkini (download URL) geri döner.
  ///
  /// [klasor] örn: 'bildirimler', 'mudahaleler'
  /// [dosyaAdi] benzersiz bir isim olmalı, çakışmayı önlemek için
  /// genelde zaman damgası + orijinal uzantı kullanılır.
  Future<String> fotografYukle({
    required File dosya,
    required String klasor,
  }) async {
    final dosyaAdi =
        '${DateTime.now().millisecondsSinceEpoch}_${dosya.path.split('/').last}';
    final ref = _storage.ref().child('$klasor/$dosyaAdi');

    final uploadTask = await ref.putFile(dosya);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }

  /// Birden fazla fotoğrafı sırayla yükler, tüm URL'leri liste olarak döner.
  Future<List<String>> cokluFotografYukle({
    required List<File> dosyalar,
    required String klasor,
  }) async {
    final List<String> urller = [];
    for (final dosya in dosyalar) {
      final url = await fotografYukle(dosya: dosya, klasor: klasor);
      urller.add(url);
    }
    return urller;
  }

  /// Storage'dan bir dosyayı siler (URL üzerinden referans bularak)
  Future<void> fotografSil(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // Dosya zaten silinmişse ya da bulunamazsa sessizce geç
    }
  }

    /// Herhangi bir dosyayı (video, belge, vs.) yükler, indirme linkini döner.
  Future<String> dosyaYukle({
    required File dosya,
    required String klasor,
  }) async {
    final dosyaAdi =
        '${DateTime.now().millisecondsSinceEpoch}_${dosya.path.split('/').last}';
    final ref = _storage.ref().child('$klasor/$dosyaAdi');

    final uploadTask = await ref.putFile(dosya);
    return await uploadTask.ref.getDownloadURL();
  }
}