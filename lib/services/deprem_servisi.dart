import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/deprem.dart';

/// Hangi kurumdan veri cekilecegini belirtir.
enum VeriKaynagi {
  afad('AFAD'),
  kandilli('Kandilli');

  final String ad;
  const VeriKaynagi(this.ad);
}

/// Bir veri cekme isleminin sonucu ve KAPSAMA bilgisi.
///
/// NEDEN SADECE LISTE DONMUYORUZ?
///   Kandilli endpoint'i tarih filtresi almiyor: sadece "son N kayit"
///   veriyor. Turkiye'de gunde 100-300 deprem oldugu icin 1000 kayit
///   bile 3-7 gunu zar zor kapsiyor.
///
///   Kullanici "son 30 gun" sectiginde elimizde 30 gunluk veri OLMADIGI
///   halde liste doluymus gibi gorunuyordu. Bu sessiz bir eksiklik ve
///   kullanicinin yanlis sonuc cikarmasina yol aciyor.
///
///   Bu sinif, verinin istenen araligi gercekten kapsayip kapsamadigini
///   soyluyor; arayuz de bunu kullaniciya bildiriyor.
class DepremYanit {
  final List<Deprem> depremler;

  /// Kullanicinin istedigi baslangic tarihi
  final DateTime istenenBaslangic;

  /// Sunucudan kac kayit istendigi
  final int kayitSiniri;

  final VeriKaynagi kaynak;

  const DepremYanit({
    required this.depremler,
    required this.istenenBaslangic,
    required this.kayitSiniri,
    required this.kaynak,
  });

  /// Elimizdeki en eski kaydin tarihi (liste bossa null)
  DateTime? get enEskiKayit {
    if (depremler.isEmpty) return null;
    // Liste yeniden eskiye sirali
    return depremler.last.tarih;
  }

  /// Veri istenen araligi kapsamiyor mu?
  ///
  /// Kayit sayisi sinira dayanmis VE en eski kayit istenen baslangictan
  /// belirgin olarak yeniyse, sunucu bize araligin tamamini vermemis.
  bool get kapsamEksik {
    final enEski = enEskiKayit;
    if (enEski == null) return false;
    if (depremler.length < kayitSiniri) return false;

    // 2 saatlik tolerans: kucuk sapmalar dogal
    return enEski.isAfter(
      istenenBaslangic.add(const Duration(hours: 2)),
    );
  }

  /// Verinin gercekte kac gunu kapsadigi
  int get kapsananGun {
    final enEski = enEskiKayit;
    if (enEski == null) return 0;
    return DateTime.now().difference(enEski).inDays;
  }
}

/// Deprem verilerini internetten ceken servis.
///
/// Iki farkli kaynak destekleniyor:
///   - AFAD     : resmi kurum, dogrudan kendi API'si
///   - Kandilli : Bogazici Universitesi verisi (acik bir API uzerinden)
///
/// Iki kaynak birden desteklenmesinin sebebi: biri gecici olarak
/// erisilemez ya da gecikmeli olursa uygulama calismaya devam etsin.
class DepremServisi {
  static const String _afadUrl = 'https://deprem.afad.gov.tr/apiv2/event/filter';
  static const String _kandilliUrl =
      'https://api.orhanaydogdu.com.tr/deprem/kandilli/live';

  static const Duration _zamanAsimi = Duration(seconds: 20);

  /// Secilen kaynaktan depremleri getirir.
  ///
  /// [gunSayisi]   kac gun geriye gidilecek
  /// [minBuyukluk] bu degerin altindaki depremler elenir
  static Future<DepremYanit> getir({
    required VeriKaynagi kaynak,
    required int gunSayisi,
    required double minBuyukluk,
    int kayitSiniri = 1000,
  }) async {
    final simdi = DateTime.now();
    final istenenBaslangic = simdi.subtract(Duration(days: gunSayisi));

    final List<Deprem> depremler;
    if (kaynak == VeriKaynagi.afad) {
      depremler = await _afaddanGetir(
        istenenBaslangic,
        simdi,
        minBuyukluk,
        kayitSiniri,
      );
    } else {
      depremler = await _kandillidenGetir(
        istenenBaslangic,
        minBuyukluk,
        kayitSiniri,
      );
    }

    // En yeniden en eskiye sirala
    depremler.sort((a, b) => b.tarih.compareTo(a.tarih));

    return DepremYanit(
      depremler: depremler,
      istenenBaslangic: istenenBaslangic,
      kayitSiniri: kayitSiniri,
      kaynak: kaynak,
    );
  }

