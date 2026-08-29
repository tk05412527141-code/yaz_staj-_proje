import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/deprem_servisi.dart';
import '../services/tercih_servisi.dart';
import '../models/hazirlik_maddesi.dart';
import '../state/deprem_deposu.dart';
import '../utils/cam_tema.dart';
import '../utils/tema.dart';
import 'hazirlik_ekrani.dart';
import 'yerlerim_ekrani.dart';

/// Ayarlar sekmesi: veri kaynagi secimi, uygulama ve kaynak bilgileri.
class AyarlarSekmesi extends StatelessWidget {
  final DepremDeposu depo;

  const AyarlarSekmesi({super.key, required this.depo});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: depo,
      builder: (context, _) {
        return SafeArea(
          bottom: false,
          child: ListView(
            // Alt bosluk: yuzen cam sekme cubugu son bolumu kapatmasin.
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              CamOlculer.altBosluk(context) + 8,
            ),
            children: [
              const Text(
                'Ayarlar',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Renkler.metin,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 22),
              _bolumBasligi('YERLERİM'),
              _kutu(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Renkler.vurgu.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.place_outlined,
                        size: 20, color: Renkler.vurgu),
                  ),
                  title: const Text(
                    'Takip ettiğim yerler',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    depo.konumlar.isEmpty
                        ? 'Henüz yer eklemedin'
                        : depo.konumlar.map((k) => k.ad).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Renkler.metinSolgun,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => YerlerimEkrani(depo: depo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Eklediğin yerler için depremlerin tahmini olarak ne kadar '
                  'hissedileceği hesaplanır. Konum bilgisi yalnızca telefonunda '
                  'saklanır, hiçbir yere gönderilmez.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Renkler.metinSolgun,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _bolumBasligi('DEPREM ÖNCESİ'),
              _kutu(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3FB950).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.health_and_safety_outlined,
                        size: 20, color: Color(0xFF3FB950)),
                  ),
                  title: const Text(
                    'Hazırlık ve hatırlatmalar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    depo.hazirlik.tamamlananSayisi == 0
                        ? 'Kontrol listesi · henüz başlamadın'
                        : '${depo.hazirlik.tamamlananSayisi}/'
                            '${HazirlikListesi.tumu.length} madde tamam · '
                            '${depo.acikHatirlatmaSayisi} hatırlatma açık',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Renkler.metinSolgun,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HazirlikEkrani(depo: depo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Bu uygulama deprem tahmini yapamaz ve erken uyarı veremez. '
                  'Deprem olmadan önce yapabileceği şey seni hazırlıklı '
                  'tutmak — nedenini hazırlık ekranından okuyabilirsin.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Renkler.metinSolgun,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _bolumBasligi('VERİ KAYNAĞI'),
              _kutu(
                child: Column(
                  children: [
                    for (final k in VeriKaynagi.values) ...[
                      RadioListTile<VeriKaynagi>(
                        value: k,
                        groupValue: depo.kaynak,
                        onChanged: (secilen) {
                          if (secilen != null) depo.kaynakDegistir(secilen);
                        },
                        activeColor: Renkler.vurgu,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(
                          k.ad,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Renkler.metin,
                          ),
                        ),
                        subtitle: Text(
                          switch (k) {
                            VeriKaynagi.otomatik =>
                              'İki kaynağı aynı anda dener, verisi daha '
                                  'taze olanı kullanır. Önerilen.',
                            VeriKaynagi.afad =>
                              'Resmî kurum verisi. Geçmişe dönük arama '
                                  'yapabilir ama zaman zaman saatlerce '
                                  'gecikmeli yayınlanır.',
                            VeriKaynagi.kandilli =>
                              'Boğaziçi Üniv. Kandilli Rasathanesi verisi. '
                                  'Genelde çok daha güncel ama yalnızca '
                                  'son 24 saati verir.',
                          },
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: Renkler.metinSolgun,
                          ),
                        ),
                      ),
                      if (k != VeriKaynagi.values.last) const GlassDivider(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _bolumBasligi('TERCİHLER'),
              _kutu(
                child: Column(
                  children: [
                    _satir(
                      Icons.history,
                      'Zaman aralığı',
                      depo.gunSayisi == 1
                          ? 'Son 24 saat'
                          : 'Son ${depo.gunSayisi} gün',
                    ),
                    const GlassDivider(),
                    _satir(
                      Icons.speed,
                      'Minimum büyüklük',
                      depo.minBuyukluk == 0
                          ? 'Sınır yok'
                          : depo.minBuyukluk.toStringAsFixed(1),
                    ),
                    const GlassDivider(),
                    _satir(Icons.sort, 'Sıralama', depo.siralama.etiket),
                    const GlassDivider(),
                    ListTile(
                      leading:
                          const Icon(Icons.restart_alt, color: Renkler.vurgu),
                      title: const Text(
                        'Filtreleri sıfırla',
                        style: TextStyle(
                          color: Renkler.vurgu,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () async {
                        await depo.filtreleriSifirla();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filtreler sıfırlandı'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Tercihlerin telefonda saklanır; uygulamayı kapatıp '
                  'açtığında aynı ayarlarla devam eder.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Renkler.metinSolgun,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _bolumBasligi('HAKKINDA'),
              _kutu(
                child: Column(
                  children: [
                    _satir(
                        Icons.info_outline, 'Uygulama', 'Depremin Nabzı 1.0'),
                    const GlassDivider(),
                    _satir(Icons.public, 'Harita', 'OpenStreetMap'),
                    const GlassDivider(),
                    ListTile(
                      leading: const Icon(Icons.replay_outlined),
                      title: const Text('Tanıtımı tekrar göster'),
                      subtitle: const Text(
                        'Uygulamayı bir sonraki açışında',
                        style: TextStyle(color: Renkler.metinSolgun),
                      ),
                      onTap: () async {
                        await TercihServisi.tanitimiSifirla();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Tanıtım bir sonraki açılışta gösterilecek'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                    const GlassDivider(),
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: const Text('AFAD veri servisi'),
                      subtitle: const Text(
                        'deprem.afad.gov.tr',
                        style: TextStyle(color: Renkler.metinSolgun),
                      ),
                      trailing: const Icon(Icons.copy, size: 18),
                      onTap: () => _kopyala(
                        context,
                        'https://deprem.afad.gov.tr/apiv2/event/filter',
                        'AFAD adresi kopyalandı',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Deprem verileri AFAD ve Boğaziçi Üniversitesi Kandilli '
                'Rasathanesi\'ne aittir. Harita verileri © OpenStreetMap '
                'katkıda bulunanlar.\n\n'
                'Bu uygulama bilgilendirme amaçlıdır; acil durumlarda '
                'resmî kaynakları esas alın.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: Renkler.metinSolgun,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------

  Widget _bolumBasligi(String yazi) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          yazi,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Renkler.metinSolgun,
          ),
        ),
      );

  /// Ayar bolumlerinin cam govdesi.
  ///
  /// iOS 26'da ayar gruplari cam bir "platter" uzerinde durur; satirlar
  /// (ListTile, RadioListTile) opak kalir. Bu yuzden ic ogelere ayrica
  /// cam vermiyoruz - cam ustune cam koymak efekti bozuyor.
  Widget _kutu({required Widget child}) => GlassCard(
        quality: GlassQuality.minimal,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: const LiquidRoundedSuperellipse(borderRadius: 20),
        child: child,
      );

  Widget _satir(IconData ikon, String baslik, String deger) => ListTile(
        leading: Icon(ikon),
        title: Text(baslik),
        trailing: Text(
          deger,
          style: const TextStyle(
            color: Renkler.metinSolgun,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Future<void> _kopyala(
      BuildContext context, String metin, String mesaj) async {
    await Clipboard.setData(ClipboardData(text: metin));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), duration: const Duration(seconds: 2)),
    );
  }
}
