import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/deprem_servisi.dart';
import '../state/deprem_deposu.dart';
import '../utils/tema.dart';

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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                          k == VeriKaynagi.afad
                              ? 'Resmî kurum verisi. Zaman zaman gecikmeli '
                                  'yayınlanabilir.'
                              : 'Boğaziçi Üniv. Kandilli Rasathanesi verisi. '
                                  'Genelde daha günceldir.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: Renkler.metinSolgun,
                          ),
                        ),
                      ),
                      if (k != VeriKaynagi.values.last) const Divider(),
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
                    const Divider(),
                    _satir(
                      Icons.speed,
                      'Minimum büyüklük',
                      depo.minBuyukluk == 0
                          ? 'Sınır yok'
                          : depo.minBuyukluk.toStringAsFixed(1),
                    ),
                    const Divider(),
                    _satir(Icons.sort, 'Sıralama', depo.siralama.etiket),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.restart_alt,
                          color: Renkler.vurgu),
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
                    _satir(Icons.info_outline, 'Uygulama', 'Deprem Takip 1.0'),
                    const Divider(),
                    _satir(Icons.public, 'Harita', 'OpenStreetMap'),
                    const Divider(),
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

  Widget _kutu({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Renkler.yuzey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Renkler.kenarlik),
        ),
        clipBehavior: Clip.antiAlias,
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
