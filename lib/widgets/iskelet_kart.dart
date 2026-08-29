import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../utils/tema.dart';

/// Veri yuklenirken gosterilen "iskelet" kartlar.
///
/// Neden donen bir cark yerine bu?
///   Iskelet ekranlar, kullaniciya birazdan ne gelecegini gosterdigi icin
///   bekleme suresini daha kisa hissettirir. Ayrica ekran birden bire
///   doldugunda olusan sicrama etkisini azaltir.
///
/// Parildama efekti icin ek paket kullanilmadi; basit bir
/// AnimationController + kayan gradyan yeterli.
class IskeletListe extends StatelessWidget {
  final int adet;

  const IskeletListe({super.key, this.adet = 7});

  @override
  Widget build(BuildContext context) {
    // ExcludeSemantics: bu kartlar bos yer tutuculardir, icerikleri yoktur.
    // Ekran okuyucu bunlari okumaya calisirsa kullanici anlamsiz bir
    // listeyle karsilasir. Yukleme durumunu tek bir etiketle bildiriyoruz.
    return Semantics(
      liveRegion: true,
      label: 'Depremler yükleniyor',
      child: ExcludeSemantics(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          itemCount: adet,
          itemBuilder: (_, __) => const _IskeletKart(),
        ),
      ),
    );
  }
}

class _IskeletKart extends StatefulWidget {
  const _IskeletKart();

  @override
  State<_IskeletKart> createState() => _IskeletKartState();
}

class _IskeletKartState extends State<_IskeletKart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kontrolcu;

  @override
  void initState() {
    super.initState();
    _kontrolcu = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    // Onemli: kontrolcu birakilmazsa bellek sizintisi olur.
    _kontrolcu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // Iskelet kartlar da cam: yuklenme bitince yerine gelecek gercek
      // kartla ayni yuzey dilini konusuyor, gecis sicramiyor.
      child: GlassCard(
        height: 86,
        quality: GlassQuality.minimal,
        shape: const LiquidRoundedSuperellipse(borderRadius: 18),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _parildayan(54, 54, yuvarlaklik: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _parildayan(double.infinity, 13),
                  const SizedBox(height: 9),
                  _parildayan(130, 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _parildayan(double genislik, double yukseklik,
      {double yuvarlaklik = 6}) {
    return AnimatedBuilder(
      animation: _kontrolcu,
      builder: (context, _) {
        // -1 ile 2 arasinda kayan bir deger: gradyani soldan saga suruyor
        final kayma = (_kontrolcu.value * 3) - 1;
        return Container(
          width: genislik,
          height: yukseklik,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(yuvarlaklik),
            gradient: LinearGradient(
              begin: Alignment(kayma - 1, 0),
              end: Alignment(kayma + 1, 0),
              colors: const [
                Renkler.yuzeyUst,
                Color(0xFF2A3543),
                Renkler.yuzeyUst,
              ],
            ),
          ),
        );
      },
    );
  }
}
