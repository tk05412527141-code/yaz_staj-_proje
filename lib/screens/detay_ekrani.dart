import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/deprem.dart';
import '../utils/buyukluk_stili.dart';
import '../utils/tema.dart';

/// Tek bir depremin tum ayrintilarini gosteren ekran.
class DetayEkrani extends StatelessWidget {
  final Deprem deprem;

  const DetayEkrani({super.key, required this.deprem});

  @override
  Widget build(BuildContext context) {
    final renk = BuyuklukStili.renk(deprem.buyukluk);
    final konum = LatLng(deprem.enlem, deprem.boylam);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            backgroundColor: Renkler.zemin,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: 'Paylaş',
                icon: const Icon(Icons.ios_share),
                onPressed: () => _paylasimSayfasi(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ustBant(renk),
              titlePadding:
                  const EdgeInsets.only(left: 56, right: 56, bottom: 14),
              title: Text(
                deprem.yer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Renkler.metin,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ust satir: buyukluk / derinlik / zaman ozetleri
                  Row(
                    children: [
                      Expanded(
                        child: _olcuKutusu(
                          'BÜYÜKLÜK',
                          deprem.buyukluk.toStringAsFixed(1),
                          BuyuklukStili.etiket(deprem.buyukluk),
                          renk,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _olcuKutusu(
                          'DERİNLİK',
                          deprem.derinlik.toStringAsFixed(1),
                          'kilometre',
                          Renkler.metin,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _haritaKarti(konum, renk),
                  const SizedBox(height: 16),

                  _detayKarti(context),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _eylemButonu(
                          Icons.copy_all_outlined,
                          'Bilgileri kopyala',
                          () => _kopyala(
                            context,
                            deprem.paylasimMetni,
                            'Deprem bilgisi panoya kopyalandı',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _eylemButonu(
                          Icons.my_location,
                          'Koordinatları kopyala',
                          () => _kopyala(
                            context,
                            deprem.koordinatMetni,
                            'Koordinatlar panoya kopyalandı',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Text(
                    'Harita verileri © OpenStreetMap katkıda bulunanlar.',
                    style: TextStyle(fontSize: 11, color: Renkler.metinSolgun),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _ustBant(Color renk) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            renk.withValues(alpha: 0.35),
            Renkler.zemin,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                deprem.buyukluk.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 62,
                  fontWeight: FontWeight.w900,
                  color: renk,
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                BuyuklukStili.etiket(deprem.buyukluk).toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: renk.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _olcuKutusu(
      String etiket, String deger, String altYazi, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Renkler.yuzey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Renkler.kenarlik),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiket,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: Renkler.metinSolgun,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            deger,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: renk,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            altYazi,
            style: const TextStyle(fontSize: 12, color: Renkler.metinSolgun),
          ),
        ],
      ),
    );
  }

  Widget _haritaKarti(LatLng konum, Color renk) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: konum,
                initialZoom: 8,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tunakilic.deprem_takip',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: konum,
                      width: 46,
                      height: 46,
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
          ],
        ),
      ),
    );
  }

  Widget _detayKarti(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Renkler.yuzey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Renkler.kenarlik),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _satir(Icons.place_outlined, 'Konum', deprem.yer),
          const Divider(),
          _satir(Icons.schedule, 'Tarih ve saat',
              '${deprem.tarihMetni}  ·  ${deprem.gecenSure}'),
          const Divider(),
          _satir(Icons.my_location, 'Koordinatlar', deprem.koordinatMetni),
          const Divider(),
          _satir(Icons.verified_outlined, 'Veri kaynağı', deprem.kaynak),
          if (deprem.id.isNotEmpty) ...[
            const Divider(),
            _satir(Icons.tag, 'Kayıt numarası', deprem.id),
          ],
        ],
      ),
    );
  }

  Widget _satir(IconData ikon, String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 19, color: Renkler.metinSolgun),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Renkler.metinSolgun,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  deger,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Renkler.metin,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eylemButonu(IconData ikon, String yazi, VoidCallback onTap) {
    return Material(
      color: Renkler.yuzeyUst,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Renkler.kenarlik),
          ),
          child: Column(
            children: [
              Icon(ikon, size: 20, color: Renkler.metin),
              const SizedBox(height: 6),
              Text(
                yazi,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Renkler.metin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Paylasim
  // ------------------------------------------------------------------

  /// Alttan acilan paylasim secenekleri.
  ///
  /// Sistem paylasim menusu yerine panoya kopyalama tercih edildi:
  /// ek bir eklenti gerektirmiyor ve her platformda ayni sekilde calisiyor.
  void _paylasimSayfasi(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sayfaContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Paylaş',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Renkler.metin,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Tüm bilgileri kopyala'),
              subtitle: const Text('Konum, büyüklük, derinlik, tarih, bağlantı'),
              onTap: () {
                Navigator.of(sayfaContext).pop();
                _kopyala(context, deprem.paylasimMetni,
                    'Deprem bilgisi panoya kopyalandı');
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Koordinatları kopyala'),
              subtitle: Text(deprem.koordinatMetni),
              onTap: () {
                Navigator.of(sayfaContext).pop();
                _kopyala(context, deprem.koordinatMetni,
                    'Koordinatlar panoya kopyalandı');
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Harita bağlantısını kopyala'),
              subtitle: const Text('Tarayıcıda açılabilir konum bağlantısı'),
              onTap: () {
                Navigator.of(sayfaContext).pop();
                _kopyala(context, deprem.haritaBaglantisi,
                    'Bağlantı panoya kopyalandı');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _kopyala(
      BuildContext context, String metin, String mesaj) async {
    await Clipboard.setData(ClipboardData(text: metin));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
