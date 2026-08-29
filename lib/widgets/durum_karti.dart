import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../state/deprem_deposu.dart';
import '../utils/cam_tema.dart';
import '../utils/siddet_hesabi.dart';
import '../utils/tema.dart';

/// Listenin en ustundeki kisisel ozet karti.
///
/// NEDEN VAR?
///   Insanin bu uygulamayi acma sebebi tek bir soru: "son 24 saatte
///   benim yerlerimde bir sey oldu mu?" Cevabi bulmak icin 200 kartlik
///   listeyi taramasi gerekmemeli. Cevap en ustte olmali.
///
/// Uc durum gosteriyor:
///   - Hic yer eklenmemis  -> ekleme cagrisi
///   - Yer var, sarsinti yok -> sakinlestirici "her sey normal"
///   - Yer var, sarsinti var -> en guclusunun ozeti
class DurumKarti extends StatelessWidget {
  final DepremDeposu depo;
  final VoidCallback onYerEkle;
  final VoidCallback onDetay;

  const DurumKarti({
    super.key,
    required this.depo,
    required this.onYerEkle,
    required this.onDetay,
  });

  @override
  Widget build(BuildContext context) {
    if (depo.konumlar.isEmpty) return _yerEkleCagrisi(context);

    final ozet = _sonGunOzeti();

    if (ozet == null) return _sakinDurum(context);
    return _sarsintiDurumu(context, ozet);
  }

  // ------------------------------------------------------------------

  /// Son 24 saatte kayitli yerlerde hissedilen en guclu deprem.
  ({String konumAdi, String yer, SiddetSonucu sonuc})? _sonGunOzeti() {
    final sinir = DateTime.now().subtract(const Duration(hours: 24));

    ({String konumAdi, String yer, SiddetSonucu sonuc})? enGuclu;

    for (final d in depo.liste) {
      if (d.tarih.isBefore(sinir)) continue;

      final etki = depo.enYakinEtki(d);
      if (etki == null || !etki.sonuc.seviye.hissedilir) continue;

      if (enGuclu == null || etki.sonuc.mmi > enGuclu.sonuc.mmi) {
        enGuclu = (
          konumAdi: etki.konum.ad,
          yer: d.yer,
          sonuc: etki.sonuc,
        );
      }
    }
    return enGuclu;
  }

  // ------------------------------------------------------------------
  // Uc durum
  // ------------------------------------------------------------------

  Widget _yerEkleCagrisi(BuildContext context) {
    return _kabuk(
      renk: Renkler.vurgu,
      semantikEtiket: 'Henüz yer eklemediniz. Yer eklemek için dokunun.',
      onTap: onYerEkle,
      child: Row(
        children: [
          _ikonKutusu(Icons.add_location_alt_outlined, Renkler.vurgu),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yerinizi ekleyin',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Renkler.metin,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Depremlerin evinizde ne kadar hissedileceğini görün',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Renkler.metinSolgun,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Renkler.metinSolgun),
        ],
      ),
    );
  }

  Widget _sakinDurum(BuildContext context) {
    final yerSayisi = depo.konumlar.length;
    final yerMetni =
        yerSayisi == 1 ? depo.konumlar.first.ad : '$yerSayisi yerinizde';

    return _kabuk(
      renk: Renkler.canli,
      semantikEtiket:
          'Son 24 saatte $yerMetni hissedilen deprem yok. Detay için dokunun.',
      onTap: onDetay,
      child: Row(
        children: [
          _ikonKutusu(Icons.check_circle_outline, Renkler.canli),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  yerSayisi == 1 ? '$yerMetni sakin' : 'Yerleriniz sakin',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Renkler.metin,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Son 24 saatte hissedilmesi beklenen deprem yok',
                  style: TextStyle(
                    fontSize: 12.5,
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

  Widget _sarsintiDurumu(
    BuildContext context,
    ({String konumAdi, String yer, SiddetSonucu sonuc}) ozet,
  ) {
    final renk = ozet.sonuc.seviye.renk;

    return _kabuk(
      renk: renk,
      semantikEtiket: 'Son 24 saatte ${ozet.konumAdi} konumunda '
          '${ozet.sonuc.seviye.etiket} seviyesinde sarsıntı bekleniyordu. '
          'Merkez üssü ${ozet.yer}. Detay için dokunun.',
      onTap: onDetay,
      child: Row(
        children: [
          _ikonKutusu(Icons.vibration, renk),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ozet.konumAdi}: ${ozet.sonuc.seviye.etiket.toLowerCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: renk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Son 24 saat · ${ozet.yer} · ${ozet.sonuc.mesafeMetni}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Renkler.metinSolgun,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Renkler.metinSolgun),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _kabuk({
    required Color renk,
    required Widget child,
    required String semantikEtiket,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semantikEtiket,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          // Listenin odak yuzeyi: tek kart oldugu icin gercek cam
          // (standard) kullaniyoruz. Cam, durumun rengiyle tonlaniyor -
          // sakinken yesil, sarsinti varken siddet rengi. Boylece
          // "her sey normal mi?" sorusu renkten bile anlasiliyor.
          child: GlassCard(
            quality: GlassQuality.standard,
            settings: CamAyar.tonlu(renk, yogunluk: 0.14),
            useOwnLayer: true,
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: LiquidRoundedSuperellipse(
              borderRadius: 20,
              side: BorderSide(color: renk.withValues(alpha: 0.35)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ikonKutusu(IconData ikon, Color renk) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(ikon, size: 22, color: renk),
    );
  }
}
