/// Resmi haber kaynagindan gelen bir deprem haberi.
class Haber {
  final String baslik;
  final String ozet;
  final String baglanti;
  final String? gorselUrl;
  final DateTime tarih;
  final String kaynak;
  final String kategori;

  const Haber({
    required this.baslik,
    required this.ozet,
    required this.baglanti,
    required this.tarih,
    required this.kaynak,
    this.gorselUrl,
    this.kategori = '',
  });

  String get gecenSure {
    final fark = DateTime.now().difference(tarih);
    if (fark.isNegative || fark.inMinutes < 1) return 'az önce';
    if (fark.inMinutes < 60) return '${fark.inMinutes} dakika önce';
    if (fark.inHours < 24) return '${fark.inHours} saat önce';
    if (fark.inDays < 30) return '${fark.inDays} gün önce';
    return '${(fark.inDays / 30).floor()} ay önce';
  }
}

/// Haberlerin deprem ve Turkiye ile ilgili olup olmadigini belirler.
///
/// NEDEN AYRI BIR SINIF?
///   Bu mantik saf fonksiyonlardan olusuyor ve test edilebilir olmasi
///   onemli: yanlis bir filtre ya alakasiz haber gosterir ya da gercek
///   deprem haberini gizler.
class HaberFiltresi {
  const HaberFiltresi._();

  /// Depremle ilgili oldugunu gosteren kelimeler.
  static const depremKelimeleri = [
    'deprem', 'sarsıntı', 'sarsinti', 'artçı', 'artci',
    'afad', 'kandilli', 'richter', 'fay hattı', 'fay hatti',
    'tsunami', 'zelzele', 'büyüklüğünde', 'buyuklugunde',
  ];

  /// Turkiye ile ilgili oldugunu gosteren isaretler.
  ///
  /// TRT kategorileri ("Türkiye", "Gündem") birincil sinyal; il adlari
  /// yedek. Boylece "Japonya'da deprem" haberi elenirken
  /// "Ege Denizi'nde deprem" haberi kaliyor.
  static const turkiyeIsaretleri = [
    'türkiye', 'turkiye', 'afad', 'kandilli',
    'ege deniz', 'akdeniz', 'marmara', 'karadeniz',
  ];

  /// Turkiye disi oldugunu gosteren guclu isaretler.
  static const yabanciUlkeler = [
    'japonya', 'endonezya', 'şili', 'sili', 'meksika', 'nepal',
    'afganistan', 'fas', 'italya', 'yunanistan\'da', 'abd\'de',
    'çin\'de', 'cin\'de', 'filipinler', 'peru', 'ekvador',
  ];

  /// TAHMIN IDDIASI kaliplari.
  ///
  /// NEDEN FILTRELIYORUZ?
  ///   Uygulamanin baska bir ekraninda deprem tahmininin bilimsel olarak
  ///   mumkun olmadigini anlatiyoruz (bkz. erken_uyari_ekrani.dart).
  ///   "Uzman uyardi: X ilinde 7'lik deprem" turu icerigi ayni uygulamada
  ///   filtresiz gostermek hem celiskili hem de panige yol acabilir.
  ///
  ///   Bu haberleri GIZLEMIYORUZ, ISARETLIYORUZ: kullanici gorebilir ama
  ///   yaninda "tahmin iddiasi" uyarisi cikiyor. Sansur degil, baglam.
  static const tahminKaliplari = [
    'kahin', 'kâhin', 'ne zaman olacak', 'olacak mı', 'olacak mi',
    'bekleniyor mu', 'tahmin etti', 'öngördü', 'ongordu',
    'büyük deprem uyarısı', 'buyuk deprem uyarisi',
    'deprem tahmini', 'tarih verdi', 'işaret etti',
  ];

  static String _sadelestir(String metin) {
    const donusum = {
      'ı': 'i', 'İ': 'i', 'I': 'i',
      'ş': 's', 'Ş': 's', 'ğ': 'g', 'Ğ': 'g',
      'ü': 'u', 'Ü': 'u', 'ö': 'o', 'Ö': 'o',
      'ç': 'c', 'Ç': 'c', 'â': 'a', 'Â': 'a',
    };
    final t = StringBuffer();
    for (final h in metin.split('')) {
      t.write(donusum[h] ?? h.toLowerCase());
    }
    return t.toString();
  }

  static bool _iceriyorMu(String metin, List<String> kelimeler) {
    final s = _sadelestir(metin);
    for (final k in kelimeler) {
      if (s.contains(_sadelestir(k))) return true;
    }
    return false;
  }

  /// Haber depremle ilgili mi?
  static bool depremleIlgiliMi(Haber h) {
    return _iceriyorMu('${h.baslik} ${h.ozet}', depremKelimeleri);
  }

  /// Haber Turkiye'yi ilgilendiriyor mu?
  ///
  /// Once yabanci ulke isareti aranir; varsa ve Turkiye isareti yoksa
  /// elenir. Kategori "Türkiye" veya "Gündem" ise dogrudan kabul.
  static bool turkiyeIleIlgiliMi(Haber h) {
    final tumMetin = '${h.baslik} ${h.ozet}';
    final kategori = _sadelestir(h.kategori);

    if (kategori == 'turkiye' || kategori == 'gundem') return true;

    final yabanci = _iceriyorMu(tumMetin, yabanciUlkeler);
    final yerli = _iceriyorMu(tumMetin, turkiyeIsaretleri);

    if (yabanci && !yerli) return false;
    return yerli || kategori.isEmpty;
  }

  /// Haber tahmin iddiasi tasiyor mu?
  static bool tahminIddiasiMi(Haber h) {
    return _iceriyorMu('${h.baslik} ${h.ozet}', tahminKaliplari);
  }

  /// Gosterilecek haberleri secer ve tarihe gore siralar.
  static List<Haber> suz(List<Haber> haberler) {
    final sonuc = haberler
        .where(depremleIlgiliMi)
        .where(turkiyeIleIlgiliMi)
        .toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));
    return sonuc;
  }
}
