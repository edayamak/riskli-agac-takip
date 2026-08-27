import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class KonumSonucu {
  final double lat;
  final double lng;
  final String adres;

  KonumSonucu({required this.lat, required this.lng, required this.adres});
}

class LocationService {
  final Geocoding _geocoding = Geocoding(locale: const Locale('tr', 'TR'));

  Future<Position> mevcutKonumuAl() async {
    bool servisAcik = await Geolocator.isLocationServiceEnabled();
    if (!servisAcik) {
      throw Exception('Konum servisleri kapali. Lutfen GPS ayarini acin.');
    }

    LocationPermission izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
      if (izin == LocationPermission.denied) {
        throw Exception('Konum izni reddedildi.');
      }
    }

    if (izin == LocationPermission.deniedForever) {
      throw Exception(
        'Konum izni kalici olarak reddedildi. Ayarlardan izin vermeniz gerekiyor.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<String> adresBul(double lat, double lng) async {
    try {
      final yerler = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (yerler.isEmpty) return '';

      final yer = yerler.first;
      final parcalar = <String>[];

      if (yer.subLocality != null && yer.subLocality!.isNotEmpty) {
        parcalar.add(yer.subLocality!);
      }
      if (yer.locality != null && yer.locality!.isNotEmpty) {
        parcalar.add(yer.locality!);
      }
      if (yer.administrativeArea != null && yer.administrativeArea!.isNotEmpty) {
        parcalar.add(yer.administrativeArea!);
      }

      return parcalar.join(', ');
    } catch (e) {
      return '';
    }
  }

  Future<KonumSonucu> konumVeAdresAl() async {
    final position = await mevcutKonumuAl();
    final adres = await adresBul(position.latitude, position.longitude);

    return KonumSonucu(
      lat: position.latitude,
      lng: position.longitude,
      adres: adres,
    );
  }
}