  /// Duyuru bultenleri icin hedefli sorgu.
  ///
  /// NEDEN AYRI BIR SORGU?
  ///   Ana liste "son 7 gun, tum buyuklukler" istiyor. Kandilli endpoint'i
  ///   tarih filtresi almadigi icin sadece son N kaydi veriyor ve
  ///   Turkiye'de gunde 100-300 deprem oldugundan 1000 kayit bile
  ///   7 gunu zar zor kapsiyor.
  ///
  ///   Bultenler ise "son 30 gunun onemli depremleri" istiyor. Ayni
  ///   veriyi kullanmak imkansiz: 30 gunluk tum depremler on binlerce
  ///   kayit olurdu.
  ///
  ///   Cozum: AFAD sunucu tarafinda minmag filtresi destekliyor. Yuksek
  ///   esikli sorgu, 30 gunu kapsayan ama sadece birkac dusuzine kayit
  ///   donen verimli bir istek oluyor.
  static Future<DepremYanit> bultenIcinGetir({
    required VeriKaynagi kaynak,
    required int gunSayisi,
    required double minBuyukluk,
  }) {
    return getir(
      kaynak: kaynak,
      gunSayisi: gunSayisi,
      minBuyukluk: minBuyukluk,
      // Kandilli tarih/buyukluk filtresi almadigi icin daha genis bir
      // pencere istiyoruz; AFAD'da bu sinir zaten asilmaz.
      kayitSiniri: kaynak == VeriKaynagi.afad ? 500 : 2000,
    );
  }

  // ------------------------------------------------------------------
  // AFAD
  // ------------------------------------------------------------------

  static Future<List<Deprem>> _afaddanGetir(
    DateTime baslangic,
    DateTime bitis,
    double minBuyukluk,
    int kayitSiniri,
  ) async {
    // AFAD tarih ve minmag filtresini SUNUCU TARAFINDA destekliyor:
    // yuksek esikli uzun araliklar bile az kayit dondurur.
    final adres = Uri.parse(_afadUrl).replace(queryParameters: {
      'start': _afadTarihFormati(baslangic),
      'end': _afadTarihFormati(bitis),
      'orderby': 'timedesc',
      'limit': kayitSiniri.toString(),
      if (minBuyukluk > 0) 'minmag': minBuyukluk.toStringAsFixed(1),
    });

    final govde = await _istekAt(adres, 'AFAD');

    // AFAD dogrudan bir dizi donuyor: [ {...}, {...} ]
    final dynamic cozulmus = jsonDecode(govde);
    if (cozulmus is! List<dynamic>) {
      throw Exception('AFAD beklenmeyen bir yanit dondu.');
    }

    final List<Deprem> sonuc = [];
    for (final oge in cozulmus) {
      if (oge is! Map<String, dynamic>) continue;
      final deprem = Deprem.afaddan(oge);
      if (deprem.buyukluk >= minBuyukluk) sonuc.add(deprem);
    }
    return sonuc;
  }

  /// AFAD tarihleri "2026-07-26T14:30:00" formatinda bekliyor.
  static String _afadTarihFormati(DateTime t) {
    String iki(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${iki(t.month)}-${iki(t.day)}'
        'T${iki(t.hour)}:${iki(t.minute)}:${iki(t.second)}';
  }

  // ------------------------------------------------------------------
  // Kandilli
  // ------------------------------------------------------------------

  static Future<List<Deprem>> _kandillidenGetir(
    DateTime baslangic,
    double minBuyukluk,
    int kayitSiniri,
  ) async {
    // DIKKAT: Bu API tarih araligi VE buyukluk parametresi ALMIYOR.
    // Sadece "son N kayit" veriyor; filtrelemeyi biz yapiyoruz.
    // Bu yuzden uzun araliklarda veri eksik kalabilir -> DepremYanit
    // .kapsamEksik bunu bildiriyor.
    final adres = Uri.parse(_kandilliUrl).replace(queryParameters: {
      'limit': kayitSiniri.toString(),
    });

    final govde = await _istekAt(adres, 'Kandilli');

    // Kandilli sarmalanmis donuyor: { "status": true, "result": [ ... ] }
    final dynamic cozulmus = jsonDecode(govde);
    if (cozulmus is! Map<String, dynamic>) {
      throw Exception('Kandilli beklenmeyen bir yanit dondu.');
    }

    final dynamic kayitlar = cozulmus['result'];
    if (kayitlar is! List<dynamic>) {
      throw Exception('Kandilli yanitinda deprem listesi bulunamadi.');
    }

    final List<Deprem> sonuc = [];
    for (final oge in kayitlar) {
      if (oge is! Map<String, dynamic>) continue;
      final deprem = Deprem.kandilliden(oge);
      if (deprem.buyukluk >= minBuyukluk &&
          deprem.tarih.isAfter(baslangic)) {
        sonuc.add(deprem);
      }
    }
    return sonuc;
  }

  // ------------------------------------------------------------------
  // Ortak HTTP yardimcisi
  // ------------------------------------------------------------------

  /// Istegi atar, hatalari anlasilir Turkce mesajlara cevirir.
  static Future<String> _istekAt(Uri adres, String kaynakAdi) async {
    try {
      final yanit = await http.get(adres).timeout(_zamanAsimi);

      if (yanit.statusCode != 200) {
        throw Exception(
          '$kaynakAdi sunucusu ${yanit.statusCode} hatasi dondu. '
          'Daha sonra tekrar deneyin.',
        );
      }

      // ONEMLI: yanit.body yerine bodyBytes + utf8.decode kullaniyoruz.
      // Aksi halde Turkce karakterler (ç, ğ, ı, ö, ş, ü) bozuk gorunur.
      return utf8.decode(yanit.bodyBytes);
    } on TimeoutException {
      throw Exception(
        '$kaynakAdi sunucusu zamaninda yanit vermedi. '
        'Internet baglantinizi kontrol edin.',
      );
    } on FormatException {
      throw Exception('$kaynakAdi verisi okunamadi (bozuk yanit).');
    }
  }
}
