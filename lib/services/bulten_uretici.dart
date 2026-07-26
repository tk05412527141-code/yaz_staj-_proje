import '../models/deprem.dart';
import '../models/kayitli_konum.dart';
import '../utils/siddet_hesabi.dart';

/// Onemli bir deprem icin uretilmis bilgi bulteni.
class Bulten {
  final Deprem deprem;

  /// Bu depremden sonra ayni bolgede olan daha kucuk depremler.
  ///
  /// ONEMLI KAPSAM SINIRI
  ///   Bulten verisi [BultenUretici.esikBuyukluk] esigiyle cekiliyor,
  ///   yani esik altindaki artcilar veri setinde HIC YOK. Gercek artci
  ///   sayisi bundan cok daha fazladir.
  ///
  ///   Bu yuzden arayuzde "yaklasik N artci" DEMIYORUZ; "3.0+ artci: N"
  ///   diyoruz. Aksi halde kullanici gercek artci sayisini cok dusuk
  ///   saniyor olurdu.
  final int artciSayisi;

  /// Artcilarin sayildigi en kucuk buyukluk (etiketleme icin).
  final double artciEsigi;

  /// Artcilarin en buyugu (yoksa 0)
  final double enBuyukArtci;

  /// Artci egilimi: son 6 saatteki artci sayisi onceki 6 saatten az mi?
  final ArtciEgilimi egilim;

  /// Kullanicinin yerlerindeki tahmini etki (yer yoksa bos)
  final List<({KayitliKonum konum, SiddetSonucu sonuc})> yerEtkileri;

  /// Bu deprem bulten esigini gecti mi?
  ///
  /// false ise: esigi gecen hic deprem yoktu, bu kayit "en buyukleri"
  /// yedegi olarak gosteriliyor. Arayuz bunu farkli etiketliyor —
  /// kullanici siradan bir sarsintiyi "onemli duyuru" sanmamali.
  final bool esigiGecti;

  const Bulten({
    required this.deprem,
    required this.artciSayisi,
    required this.enBuyukArtci,
    required this.egilim,
    required this.yerEtkileri,
    this.esigiGecti = true,
    this.artciEsigi = BultenUretici.esikBuyukluk,
  });

  /// "3.0+ artçı: 4" gibi dogru etiket.
  String get artciMetni =>
      '${artciEsigi.toStringAsFixed(1)}+ artçı: $artciSayisi';

  /// Bultenin onem derecesi - siralamada ve gorsel vurguda kullanilir.
  bool get onemli => esigiGecti && deprem.buyukluk >= 5.0;

  /// En cok etkilenen kayitli yer (varsa)
  ({KayitliKonum konum, SiddetSonucu sonuc})? get enCokEtkilenen {
    if (yerEtkileri.isEmpty) return null;
    var enIyi = yerEtkileri.first;
    for (final e in yerEtkileri) {
      if (e.sonuc.mmi > enIyi.sonuc.mmi) enIyi = e;
    }
    return enIyi;
  }
}

enum ArtciEgilimi {
  azaliyor('Azalma eğiliminde'),
  suruyor('Sürüyor'),
  yok('Artçı kaydı yok');

  final String etiket;
  const ArtciEgilimi(this.etiket);
}

/// Resmi deprem verisinden bilgi bultenleri uretir.
///
/// NEDEN BOYLE?
///   AFAD ve Kandilli'nin makine-okunabilir bir duyuru/basin aciklamasi
///   beslemesi yok (AFAD'in /rss adresi bos donuyor). HTML kazimak hem
///   kirilgan hem kullanim kosullari acisindan tartismali.
///
///   Bunun yerine bultenleri ZATEN KULLANDIGIMIZ resmi veriden
///   uretiyoruz: onemli depremin resmi parametreleri, o bolgedeki artci
///   sayimi ve kullanicinin yerlerindeki tahmini etki.
///
///   Boylece: dis kaynak yok, kirilma noktasi yok, cevrimdisi calisiyor
///   ve icerigin nereden geldigi net.
class BultenUretici {
  const BultenUretici._();

  /// Bulten uretilmesi icin gereken en kucuk buyukluk.
  ///
  /// ILK DEGER 4.0'DI VE SAYFA SUREKLI BOS KALIYORDU.
  ///   Turkiye'de rastgele bir 24 saatte 4.0+ deprem cogu zaman hic
  ///   olmuyor. Ustelik varsayilan kaynak Kandilli ve o API yalnizca
  ///   son 24 saati veriyor (bkz. DepremServisi). Ikisi birlesince
  ///   duyurular sekmesi olu bir sekmeye donusuyordu.
  ///
  ///   3.0: hissedilmeye baslanan esik. Icerik uretiyor ama her kucuk
  ///   sarsintiyi "duyuru" yapacak kadar da dusuk degil.
  static const esikBuyukluk = 3.0;

  /// Esigi gecen hic deprem yoksa gosterilecek en buyuk kayit sayisi.
  ///
  /// Bos bir sekme kullaniciya hicbir sey soylemiyor. Bunun yerine
  /// "belirgin bir deprem olmadi, en buyukleri sunlar" demek hem
  /// bilgilendirici hem durust.
  static const yedekBultenSayisi = 3;

  /// Artci sayilirken kullanilan yaricap (km).
  ///
  /// Bir depremin artcilari genelde kirilma alani cevresinde olur.
  /// 100 km makul bir yaklasim; kesin bir sinir degil, bu yuzden
  /// arayuzde "yaklasik" diye belirtiyoruz.
  static const artciYaricapKm = 100.0;

