import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/deprem_servisi.dart';
import '../state/deprem_deposu.dart';
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
  static Future<void> ac(BuildContext context, DepremDeposu depo) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
                  children: VeriKaynagi.values.map((k) {
                    return ChoiceChip(
                      label: Text(k.ad),
                      selected: depo.kaynak == k,
                      onSelected: (s) {
                        if (!s) return;
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
                    return ChoiceChip(
                      label: Text(gun == 1 ? 'Son 24 saat' : 'Son $gun gün'),
                      selected: depo.gunSayisi == gun,
                      onSelected: (s) {
                        if (!s) return;
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
                        color: Renkler.yuzeyUst,
                        borderRadius: BorderRadius.circular(8),
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
                Slider(
                  value: depo.minBuyukluk,
                  min: 0,
                  max: 6,
                  divisions: 12,
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
                Wrap(
                  spacing: 8,
                  children: Siralama.values.map((s) {
                    return ChoiceChip(
                      label: Text(s.etiket),
                      selected: depo.siralama == s,
                      onSelected: (secildi) {
                        if (!secildi) return;
                        HapticFeedback.selectionClick();
                        depo.siralamaDegistir(s);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('${depo.liste.length} sonucu göster'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
