import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/deprem.dart';
import '../utils/buyukluk_stili.dart';

/// Tek bir depremin detaylarini ve konumunu haritada gosteren ekran.
class DetayEkrani extends StatelessWidget {
  final Deprem deprem;

  const DetayEkrani({super.key, required this.deprem});

  @override
  Widget build(BuildContext context) {
    final renk = BuyuklukStili.renk(deprem.buyukluk);
    final konum = LatLng(deprem.enlem, deprem.boylam);

    return Scaffold(
      appBar: AppBar(title: const Text('Deprem Detayi')),
      body: ListView(
        children: [
          // Ust bilgi bandi
          Container(
            width: double.infinity,
            color: renk,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Text(
                  deprem.buyukluk.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BuyuklukStili.etiket(deprem.buyukluk),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  deprem.yer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Harita
          SizedBox(
            height: 260,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: konum,
                initialZoom: 8,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.deprem_takip',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: konum,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: renk.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bilgi satirlari
          _bilgi(context, Icons.access_time, 'Tarih / Saat',
              '${deprem.tarihMetni}  (${deprem.gecenSure})'),
          _bilgi(context, Icons.vertical_align_bottom, 'Derinlik',
              '${deprem.derinlik.toStringAsFixed(2)} km'),
          _bilgi(context, Icons.my_location, 'Koordinatlar',
              '${deprem.enlem.toStringAsFixed(4)}, '
              '${deprem.boylam.toStringAsFixed(4)}'),
          _bilgi(context, Icons.verified_outlined, 'Veri kaynagi',
              deprem.kaynak),
          if (deprem.id.isNotEmpty)
            _bilgi(context, Icons.tag, 'Kayit no', deprem.id),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Harita verileri © OpenStreetMap katkida bulunanlar. '
              'Deprem verisi ${deprem.kaynak} kaynaklidir.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _bilgi(
    BuildContext context,
    IconData ikon,
    String baslik,
    String deger,
  ) {
    return ListTile(
      leading: Icon(ikon),
      title: Text(baslik, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        deger,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
