import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/acil_durum_servisi.dart';
import '../services/bulten_uretici.dart';
import '../state/deprem_deposu.dart';
import '../utils/buyukluk_stili.dart';
import '../utils/sehirler.dart';
import '../utils/tema.dart';
import '../widgets/durum_gorunumu.dart';
import '../widgets/iskelet_kart.dart';
import 'detay_ekrani.dart';

/// Onemli depremler icin resmi verilerden uretilmis bilgi bultenleri.
///
/// NEDEN "HABER" DEGIL "DUYURU"?
///   AFAD ve Kandilli'nin makine-okunabilir bir basin aciklamasi
///   beslemesi yok. Haber sitelerinden cekmek ise iki sorun getiriyordu:
///   telif/kullanim kosullari ve daha onemlisi, Turkiye'deki "deprem"
///   etiketli haberlerin ciddi bir kisminin TAHMIN iddiasi tasimasi.
///
///   Uygulamanin baska bir ekraninda tahminin bilimsel olarak mumkun
///   olmadigini anlatiyoruz; filtresiz haber akitmak bununla celisirdi.
///
///   Bu yuzden duyurular, zaten kullandigimiz resmi veriden uretiliyor.
class DuyurularSekmesi extends StatelessWidget {
  final DepremDeposu depo;

  const DuyurularSekmesi({super.key, required this.depo});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: depo,
      builder: (context, _) {
        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              _baslik(),
              Expanded(child: _icerik(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _baslik() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Duyurular',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Renkler.metin,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${BultenUretici.esikBuyukluk.toStringAsFixed(1)} ve üzeri '
            'depremler için ${depo.kaynak.ad} verisinden üretilen bültenler',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Renkler.metinSolgun,
            ),
          ),
        ],
      ),
    );
  }

  Widget _icerik(BuildContext context) {
    if (depo.yukleniyor) return const IskeletListe(adet: 4);

    if (depo.hata != null) {
      return DurumGorunumu(
        ikon: Icons.cloud_off_rounded,
        ikonRengi: const Color(0xFFF85149),
        baslik: 'Veriye ulaşılamadı',
        aciklama: depo.hata!,
        eylemYazisi: 'Tekrar dene',
        onEylem: depo.yenile,
      );
    }

    final bultenler = depo.bultenler;

    if (bultenler.isEmpty) {
      return DurumGorunumu(
        ikon: Icons.inbox_outlined,
        ikonRengi: Renkler.canli,
        baslik: 'Bülten yok',
        aciklama: 'Seçili zaman aralığında '
            '${BultenUretici.esikBuyukluk.toStringAsFixed(1)} ve üzeri '
            'deprem kaydı bulunmuyor. Bu iyi haber.\n\n'
            'Daha geniş bir aralık için Liste sekmesindeki filtreleri '
            'kullanabilirsin.',
        eylemYazisi: 'Yenile',
        onEylem: depo.yenile,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await depo.yenile();
      },
      color: Renkler.vurgu,
      backgroundColor: Renkler.yuzey,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: bultenler.length + 1,
        itemBuilder: (context, i) {
          if (i == bultenler.length) return _kaynakNotu();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _bultenKarti(context, bultenler[i]),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _bultenKarti(BuildContext context, Bulten b) {
    final d = b.deprem;
    final renk = BuyuklukStili.renk(d.buyukluk);
    final etki = b.enCokEtkilenen;

    return Material(
      color: Renkler.yuzey,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetayEkrani(deprem: d, depo: depo),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: b.onemli
                  ? renk.withValues(alpha: 0.5)
                  : Renkler.kenarlik,
              width: b.onemli ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ust: buyukluk + konum
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: BuyuklukStili.zeminTonu(d.buyukluk),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: renk.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        d.buyukluk.toStringAsFixed(1),
                        style: TextStyle(
                          color: renk,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
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
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Renkler.metin,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d.tarihMetni} · ${d.gecenSure}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Renkler.metinSolgun,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Resmi parametreler
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _olcu('Derinlik', '${d.derinlik.toStringAsFixed(1)} km'),
                    _olcu('Koordinat', d.koordinatMetni),
                    _olcu('Kaynak', d.kaynak),
                  ],
                ),
              ),

              // Artci ozeti
              if (b.artciSayisi > 0) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Row(
                    children: [
                      Icon(
                        b.egilim == ArtciEgilimi.azaliyor
                            ? Icons.trending_down
                            : Icons.show_chart,
                        size: 17,
                        color: b.egilim == ArtciEgilimi.azaliyor
                            ? Renkler.canli
                            : const Color(0xFFE3B341),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yaklaşık ${b.artciSayisi} artçı · '
                              'en büyüğü '
                              '${b.enBuyukArtci.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Renkler.metin,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b.egilim.etiket,
                              style: TextStyle(
                                fontSize: 12,
                                color: b.egilim == ArtciEgilimi.azaliyor
                                    ? Renkler.canli
                                    : Renkler.metinSolgun,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Kullanicinin yerlerindeki etki
              if (etki != null) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Row(
                    children: [
                      Icon(
                        KonumSimgesi.ikon(etki.konum.simge),
                        size: 16,
                        color: etki.sonuc.seviye.renk,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${etki.konum.ad} · ${etki.sonuc.mesafeMetni}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Renkler.metinSolgun,
                          ),
                        ),
                      ),
                      Text(
                        etki.sonuc.seviye.etiket,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: etki.sonuc.seviye.renk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Paylas
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: TextButton.icon(
                    onPressed: () => _bulteniKopyala(context, b),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Bülteni kopyala'),
                    style: TextButton.styleFrom(
                      foregroundColor: Renkler.metinSolgun,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _olcu(String etiket, String deger) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiket.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: Renkler.metinSolgun,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          deger,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Renkler.metin,
          ),
        ),
      ],
    );
  }

  Widget _kaynakNotu() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Renkler.yuzeyUst,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 17, color: Renkler.metinSolgun),
              SizedBox(width: 9),
              Text(
                'Bu bültenler nasıl üretiliyor?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Renkler.metin,
                ),
              ),
            ],
          ),
          SizedBox(height: 9),
          Text(
            'Deprem parametreleri AFAD ve Kandilli\'nin resmî verilerinden '
            'doğrudan alınır. Artçı sayımı ve hissedilirlik tahmini bu '
            'veriden uygulama içinde hesaplanır — yaklaşık değerlerdir.\n\n'
            'Bunlar kurumların basın açıklaması değildir. Resmî '
            'açıklamalar için AFAD ve Kandilli Rasathanesi\'nin kendi '
            'kaynaklarını takip edin.',
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              color: Renkler.metinSolgun,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulteniKopyala(BuildContext context, Bulten b) async {
    HapticFeedback.selectionClick();
    final oldu = await AcilDurumServisi.panoyaKopyala(
      BultenUretici.metneCevir(b),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(oldu ? 'Bülten panoya kopyalandı' : 'Kopyalanamadı'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
