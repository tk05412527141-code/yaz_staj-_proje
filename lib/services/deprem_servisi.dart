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
  static Future<List<Deprem>> getir({
    required VeriKaynagi kaynak,
    required int gunSayisi,
    required double minBuyukluk,
  }) async {
    final List<Deprem> depremler;
    if (kaynak == VeriKaynagi.afad) {
      depremler = await _afaddanGetir(gunSayisi, minBuyukluk);
    } else {
      depremler = await _kandillidenGetir(gunSayisi, minBuyukluk);
    }

    // En yeniden en eskiye sirala
    depremler.sort((a, b) => b.tarih.compareTo(a.tarih));
    return depremler;
  }

  // ------------------------------------------------------------------
  // AFAD
  // ------------------------------------------------------------------

  static Future<List<Deprem>> _afaddanGetir(
    int gunSayisi,
    double minBuyukluk,
  ) async {
    final simdi = DateTime.now();
    final baslangic = simdi.subtract(Duration(days: gunSayisi));

    final adres = Uri.parse(_afadUrl).replace(queryParameters: {
      'start': _afadTarihFormati(baslangic),
      'end': _afadTarihFormati(simdi),
      'orderby': 'timedesc',
      'limit': '1000',
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
    int gunSayisi,
    double minBuyukluk,
  ) async {
    // Bu API tarih araligi parametresi almiyor; son N kaydi verip
    // filtrelemeyi biz yapiyoruz.
    final adres = Uri.parse(_kandilliUrl).replace(queryParameters: {
      'limit': '500',
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

    final sinir = DateTime.now().subtract(Duration(days: gunSayisi));

    final List<Deprem> sonuc = [];
    for (final oge in kayitlar) {
      if (oge is! Map<String, dynamic>) continue;
      final deprem = Deprem.kandilliden(oge);
      if (deprem.buyukluk >= minBuyukluk && deprem.tarih.isAfter(sinir)) {
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
