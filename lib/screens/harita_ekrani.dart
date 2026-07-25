import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/deprem.dart';
import '../utils/buyukluk_stili.dart';
import 'detay_ekrani.dart';

/// Filtrelenmis tum depremleri tek bir harita uzerinde gosterir.
///
/// Isaretcinin boyutu ve rengi depremin buyuklugune gore degisir;
/// boylece haritaya bakinca nerede ne oldugu bir bakista anlasilir.
class HaritaEkrani extends StatelessWidget {
  final List<Deprem> depremler;

  const HaritaEkrani({super.key, required this.depremler});

  @override
  Widget build(BuildContext context) {
    // Turkiye'nin yaklasik merkezi
    const merkez = LatLng(39.0, 35.2);

    return Scaffold(
      appBar: AppBar(
        title: Text('Harita (${depremler.length} deprem)'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: merkez,
              initialZoom: 5.2,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.deprem_takip',
              ),
              MarkerLayer(
                markers: depremler.map((d) {
                  final boyut = BuyuklukStili.isaretciBoyutu(d.buyukluk);
                  return Marker(
                    point: LatLng(d.enlem, d.boylam),
                    width: boyut,
                    height: boyut,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetayEkrani(deprem: d),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: BuyuklukStili.renk(d.buyukluk)
                              .withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: boyut >= 30
                            ? Text(
                                d.buyukluk.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Renk aciklamasi (lejant)
          Positioned(
            left: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Buyukluk',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    _lejantSatiri('< 3', 2.0),
                    _lejantSatiri('3 - 4', 3.5),
                    _lejantSatiri('4 - 5', 4.5),
                    _lejantSatiri('5+', 5.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lejantSatiri(String yazi, double ornekBuyukluk) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: BuyuklukStili.renk(ornekBuyukluk),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(yazi, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
