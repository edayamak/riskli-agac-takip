import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';

class KonumDuzenleScreen extends StatefulWidget {
  final double baslangicLat;
  final double baslangicLng;

  const KonumDuzenleScreen({
    super.key,
    required this.baslangicLat,
    required this.baslangicLng,
  });

  @override
  State<KonumDuzenleScreen> createState() => _KonumDuzenleScreenState();
}

class _KonumDuzenleScreenState extends State<KonumDuzenleScreen> {
  late LatLng _secilenKonum;

  @override
  void initState() {
    super.initState();
    _secilenKonum = LatLng(widget.baslangicLat, widget.baslangicLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konumu Düzenle')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _secilenKonum, zoom: 17),
            markers: {
              Marker(
                markerId: const MarkerId('secilen_konum'),
                position: _secilenKonum,
                draggable: true,
                onDragEnd: (yeniKonum) {
                  setState(() => _secilenKonum = yeniKonum);
                },
              ),
            },
            onTap: (yeniKonum) {
              setState(() => _secilenKonum = yeniKonum);
            },
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
              ),
              child: const Text(
                'Pini sürükleyerek ya da haritaya dokunarak konumu düzeltebilirsiniz.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _secilenKonum),
            child: const Text('Bu Konumu Kullan'),
          ),
        ),
      ),
    );
  }
}