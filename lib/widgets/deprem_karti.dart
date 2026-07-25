import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final renk = BuyuklukStili.renk(deprem.buyukluk);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Renkler.yuzey,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Renkler.kenarlik),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Sol kenardaki renkli serit - listede tarama kolayligi saglar
                  Container(width: 4, color: renk),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
    );
  }

  Widget _buyuklukRozeti(Color renk) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: BuyuklukStili.zeminTonu(deprem.buyukluk),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            deprem.buyukluk.toStringAsFixed(1),
            style: TextStyle(
              color: renk,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.5,
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
            Text(
              e.sonuc.seviye.etiket,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: e.sonuc.seviye.renk,
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
        Row(
          children: [
            const Icon(Icons.schedule, size: 13, color: Renkler.metinSolgun),
            const SizedBox(width: 4),
            Text(
              deprem.gecenSure,
              style: const TextStyle(
                fontSize: 12.5,
                color: Renkler.metinSolgun,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_downward,
                size: 13, color: Renkler.metinSolgun),
            const SizedBox(width: 3),
            Text(
              '${deprem.derinlik.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontSize: 12.5,
                color: Renkler.metinSolgun,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
