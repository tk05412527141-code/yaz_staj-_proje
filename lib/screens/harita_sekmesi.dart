import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/deprem.dart';
import '../state/deprem_deposu.dart';
import '../utils/buyukluk_stili.dart';
import '../utils/tema.dart';
import 'detay_ekrani.dart';

/// Harita sekmesi: filtrelenmis tum depremler tek haritada.
///
/// Liste sekmesiyle AYNI depoyu kullanir; yani listede uyguladigin filtre
/// haritaya da yansir. Kullanici iki ekran arasinda tutarsizlik gormez.
class HaritaSekmesi extends StatefulWidget {
  final DepremDeposu depo;

  const HaritaSekmesi({super.key, required this.depo});

  @override
  State<HaritaSekmesi> createState() => _HaritaSekmesiState();
}

class _HaritaSekmesiState extends State<HaritaSekmesi> {
  final _haritaKontrolcu = MapController();

  // Turkiye'nin yaklasik merkezi
  static const _merkez = LatLng(39.0, 35.2);
  static const _baslangicYakinlik = 5.2;

  Deprem? _secili;

  @override
  void dispose() {
    // Kontrolcu birakilmazsa bellek sizintisi olur.
    _haritaKontrolcu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.depo,
      builder: (context, _) {
        final liste = widget.depo.liste;

        return Stack(
          children: [
            FlutterMap(
              mapController: _haritaKontrolcu,
              options: MapOptions(
                initialCenter: _merkez,
                initialZoom: _baslangicYakinlik,
                // Haritaya bos bir yere dokununca secimi kaldir
                onTap: (_, __) => setState(() => _secili = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tunakilic.deprem_takip',
                ),
                MarkerLayer(markers: _isaretciler(liste)),
              ],
            ),

            // Ust bilgi serdi
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _bilgiKapsulu(
                      '${liste.length} deprem · ${widget.depo.kaynak.ad}',
                    ),
                    const Spacer(),
                    _yuvarlakButon(
                      Icons.my_location,
                      'Türkiye görünümüne dön',
                      () => _haritaKontrolcu.move(_merkez, _baslangicYakinlik),
                    ),
                  ],
                ),
              ),
            ),

            // Lejant
            Positioned(left: 12, bottom: 12, child: _lejant()),

            // Secili depremin alt karti
            if (_secili != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _seciliKart(_secili!),
              ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------------

  List<Marker> _isaretciler(List<Deprem> liste) {
    return liste.map((d) {
      final boyut = BuyuklukStili.isaretciBoyutu(d.buyukluk);
      final renk = BuyuklukStili.renk(d.buyukluk);
      final seciliMi = _secili?.id == d.id && d.id.isNotEmpty;

      return Marker(
        point: LatLng(d.enlem, d.boylam),
        width: boyut,
        height: boyut,
        child: GestureDetector(
          onTap: () => setState(() => _secili = d),
          child: Container(
            decoration: BoxDecoration(
              color: renk.withValues(alpha: seciliMi ? 0.95 : 0.62),
              shape: BoxShape.circle,
              border: Border.all(
                color: seciliMi ? Colors.white : Colors.white70,
                width: seciliMi ? 3 : 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: boyut >= 30
                ? Text(
                    d.buyukluk.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
        ),
      );
    }).toList();
  }

  Widget _bilgiKapsulu(String yazi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Renkler.yuzey.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Renkler.kenarlik),
      ),
      child: Text(
        yazi,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Renkler.metin,
        ),
      ),
    );
  }

  Widget _yuvarlakButon(IconData ikon, String ipucu, VoidCallback onTap) {
    return Material(
      color: Renkler.yuzey.withValues(alpha: 0.94),
      shape: const CircleBorder(
        side: BorderSide(color: Renkler.kenarlik),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: ipucu,
        onPressed: onTap,
        icon: Icon(ikon, size: 20, color: Renkler.metin),
      ),
    );
  }

  Widget _lejant() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Renkler.yuzey.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Renkler.kenarlik),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'BÜYÜKLÜK',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Renkler.metinSolgun,
            ),
          ),
          const SizedBox(height: 7),
          _lejantSatiri('< 3', 2.0),
          _lejantSatiri('3 – 4', 3.5),
          _lejantSatiri('4 – 5', 4.5),
          _lejantSatiri('5 +', 5.5),
        ],
      ),
    );
  }

  Widget _lejantSatiri(String yazi, double ornek) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: BuyuklukStili.renk(ornek),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            yazi,
            style: const TextStyle(fontSize: 11, color: Renkler.metin),
          ),
        ],
      ),
    );
  }

  /// Haritada bir isaretciye dokununca alttan cikan ozet kart.
  Widget _seciliKart(Deprem d) {
    final renk = BuyuklukStili.renk(d.buyukluk);

    return Material(
      color: Renkler.yuzey,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetayEkrani(deprem: d, depo: widget.depo),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Renkler.kenarlik),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BuyuklukStili.zeminTonu(d.buyukluk),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: renk.withValues(alpha: 0.45)),
                ),
                alignment: Alignment.center,
                child: Text(
                  d.buyukluk.toStringAsFixed(1),
                  style: TextStyle(
                    color: renk,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.yer,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Renkler.metin,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${d.gecenSure} · ${d.derinlik.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Renkler.metinSolgun,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Renkler.metinSolgun),
            ],
          ),
        ),
      ),
    );
  }
}
