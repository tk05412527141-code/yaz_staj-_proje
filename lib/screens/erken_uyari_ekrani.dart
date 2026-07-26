import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/tema.dart';

/// Erken uyari hakkinda durust bilgilendirme.
///
/// NEDEN BOYLE BIR EKRAN VAR?
///   Kullanicilar deprem uygulamalarindan "depremi onceden haber vermesini"
///   bekliyor. Bu beklentiyi bos birakmak ya da ustu kapali gecmek yerine
///   acikca ele aliyoruz:
///
///     - Deprem TAHMINI bilimsel olarak mumkun degil
///     - Erken uyari gercek ama bu uygulamanin altyapisiyla yapilamaz
///     - Kullanicinin erken uyari alabilecegi GERCEK yollar var
///
///   "Biz bunu yapamayiz ama sunu ac" demek, sahte bir erken uyari
///   vaadinden hem daha durust hem kullaniciya daha faydali.
class ErkenUyariEkrani extends StatelessWidget {
  const ErkenUyariEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erken uyarı')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _uyariKutusu(),
          const SizedBox(height: 24),

          _baslik('Üç farklı şey karıştırılıyor'),
          const SizedBox(height: 14),

          _kavramKarti(
            ikon: Icons.block,
            renk: const Color(0xFFF85149),
            baslik: 'Deprem tahmini',
            durum: 'Mümkün değil',
            aciklama: '"Yarın 7.0 olacak" demek bilimsel olarak yapılamıyor. '
                'ABD Jeoloji Araştırmaları Kurumu (USGS) bugüne kadar hiçbir '
                'bilim insanının büyük bir depremi önceden bildiremediğini ve '
                'öngörülebilir gelecekte de bunu beklemediklerini belirtiyor.\n\n'
                'Bunu vaat eden bir uygulama görürsen şüpheyle yaklaş.',
          ),
          const SizedBox(height: 12),

          _kavramKarti(
            ikon: Icons.bolt,
            renk: const Color(0xFFE3B341),
            baslik: 'Erken uyarı',
            durum: 'Gerçek — ama bu uygulama yapamaz',
            aciklama: 'Deprem başladıktan sonra, yıkıcı dalga sana ulaşmadan '
                'önce haber vermek. Hızlı ilerleyen P dalgası (5–7 km/sn) ile '
                'yıkıcı S dalgası (3–4 km/sn) arasındaki farktan yararlanır; '
                'veri ise ışık hızında gider.\n\n'
                'Bunun için sismik istasyon ağı ya da işletim sistemi '
                'seviyesinde erişim gerekiyor. Bu uygulama AFAD ve Kandilli\'nin '
                'açık verilerini kullanıyor; o veriler deprem analiz edilip '
                'yayınlandıktan sonra geliyor — erken uyarı için çok geç.',
          ),
          const SizedBox(height: 12),

          _kavramKarti(
            ikon: Icons.check_circle_outline,
            renk: Renkler.canli,
            baslik: 'Hazırlık ve bilgilendirme',
            durum: 'Bu uygulamanın yaptığı',
            aciklama: 'Olan depremleri gösteriyor, senin yerlerinde ne kadar '
                'hissedileceğini tahmin ediyor ve deprem olmadan önce '
                'hazırlık hatırlatmaları gönderiyor.\n\n'
                'Sarsıntı anında saniyeler kazandırmıyor; ama o anı hazırlıklı '
                'karşılamana yardım ediyor.',
          ),

          const SizedBox(height: 28),
          _baslik('Erken uyarıyı nereden alabilirsin?'),
          const SizedBox(height: 6),
          const Text(
            'Aşağıdakiler bu uygulamadan bağımsız çalışır. Hepsini birden '
            'açık tutmak en iyisi.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Renkler.metinSolgun,
            ),
          ),
          const SizedBox(height: 14),

          _yolKarti(
            context,
            ikon: Icons.android,
            baslik: 'Android deprem uyarıları',
            adimlar: 'Ayarlar → Güvenlik ve acil durum → Deprem uyarıları\n'
                'Bazı sürümlerde: Ayarlar → Konum → Gelişmiş → Deprem uyarıları',
            not: 'Google, Android telefonlardaki ivmeölçerleri kullanarak '
                'sarsıntıyı algılar ve uyarı gönderir.',
          ),
          const SizedBox(height: 10),

          _yolKarti(
            context,
            ikon: Icons.phone_iphone,
            baslik: 'iPhone',
            adimlar: 'Ayarlar → Bildirimler → en alta in → '
                'Resmî Uyarılar bölümündeki tüm anahtarları aç',
            not: 'iOS\'ta işletim sistemi seviyesinde deprem uyarısı '
                'Android\'deki gibi yaygın değil; resmî acil durum '
                'uyarılarını açık tutmak önemli.',
          ),
          const SizedBox(height: 10),

          _yolKarti(
            context,
            ikon: Icons.verified_outlined,
            baslik: 'AFAD Acil uygulaması',
            adimlar: 'App Store veya Play Store\'dan "AFAD Acil" uygulamasını '
                'kur ve bildirimlerine izin ver',
            not: 'Resmî kurum uygulaması. Acil çağrı ve "iyiyim" bildirimi '
                'gibi ek özellikleri var.',
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Renkler.yuzeyUst,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Renkler.metinSolgun),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Erken uyarı her zaman zamanında ulaşmayabilir. Merkez '
                    'üssüne çok yakınsan uyarı, sarsıntıyla aynı anda veya '
                    'sonrasında gelebilir — kazanılan süre mesafeyle artar.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Renkler.metinSolgun,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _uyariKutusu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Renkler.vurgu.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Renkler.vurgu.withValues(alpha: 0.4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Renkler.vurgu, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bu uygulama erken uyarı veremez',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Renkler.metin,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Depremleri olduktan sonra gösterir. Sarsıntı sana ulaşmadan '
            'önce uyarı almak istiyorsan aşağıdaki sistemleri açman gerekiyor.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Renkler.metin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _baslik(String yazi) => Text(
        yazi,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Renkler.metin,
          letterSpacing: -0.3,
        ),
      );

  Widget _kavramKarti({
    required IconData ikon,
    required Color renk,
    required String baslik,
    required String durum,
    required String aciklama,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Renkler.yuzey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Renkler.kenarlik),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, size: 18, color: renk),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Renkler.metin,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      durum,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: renk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aciklama,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Renkler.metinSolgun,
            ),
          ),
        ],
      ),
    );
  }

  Widget _yolKarti(
    BuildContext context, {
    required IconData ikon,
    required String baslik,
    required String adimlar,
    required String not,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Renkler.yuzey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Renkler.kenarlik),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 19, color: Renkler.metin),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Renkler.metin,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Adımları kopyala',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.copy, size: 17),
                color: Renkler.metinSolgun,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: adimlar));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adımlar panoya kopyalandı'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Renkler.yuzeyUst,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              adimlar,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.55,
                color: Renkler.metin,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            not,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Renkler.metinSolgun,
            ),
          ),
        ],
      ),
    );
  }
}
