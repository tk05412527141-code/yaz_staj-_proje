import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/deprem.dart';
import '../models/kayitli_konum.dart';
import '../utils/buyukluk_stili.dart';
import '../utils/sehirler.dart';
import '../utils/siddet_hesabi.dart';
import '../utils/tema.dart';

/// Listede tek bir depremi gosteren kart.
///
/// Tasarim mantigi: goz once BUYUKLUGE takilsin (sol taraftaki renkli
/// rozet), sonra konuma, en son detaylara. Bilgi hiyerarsisi bu sirada.
///
/// Kullanici bir yer kaydettiyse en altta "Evinizden 340 km · hissedilmez"
/// satiri cikiyor. Asil deger burada: ham buyukluk degil, kisisel etki.
///
/// ERISILEBILIRLIK
///   - Buyukluk yalnizca renkle degil, SAYIYLA da gosteriliyor; renk
///     korlugu olan kullanici bilgiyi kaybetmiyor.
///   - Tum kart tek bir Semantics dugumu; ekran okuyucu parca parca
///     degil, anlamli bir cumle okuyor.
///   - Rozet icindeki sayi FittedBox icinde; buyuk yazi tipi ayarinda
///     tasma olmuyor.
class DepremKarti extends StatelessWidget {
  final Deprem deprem;
  final VoidCallback onTap;

  /// Kullanicinin en cok etkilenen yeri ve oradaki tahmini siddet.
  /// Kayitli yer yoksa null.
  final ({KayitliKonum konum, SiddetSonucu sonuc})? etki;

  const DepremKarti({
    super.key,
    required this.deprem,
    required this.onTap,
    this.etki,
  });

  /// Detay ekranindaki buyuk sayiyla eslesen Hero etiketi.
  static String heroEtiketi(Deprem d) =>
      'buyukluk-${d.kaynak}-${d.id}-${d.tarih.millisecondsSinceEpoch}';

  /// Ekran okuyucunun okuyacagi tek cumle.
  String _semantikEtiket() {
    final parcalar = <String>[
      'Büyüklük ${deprem.buyukluk.toStringAsFixed(1)}',
      BuyuklukStili.etiket(deprem.buyukluk),
      deprem.yer,
      deprem.gecenSure,
      'derinlik ${deprem.derinlik.toStringAsFixed(0)} kilometre',
    ];
    final e = etki;
    if (e != null) {
      parcalar.add(
        '${e.konum.ad} konumundan ${e.sonuc.mesafeMetni} uzaklıkta, '
        '${e.sonuc.seviye.etiket}',
      );
    }
    return parcalar.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final renk = BuyuklukStili.renk(deprem.buyukluk);

    return Semantics(
      button: true,
      label: _semantikEtiket(),
      onTapHint: 'detayları aç',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          // GlassQuality.minimal: liste kaydirilirken her kart icin
          // shader calistirmaz (BackdropFilter + doygunluk matrisi).
          // 50+ kartlik bir listede premium cam kullanmak kareleri
          // dusururdu; minimal ayni buzlu cam gorunumunu bedava verir.
          child: GlassCard(
            quality: GlassQuality.minimal,
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: const LiquidRoundedSuperellipse(borderRadius: 18),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Sol kenardaki renkli serit - listeyi hizli taramayi
                      // saglar. Cam uzerinde tam doygun kaliyor ki buyukluk
                      // sinifi bir bakista okunabilsin.
                      Container(width: 4, color: renk),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buyuklukRozeti(renk),
                                  const SizedBox(width: 14),
                                  Expanded(child: _bilgiSutunu(context)),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: Renkler.metinSolgun,
                                  ),
                                ],
                              ),
                              if (etki != null) _etkiSatiri(etki!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buyuklukRozeti(Color renk) {
    return Hero(
      tag: heroEtiketi(deprem),
      // Ucus sirasinda Material olmayan bir agacta metin altini cizili
      // gorunebilir; bunu engellemek icin saydam Material sariyoruz.
      flightShuttleBuilder: (_, __, ___, ____, _____) => Material(
        type: MaterialType.transparency,
        child: _rozetIcerigi(renk),
      ),
      child: _rozetIcerigi(renk),
    );
  }

  Widget _rozetIcerigi(Color renk) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: BuyuklukStili.zeminTonu(deprem.buyukluk),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // FittedBox: cihazda yazi boyutu buyutulmusse tasma olmaz
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                deprem.buyukluk.toStringAsFixed(1),
                style: TextStyle(
                  color: renk,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'M',
            style: TextStyle(
              color: renk.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// "Evinizden 340 km · Hissedilmez" satiri.
  Widget _etkiSatiri(({KayitliKonum konum, SiddetSonucu sonuc}) e) {
    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: e.sonuc.seviye.renk.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              KonumSimgesi.ikon(e.konum.simge),
              size: 14,
              color: e.sonuc.seviye.renk,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '${e.konum.ad} · ${e.sonuc.mesafeMetni}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Renkler.metinSolgun,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                e.sonuc.seviye.etiket,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: e.sonuc.seviye.renk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bilgiSutunu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          deprem.yer,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Renkler.metin,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        // Wrap: buyuk yazi tipinde alt alta gecer, tasma olmaz
        Wrap(
          spacing: 12,
          runSpacing: 3,
          children: [
            _kucukBilgi(Icons.schedule, deprem.gecenSure),
            _kucukBilgi(
              Icons.arrow_downward,
              '${deprem.derinlik.toStringAsFixed(1)} km',
            ),
          ],
        ),
      ],
    );
  }

  Widget _kucukBilgi(IconData ikon, String yazi) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 13, color: Renkler.metinSolgun),
        const SizedBox(width: 4),
        Text(
          yazi,
          style: const TextStyle(fontSize: 12.5, color: Renkler.metinSolgun),
        ),
      ],
    );
  }
}
