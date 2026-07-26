import '../models/deprem.dart';
import '../models/kayitli_konum.dart';
import '../utils/siddet_hesabi.dart';

/// Onemli bir deprem icin uretilmis bilgi bulteni.
class Bulten {
  final Deprem deprem;

  /// Bu depremden sonra ayni bolgede olan daha kucuk depremler
  final int artciSayisi;

  /// Artcilarin en buyugu (yoksa 0)
  final double enBuyukArtci;

  /// Artci egilimi: son 6 saatteki artci sayisi onceki 6 saatten az mi?
  final ArtciEgilimi egilim;

  /// Kullanicinin yerlerindeki tahmini etki (yer yoksa bos)
  final List<({KayitliKonum konum, SiddetSonucu sonuc})> yerEtkileri;

  const Bulten({
    required this.deprem,
    required this.artciSayisi,
    required this.enBuyukArtci,
    required this.egilim,
    required this.yerEtkileri,
  });

  /// Bultenin onem derecesi - siralamada ve gorsel vurguda kullanilir.
  bool get onemli => deprem.buyukluk >= 5.0;

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
  /// 4.0 alti depremler cok sik oluyor ve bulten degeri tasimiyor;
  /// listede zaten gorunuyorlar.
  static const esikBuyukluk = 4.0;

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
    final adaylar = depremler
        .where((d) => d.buyukluk >= esikBuyukluk)
        .toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));

    final bultenler = <Bulten>[];

    for (final ana in adaylar) {
      // Bu depremin artcilari: SONRASINDA olan, DAHA KUCUK ve
      // yakin konumdaki depremler
      var sayi = 0;
      var enBuyuk = 0.0;
      var sonAltiSaat = 0;
      var oncekiAltiSaat = 0;

      for (final d in depremler) {
        if (!d.tarih.isAfter(ana.tarih)) continue;
        if (d.buyukluk >= ana.buyukluk) continue;
        if (an.difference(ana.tarih) > artciPenceresi) break;

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

      bultenler.add(Bulten(
        deprem: ana,
        artciSayisi: sayi,
        enBuyukArtci: enBuyuk,
        egilim: _egilimBul(sayi, sonAltiSaat, oncekiAltiSaat),
        yerEtkileri: _yerEtkileri(ana, konumlar),
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
        'Artçı: ${b.artciSayisi} kayıt, en büyüğü '
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
