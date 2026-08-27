import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bildirim_model.dart';
import '../../../models/kullanici_model.dart';
import '../../../services/firestore_service.dart';
import 'bildirim_inceleme_screen.dart';
import 'package:flutter/gestures.dart';


class HaritaView extends StatefulWidget {
  final KullaniciModel yetkili;
  const HaritaView({super.key, required this.yetkili});

  @override
  State<HaritaView> createState() => _HaritaViewState();
}

class _HaritaViewState extends State<HaritaView> {
  final FirestoreService _firestoreService = FirestoreService();
  GoogleMapController? _mapController;
  bool _panelAcik = false;
  MapType _haritaTipi = MapType.normal;


  static const CameraPosition _baslangicKonumu = CameraPosition(
    target: LatLng(41.0027, 39.7168),
    zoom: 12,
  );

  void _haritaTipiniDegistir() {
    setState(() {
      switch (_haritaTipi) {
        case MapType.normal:
          _haritaTipi = MapType.satellite;
          break;
        case MapType.satellite:
          _haritaTipi = MapType.hybrid;
          break;
        default:
          _haritaTipi = MapType.normal;
      }
    });
  }

  IconData get _haritaTipiIkonu {
    switch (_haritaTipi) {
      case MapType.normal:
        return Icons.map_outlined;
      case MapType.satellite:
        return Icons.satellite_alt;
      default:
        return Icons.layers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BildirimModel>>(
      stream: _firestoreService.tumBildirimlerStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        }

        final bildirimler = snapshot.data ?? [];

        final markerlar = bildirimler.map((bildirim) {
          return Marker(
            markerId: MarkerId(bildirim.bildirimId),
            position: LatLng(bildirim.konumLat, bildirim.konumLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(_durumHue(bildirim.durum)),
            infoWindow: InfoWindow(
              title: _riskTipiEtiket(bildirim.riskTipi),
              snippet: '${_durumEtiket(bildirim.durum)} • ${bildirim.adres.isNotEmpty ? bildirim.adres : "Adres bilgisi yok"}',
              onTap: () => _incelemeyeGit(bildirim),
            ),
          );
        }).toSet();

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _baslangicKonumu,
              markers: markerlar,
              mapType: _haritaTipi,
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),

            // Üst bilgi çubuğu
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _ustBilgiCubugu(bildirimler.length),
            ),

            // Sağ üstte harita tipi değiştirme butonu
            Positioned(
              top: 70,
              right: 12,
              child: _haritaTipiButonu(),
            ),

            // Sağ panel
            if (_panelAcik)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _panelAcik = false),
                  child: Container(color: Colors.black.withValues(alpha: 0.25)),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              top: 0,
              bottom: 0,
              right: _panelAcik ? 0 : -300,
              width: 300,
              child: Material(
                elevation: 8,
                child: _bildirimPaneli(bildirimler),
              ),
            ),
          ],
        );
      },
    );
  }

  void _incelemeyeGit(BildirimModel bildirim) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BildirimIncelemeScreen(bildirim: bildirim, yetkili: widget.yetkili),
      ),
    );
  }

  Widget _ustBilgiCubugu(int toplamSayi) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _panelAcik = true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.park, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Toplam $toplamSayi bildirim', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _haritaTipiButonu() {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _haritaTipiniDegistir,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(_haritaTipiIkonu, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }

  Widget _bildirimPaneli(List<BildirimModel> bildirimler) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _panelAcik = false)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendSatiri(Colors.orange, 'Beklemede'),
                  _legendSatiri(Colors.blue, 'İncelendi'),
                  _legendSatiri(Colors.purple, 'Görev Atandı'),
                  _legendSatiri(Colors.cyan.shade700, 'Müdahale Edildi'),
                  _legendSatiri(Colors.red, 'Kapatıldı'),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: bildirimler.isEmpty
                  ? const Center(child: Text('Bildirim bulunamadı.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: bildirimler.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _panelKarti(bildirimler[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelKarti(BildirimModel bildirim) {
    return Card(
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _durumRengi(bildirim.durum).withValues(alpha: 0.15),
          child: Icon(Icons.circle, size: 10, color: _durumRengi(bildirim.durum)),
        ),
        title: Text(_riskTipiEtiket(bildirim.riskTipi), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(
          bildirim.adres.isNotEmpty ? bildirim.adres : 'Adres bilgisi yok',
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          setState(() => _panelAcik = false);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(bildirim.konumLat, bildirim.konumLng), 15),
          );
        },
      ),
    );
  }

  Widget _legendSatiri(Color renk, String etiket) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: renk, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(etiket, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Color _durumRengi(BildirimDurumu durum) {
    switch (durum) {
      case BildirimDurumu.beklemede:
        return Colors.orange;
      case BildirimDurumu.incelendi:
        return Colors.blue;
      case BildirimDurumu.gorevAtandi:
        return Colors.purple;
      case BildirimDurumu.mudahaleEdildi:
        return Colors.cyan.shade700;
      case BildirimDurumu.kapatildi:
        return Colors.red;
    }
  }

  double _durumHue(BildirimDurumu durum) {
    switch (durum) {
      case BildirimDurumu.beklemede:
        return BitmapDescriptor.hueOrange;
      case BildirimDurumu.incelendi:
        return BitmapDescriptor.hueAzure;
      case BildirimDurumu.gorevAtandi:
        return BitmapDescriptor.hueViolet;
      case BildirimDurumu.mudahaleEdildi:
        return BitmapDescriptor.hueCyan;
      case BildirimDurumu.kapatildi:
        return BitmapDescriptor.hueRed;
    }
  }

  String _durumEtiket(BildirimDurumu durum) {
    switch (durum) {
      case BildirimDurumu.beklemede:
        return 'Beklemede';
      case BildirimDurumu.incelendi:
        return 'İncelendi';
      case BildirimDurumu.gorevAtandi:
        return 'Görev Atandı';
      case BildirimDurumu.mudahaleEdildi:
        return 'Müdahale Edildi';
      case BildirimDurumu.kapatildi:
        return 'Kapatıldı';
    }
  }

  String _riskTipiEtiket(RiskTipi tip) {
    switch (tip) {
      case RiskTipi.kurumus:
        return 'Kurumuş Ağaç';
      case RiskTipi.hastalikli:
        return 'Hastalıklı Ağaç';
      case RiskTipi.devrilmeRiski:
        return 'Devrilme Riski';
      case RiskTipi.budamaIhtiyaci:
        return 'Budama İhtiyacı';
      case RiskTipi.firtinaRiski:
        return 'Fırtına Öncesi Risk';
    }
  }
}