import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/deprem_servisi.dart';
import '../state/deprem_deposu.dart';
import '../utils/cam_tema.dart';
import '../utils/tema.dart';

/// Alttan acilan ayrintili filtre paneli.
///
/// Sik kullanilan filtreler (hizli filtre seridi) ana ekranda duruyor;
/// daha nadir kullanilanlar buraya alindi. Boylece ana ekran sade kaliyor
/// ama gelismis secenekler de bir dokunus uzakta.
class FiltreSayfasi extends StatelessWidget {
  final DepremDeposu depo;

  const FiltreSayfasi({super.key, required this.depo});

  /// Paneli acar.
  ///
  /// GlassSheet: alttan cam bir levha olarak yukseliyor, arkasindaki
  /// liste bulaniklasarak goruluyor. Kullanici filtreyi degistirirken
  /// altta kac sonuc kaldigini camin arkasindan takip edebiliyor.
  static Future<void> ac(BuildContext context, DepremDeposu depo) {
    return GlassSheet.show<void>(
      context: context,
      settings: CamAyar.panel,
      topBorderRadius: 32,
      dragIndicatorColor: Renkler.metinSolgun,
      builder: (_) => FiltreSayfasi(depo: depo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: depo,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filtreler',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Renkler.metin,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        depo.filtreleriSifirla();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Sıfırla'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                _baslik('Veri kaynağı'),
                _aciklama(
                  'AFAD resmi kurum verisidir ancak zaman zaman gecikmeli '
                  'yayınlanır. Kandilli genelde daha günceldir.',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: VeriKaynagi.values.map((k) {
                    return _cip(
                      etiket: k.ad,
                      secili: depo.kaynak == k,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        depo.kaynakDegistir(k);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),
                _baslik('Zaman aralığı'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [1, 3, 7, 30].map((gun) {
                    return _cip(
                      etiket: gun == 1 ? 'Son 24 saat' : 'Son $gun gün',
                      secili: depo.gunSayisi == gun,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        depo.gunDegistir(gun);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),
                Row(
                  children: [
                    _baslik('Minimum büyüklük'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Renkler.yuzeyUstSaydam,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Renkler.camKenar),
                      ),
                      child: Text(
                        depo.minBuyukluk == 0
                            ? 'Tümü'
                            : depo.minBuyukluk.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Renkler.vurgu,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                GlassSlider(
                  value: depo.minBuyukluk,
                  min: 0,
                  max: 6,
                  divisions: 12,
                  activeColor: Renkler.vurgu,
                  settings: CamAyar.kontrol,
                  useOwnLayer: true,
                  glowColor: Renkler.vurgu,
                  // Surukleneken sadece etiketi guncelle (istek atma),
                  // birakinca veriyi yenile. Aksi halde her piksel
                  // hareketinde API'ye istek gider.
                  onChanged: depo.minBuyuklukOnizle,
                  onChangeEnd: (deger) {
                    HapticFeedback.selectionClick();
                    depo.minBuyuklukDegistir(deger);
                  },
                ),

                const SizedBox(height: 12),
                _baslik('Sıralama'),
                const SizedBox(height: 8),
                // Siralama iki secenekli ve birbirini disliyor: iOS 26'da
                // bunun karsiligi segment kontrolu. Secili segment cam bir
                // hap olarak kayarak geciyor.
                GlassSegmentedControl(
                  segments: Siralama.values
                      .map((s) => GlassSegment(label: s.etiket))
                      .toList(),
                  selectedIndex: Siralama.values.indexOf(depo.siralama),
                  onSegmentSelected: (i) {
                    HapticFeedback.selectionClick();
                    depo.siralamaDegistir(Siralama.values[i]);
                  },
                  settings: CamAyar.kontrol,
                  indicatorColor: Renkler.vurgu.withValues(alpha: 0.35),
                  backgroundColor: Renkler.yuzeyUstSaydam,
                  selectedTextStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Renkler.metin,
                  ),
                  unselectedTextStyle: const TextStyle(
                    fontSize: 13,
                    color: Renkler.metinSolgun,
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton.custom(
                    onTap: () => Navigator.of(context).pop(),
                    label: '${depo.liste.length} sonucu göster',
                    height: 52,
                    style: GlassButtonStyle.prominent,
                    settings: CamAyar.tonlu(Renkler.vurgu, yogunluk: 0.18),
                    useOwnLayer: true,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 18),
                    child: Text(
                      '${depo.liste.length} sonucu göster',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Renkler.metin,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tek secimlik cam cip.
  ///
  /// [ChoiceChip] yerine [GlassChip]: secili olan cam kalinlasip vurgu
  /// rengini aliyor, secili olmayan saydam kaliyor. Renk korlugunde de
  /// ayrilabilsin diye secili cipin yazisi ayrica kalinlasiyor.
  Widget _cip({
    required String etiket,
    required bool secili,
    required VoidCallback onTap,
    IconData? ikon,
  }) {
    return Semantics(
      button: true,
      selected: secili,
      label: '$etiket filtresi',
      child: ExcludeSemantics(
        child: GlassChip(
          label: etiket,
          selected: secili,
          onTap: onTap,
          icon: ikon == null ? null : Icon(ikon, size: 14),
          iconColor: secili ? Renkler.vurgu : Renkler.metinSolgun,
          selectedColor: Renkler.vurgu.withValues(alpha: 0.35),
          settings: CamAyar.kontrol,
          useOwnLayer: true,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
            color: secili ? Renkler.metin : Renkler.metinSolgun,
          ),
        ),
      ),
    );
  }

  Widget _baslik(String yazi) => Text(
        yazi,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Renkler.metin,
        ),
      );

  Widget _aciklama(String yazi) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: Text(
          yazi,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Renkler.metinSolgun,
          ),
        ),
      );
}