  /// Artci sayilirken kullanilan zaman penceresi.
  static const artciPenceresi = Duration(days: 7);

  /// Verilen deprem listesinden bultenler uretir.
  ///
  /// [depremler] tarihe gore sirali olmak zorunda degil; fonksiyon
  /// kendi siralamasini yapar.
  static List<Bulten> uret({
    required List<Deprem> depremler,
    List<KayitliKonum> konumlar = const [],
    DateTime? simdi,
  }) {
    if (depremler.isEmpty) return const [];

    final an = simdi ?? DateTime.now();

    // Esigi gecen depremler bulten adayi
    var adaylar = depremler
        .where((d) => d.buyukluk >= esikBuyukluk)
        .toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));

    // Esigi gecen yoksa en buyukleri yedek olarak goster.
    // Bos sekme yerine "belirgin deprem olmadi, en buyukleri sunlar".
    var yedekMi = false;
    if (adaylar.isEmpty) {
      yedekMi = true;
      final siraliBuyukluk = [...depremler]
        ..sort((a, b) => b.buyukluk.compareTo(a.buyukluk));
      adaylar = siraliBuyukluk.take(yedekBultenSayisi).toList()
        ..sort((a, b) => b.tarih.compareTo(a.tarih));
    }

    final bultenler = <Bulten>[];

    for (final ana in adaylar) {
      // Artci penceresi disindaki (cok eski) depremler icin artci
      // saymiyoruz. Bu kontrol DONGUNUN DISINDA olmali: [ana]'ya bagli,
      // [d]'ye degil. Icerideyken dongu degismezi oldugu icin ya hic
      // calisiyor ya da ilk turda kiriliyordu.
      final pencereIcinde = an.difference(ana.tarih) <= artciPenceresi;

      var sayi = 0;
      var enBuyuk = 0.0;
      var sonAltiSaat = 0;
      var oncekiAltiSaat = 0;

      if (pencereIcinde) {
        for (final d in depremler) {
          // Artci: ana depremden SONRA, DAHA KUCUK, yakin konumda
          if (!d.tarih.isAfter(ana.tarih)) continue;
          if (d.buyukluk >= ana.buyukluk) continue;

          final mesafe = SiddetHesabi.mesafeKm(
            ana.enlem,
            ana.boylam,
            d.enlem,
            d.boylam,
          );
          if (mesafe > artciYaricapKm) continue;

          sayi++;
          if (d.buyukluk > enBuyuk) enBuyuk = d.buyukluk;

          final gecen = an.difference(d.tarih);
          if (gecen.inHours < 6) {
            sonAltiSaat++;
          } else if (gecen.inHours < 12) {
            oncekiAltiSaat++;
          }
        }
      }

      bultenler.add(Bulten(
        deprem: ana,
        artciSayisi: sayi,
        enBuyukArtci: enBuyuk,
        egilim: _egilimBul(sayi, sonAltiSaat, oncekiAltiSaat),
        yerEtkileri: _yerEtkileri(ana, konumlar),
        esigiGecti: !yedekMi,
      ));
    }

    return bultenler;
  }

  static ArtciEgilimi _egilimBul(
    int toplam,
    int sonAltiSaat,
    int oncekiAltiSaat,
  ) {
    if (toplam == 0) return ArtciEgilimi.yok;
    // Karsilastirma icin onceki pencerede kayit olmali
    if (oncekiAltiSaat == 0) return ArtciEgilimi.suruyor;
    return sonAltiSaat < oncekiAltiSaat
        ? ArtciEgilimi.azaliyor
        : ArtciEgilimi.suruyor;
  }

  static List<({KayitliKonum konum, SiddetSonucu sonuc})> _yerEtkileri(
    Deprem d,
    List<KayitliKonum> konumlar,
  ) {
    final sonuc = <({KayitliKonum konum, SiddetSonucu sonuc})>[];
    for (final k in konumlar) {
      sonuc.add((
        konum: k,
        sonuc: SiddetHesabi.hesapla(
          depremEnlem: d.enlem,
          depremBoylam: d.boylam,
          derinlikKm: d.derinlik,
          buyukluk: d.buyukluk,
          noktaEnlem: k.enlem,
          noktaBoylam: k.boylam,
        ),
      ));
    }
    return sonuc;
  }

  /// Bulteni paylasilabilir metne cevirir.
  static String metneCevir(Bulten b) {
    final d = b.deprem;
    final satirlar = <String>[
      '${d.buyukluk.toStringAsFixed(1)} büyüklüğünde deprem',
      d.yer,
      'Tarih: ${d.tarihMetni}',
      'Derinlik: ${d.derinlik.toStringAsFixed(1)} km',
      'Koordinat: ${d.koordinatMetni}',
      'Kaynak: ${d.kaynak}',
    ];

    if (b.artciSayisi > 0) {
      satirlar.add(
        '${b.artciMetni}, en büyüğü '
        '${b.enBuyukArtci.toStringAsFixed(1)} · ${b.egilim.etiket}',
      );
    }

    final etki = b.enCokEtkilenen;
    if (etki != null) {
      satirlar.add(
        '${etki.konum.ad}: ${etki.sonuc.seviye.etiket} '
        '(${etki.sonuc.mesafeMetni})',
      );
    }

    satirlar.add(d.haritaBaglantisi);
    return satirlar.join('\n');
  }
}
