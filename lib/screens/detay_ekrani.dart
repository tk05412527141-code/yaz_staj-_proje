import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/deprem.dart';
import '../state/deprem_deposu.dart';
import '../widgets/deprem_karti.dart';
import '../utils/buyukluk_stili.dart';
import '../utils/cam_tema.dart';
import '../utils/sehirler.dart';
import '../utils/siddet_hesabi.dart';
import '../utils/tema.dart';

/// Tek bir depremin tum ayrintilarini gosteren ekran.
class DetayEkrani extends StatelessWidget {
  final Deprem deprem;

  /// Kayitli yerlerdeki tahmini etkiyi hesaplamak icin.
  /// Verilmezse "Yerlerinizde" bolumu gosterilmez.
  final DepremDeposu? depo;

  const DetayEkrani({super.key, required this.deprem, this.depo});

  @override
  Widget build(BuildContext context) {
    final renk = BuyuklukStili.renk(deprem.buyukluk);
    final konum = LatLng(deprem.enlem, deprem.boylam);

    // Zemin, depremin buyukluk rengiyle isiklandiriliyor: ekrana
    // girer girmez sarsintinin siddeti renkten hissediliyor.
    // Cam ust cubuk bu zeminin uzerinde yuzuyor, icerik altindan
    // bulaniklasarak geciyor.
    return GlassScaffold(
      background: CamZemin(vurguRengi: renk),
      statusBarStyle: GlassStatusBarStyle.light,
      settings: CamAyar.panel,
      appBar: camCubuk(GlassAppBar(
        leading: Semantics(
          button: true,
          label: 'Geri',
          child: ExcludeSemantics(
            child: GlassIconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 17, color: Renkler.metin),
              size: 40,
              settings: CamAyar.kontrol,
              useOwnLayer: true,
              glowColor: renk,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
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
        actions: [
          Semantics(
            button: true,
            label: 'Paylaş',
            child: ExcludeSemantics(
              child: GlassIconButton(
                icon:
                    const Icon(Icons.ios_share, size: 19, color: Renkler.metin),
                size: 40,
                settings: CamAyar.kontrol,
                useOwnLayer: true,
                glowColor: renk,
                onPressed: () => _paylasimSayfasi(context),
              ),
            ),
          ),
        ],
      )),
      body: CamGovde(
        child: CustomScrollView(
          slivers: [
            // Cam cubuk icerigin UZERINDE duruyor; bant onun altindan
            // baslasin diye cubuk yuksekligi kadar bosluk biraktik.
            SliverToBoxAdapter(
              child: SizedBox(height: CamOlculer.ustBosluk(context)),
            ),
            SliverToBoxAdapter(child: _ustBant(renk)),

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

                    _yerlerinizdeBolumu(),

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
                      style:
                          TextStyle(fontSize: 11, color: Renkler.metinSolgun),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _ustBant(Color renk) {
    return Container(
      height: 168,
      // Alt uc seffaf: bandin altindaki zemin gradyani kesintisiz
      // devam etsin, camin kiracagi yuzey bozulmasin.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            renk.withValues(alpha: 0.32),
            renk.withValues(alpha: 0),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Listedeki rozetten buyuyerek gelen sayi (Hero gecisi)
            Hero(
              tag: DepremKarti.heroEtiketi(deprem),
              flightShuttleBuilder: (_, __, ___, ____, _____) => Material(
                type: MaterialType.transparency,
                child: _buyukSayi(renk),
              ),
              child: _buyukSayi(renk),
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
          ],
        ),
      ),
    );
  }

  /// Ust banttaki buyuk buyukluk sayisi. Hero'nun her iki ucunda da
  /// ayni widget kullaniliyor ki gecis puruzsuz olsun.
  Widget _buyukSayi(Color renk) {
    return Text(
      deprem.buyukluk.toStringAsFixed(1),
      style: TextStyle(
        fontSize: 62,
        fontWeight: FontWeight.w900,
        color: renk,
        height: 1.0,
        letterSpacing: -2,
      ),
    );
  }

  Widget _olcuKutusu(String etiket, String deger, String altYazi, Color renk) {
    // Olcu kutulari sabit ve kaydirilmiyor: burada premium cam
    // kullanmak guvenli ve en zengin gorunumu veriyor.
    return GlassCard(
      quality: GlassQuality.standard,
      settings: CamAyar.tonlu(renk, yogunluk: 0.10),
      useOwnLayer: true,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      shape: const LiquidRoundedSuperellipse(borderRadius: 18),
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

  /// Kullanicinin kayitli yerlerindeki tahmini etki dokumu.
  ///
  /// Uygulamanin en degerli bolumu: "4.1" sayisi kimseye bir sey ifade
  /// etmiyor, ama "Evinizde hafif hissedilir" ediyor.
  Widget _yerlerinizdeBolumu() {
    final d = depo;
    if (d == null || d.konumlar.isEmpty) return const SizedBox.shrink();

    // En cok etkilenenden en aza dogru sirala
    final satirlar = d.konumlar
        .map((k) => (konum: k, sonuc: d.siddet(deprem, k)))
        .toList()
      ..sort((a, b) => b.sonuc.mmi.compareTo(a.sonuc.mmi));

    final belirsizVar = satirlar.any((s) => !s.sonuc.guvenilir);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'YERLERİNİZDE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Renkler.metinSolgun,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: const LiquidRoundedSuperellipse(borderRadius: 20),
          child: Column(
            children: [
              for (var i = 0; i < satirlar.length; i++) ...[
                if (i > 0) const GlassDivider(),
                _yerSatiri(satirlar[i].konum.ad, satirlar[i].konum.simge,
                    satirlar[i].sonuc),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            belirsizVar
                ? 'Tahminler Allen ve ark. (2012) şiddet azalım modeline '
                    'dayanır. Bu deprem modelin geçerlilik aralığının '
                    '(M5.0+, 300 km) dışında kaldığı için tahmin belirsizdir. '
                    'Gerçek sarsıntı zemin ve bina yapısına göre değişir.'
                : 'Tahminler Allen ve ark. (2012) şiddet azalım modeline '
                    'dayanır. Gerçek sarsıntı zemin yapısı, bina türü ve kat '
                    'yüksekliğine göre değişir. Resmî bir şiddet değeri değildir.',
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: Renkler.metinSolgun,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _yerSatiri(String ad, String simge, SiddetSonucu s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: s.seviye.renk.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(KonumSimgesi.ikon(simge), size: 18, color: s.seviye.renk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Renkler.metin,
                        ),
                      ),
                    ),
                    Text(
                      s.mesafeMetni,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Renkler.metinSolgun,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      s.seviye.etiket,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: s.seviye.renk,
                      ),
                    ),
                    if (!s.guvenilir) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '(tahmini)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Renkler.metinSolgun,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  s.seviye.aciklama,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Renkler.metinSolgun,
                  ),
                ),
              ],
            ),
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
    return GlassCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const LiquidRoundedSuperellipse(borderRadius: 20),
      child: Column(
        children: [
          _satir(Icons.place_outlined, 'Konum', deprem.yer),
          const GlassDivider(),
          _satir(Icons.schedule, 'Tarih ve saat',
              '${deprem.tarihMetni}  ·  ${deprem.gecenSure}'),
          const GlassDivider(),
          _satir(Icons.my_location, 'Koordinatlar', deprem.koordinatMetni),
          const GlassDivider(),
          _satir(Icons.verified_outlined, 'Veri kaynağı', deprem.kaynak),
          if (deprem.id.isNotEmpty) ...[
            const GlassDivider(),
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
    return GlassButton.custom(
      onTap: onTap,
      label: yazi,
      height: 78,
      settings: CamAyar.kontrol,
      useOwnLayer: true,
      shape: const LiquidRoundedSuperellipse(borderRadius: 18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
    GlassSheet.show<void>(
      context: context,
      settings: CamAyar.panel,
      dragIndicatorColor: Renkler.metinSolgun,
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
            GlassListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Tüm bilgileri kopyala'),
              subtitle:
                  const Text('Konum, büyüklük, derinlik, tarih, bağlantı'),
              leadingIconColor: Renkler.vurgu,
              onTap: () {
                Navigator.of(sayfaContext).pop();
                _kopyala(context, deprem.paylasimMetni,
                    'Deprem bilgisi panoya kopyalandı');
              },
            ),
            GlassListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Koordinatları kopyala'),
              subtitle: Text(deprem.koordinatMetni),
              leadingIconColor: Renkler.vurgu,
              onTap: () {
                Navigator.of(sayfaContext).pop();
                _kopyala(context, deprem.koordinatMetni,
                    'Koordinatlar panoya kopyalandı');
              },
            ),
            GlassListTile(
              leading: const Icon(Icons.link),
              title: const Text('Harita bağlantısını kopyala'),
              subtitle: const Text('Tarayıcıda açılabilir konum bağlantısı'),
              leadingIconColor: Renkler.vurgu,
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
