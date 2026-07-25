import 'package:flutter/material.dart';

import '../models/deprem.dart';
import '../utils/buyukluk_stili.dart';
import '../utils/tema.dart';

/// Listede tek bir depremi gosteren kart.
///
/// Tasarim mantigi: goz once BUYUKLUGE takilsin (sol taraftaki renkli
/// rozet), sonra konuma, en son detaylara. Bilgi hiyerarsisi bu sirada.
class DepremKarti extends StatelessWidget {
  final Deprem deprem;
  final VoidCallback onTap;

  const DepremKarti({
    super.key,
    required this.deprem,
    required this.onTap,
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
                      child: Row(
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
