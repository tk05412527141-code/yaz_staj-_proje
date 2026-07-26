import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/haber.dart';
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
            'TRT Haber\'den deprem haberleri · AFAD ve Kandilli '
            'verilerinden üretilen bültenler',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Renkler.metinSolgun,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: depo.duyurularBayatMi
                      ? Renkler.metinSolgun
                      : Renkler.canli,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  // Iki ayri bilgi: ne zaman cektik + veri ne kadar eski
                  '${depo.duyuruGuncellemeMetni}'
                  ' · en yeni kayıt ${depo.bultenVeriYasiMetni} önce',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Renkler.metinSolgun,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _icerik(BuildContext context) {
    // Bultenler ana listeden AYRI cekiliyor, o yuzden kendi
    // yukleme/hata durumunu kullaniyoruz.
    if (depo.bultenYukleniyor) return const IskeletListe(adet: 4);

    if (depo.bultenHatasi != null) {
      return _cekilebilir(DurumGorunumu(
        ikon: Icons.cloud_off_rounded,
        ikonRengi: const Color(0xFFF85149),
        baslik: 'Bültenler alınamadı',
        aciklama: depo.bultenHatasi!,
        eylemYazisi: 'Tekrar dene',
        onEylem: depo.duyurulariYenile,
      ));
    }

    final bultenler = depo.bultenler;

    if (bultenler.isEmpty) {
      return _cekilebilir(DurumGorunumu(
        ikon: Icons.inbox_outlined,
        ikonRengi: Renkler.canli,
        baslik: 'Kayıt bulunamadı',
        aciklama: 'Son ${DepremDeposu.bultenGunSayisi} günde '
            '${BultenUretici.esikBuyukluk.toStringAsFixed(1)} ve üzeri '
            'deprem kaydı alınamadı.',
        eylemYazisi: 'Yenile',
        onEylem: depo.duyurulariYenile,
      ));
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await depo.duyurulariYenile();
      },
      color: Renkler.vurgu,
      backgroundColor: Renkler.yuzey,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: bultenler.length + 3,
        itemBuilder: (context, i) {
          if (i == 0) return _haberBolumu(context);
          if (i == 1) {
            // Esigi gecen deprem yoksa bunu acikca soyle; kullanici
            // siradan bir sarsintiyi "onemli duyuru" sanmamali
            final yedek = bultenler.first.esigiGecti == false;
            if (!yedek) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Renkler.canli.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Renkler.canli.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: Renkler.canli),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Son ${DepremDeposu.bultenGunSayisi} günde '
                        '${BultenUretici.esikBuyukluk.toStringAsFixed(1)} ve '
                        'üzeri deprem olmadı. Aşağıda dönemin en büyükleri '
                        'var.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: Renkler.metin,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (i == bultenler.length + 2) return _kaynakNotu();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _bultenKarti(context, bultenler[i - 2]),
          );
        },
      ),
    );
  }

  /// Bos ve hata ekranlarinin da asagi cekilerek yenilenebilmesi icin.
  ///
  /// Kaydirilamayan bir icerikte RefreshIndicator calismaz; bu yuzden
  /// icerigi ekran yuksekligine esit bir kaydirilabilir alana koyuyoruz.
  Widget _cekilebilir(Widget cocuk) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await depo.duyurulariYenile();
      },
      color: Renkler.vurgu,
      backgroundColor: Renkler.yuzey,
      child: LayoutBuilder(
        builder: (context, sinirlar) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: sinirlar.maxHeight, child: cocuk),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Haberler
  // ------------------------------------------------------------------

  /// TRT Haber'den suzulmus deprem haberleri.
  ///
  /// Haber bulunmamasi NORMAL: deprem haberi ancak kayda deger bir
  /// deprem oldugunda cikiyor. Bu yuzden bos oldugunda hata degil,
  /// sadece bolum hic gosterilmiyor - altta bultenler zaten var.
  Widget _haberBolumu(BuildContext context) {
    if (depo.haberYukleniyor) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    final haberler = depo.haberler;
    if (haberler.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bolumBasligi('HABERLER', 'TRT Haber'),
        for (final h in haberler.take(6)) ...[
          _haberKarti(context, h),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        _bolumBasligi(
          'RESMÎ VERİ BÜLTENLERİ',
          'AFAD · son ${DepremDeposu.bultenGunSayisi} gün',
        ),
      ],
    );
  }

  Widget _bolumBasligi(String baslik, String altYazi) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 2),
      child: Row(
        children: [
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Renkler.metinSolgun,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: Renkler.kenarlik)),
          const SizedBox(width: 8),
          Text(
            altYazi,
            style: const TextStyle(
              fontSize: 10.5,
              color: Renkler.metinSolgun,
            ),
          ),
        ],
      ),
    );
  }

  Widget _haberKarti(BuildContext context, Haber h) {
    final tahmin = HaberFiltresi.tahminIddiasiMi(h);

    return Material(
      color: Renkler.yuzey,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _haberiAc(context, h),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Renkler.kenarlik),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (h.gorselUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    h.gorselUrl!,
                    fit: BoxFit.cover,
                    // Gorsel yuklenemezse kart yine calissin
                    errorBuilder: (_, __, ___) => Container(
                      color: Renkler.yuzeyUst,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined,
                          size: 28, color: Renkler.metinSolgun),
                    ),
                    loadingBuilder: (context, cocuk, ilerleme) {
                      if (ilerleme == null) return cocuk;
                      return Container(
                        color: Renkler.yuzeyUst,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tahmin) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3B341)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 14, color: Color(0xFFE3B341)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tahmin iddiası içerebilir — deprem '
                                'önceden bilinemez',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE3B341),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      h.baslik,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Renkler.metin,
                        height: 1.3,
                      ),
                    ),
                    if (h.ozet.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        h.ozet,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Renkler.metinSolgun,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 14, color: Renkler.metinSolgun),
                        const SizedBox(width: 5),
                        Text(
                          '${h.kaynak} · ${h.gecenSure}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Renkler.metinSolgun,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.open_in_new,
                            size: 14, color: Renkler.metinSolgun),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _haberiAc(BuildContext context, Haber h) async {
    HapticFeedback.selectionClick();
    try {
      final adres = Uri.parse(h.baglanti);
      if (await canLaunchUrl(adres)) {
        await launchUrl(adres, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Acilamadiysa baglantiyi panoya kopyala
    await AcilDurumServisi.panoyaKopyala(h.baglanti);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Haber açılamadı, bağlantı panoya kopyalandı'),
        duration: Duration(seconds: 3),
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
                              '${b.artciMetni} · en büyüğü '
                              '${b.enBuyukArtci.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Renkler.metin,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${b.egilim.etiket} · daha küçük artçılar '
                              'bu sayıya dahil değil',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
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
            'Bültenler iki kaynağı birleştirir: AFAD 30 günlük derinliği '
            'verir, Kandilli ise son 24 saatin tazeliğini. AFAD zaman '
            'zaman saatlerce gecikmeli yayınladığı için tek başına '
            'kullanıldığında son yarım gün eksik kalıyordu.\n\n'
            'Aynı deprem iki kaynakta da varsa tek kayda indirilir '
            've AFAD\'ın resmî parametreleri korunur.\n\n'
            'Artçı sayımı bu veri kümesi üzerinden yapılır: bültenler '
            '3.0 eşiğiyle çekildiği için daha küçük artçılar sayıya '
            'girmez. Gerçek artçı sayısı gösterilenden fazladır.\n\n'
            'Hissedilirlik tahmini de bu veriden hesaplanır ve '
            'yaklaşıktır.\n\n'
            'Haberler TRT Haber RSS beslemesinden alınır; başlık, kısa '
            'özet ve görsel gösterilir, karta dokununca haber kaynağın '
            'sitesinde açılır. Deprem haberi ancak kayda değer bir '
            'deprem olduğunda çıkar; sakin dönemlerde haber bölümü '
            'görünmez.\n\n'
            'Bültenler kurumların basın açıklaması değildir. Resmî '
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
