import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/haber.dart';

/// Resmi haber kaynaklarindan deprem haberlerini ceker.
///
/// KAYNAK SECIMI
///   TRT Haber (devlet yayincisi) RSS beslemesi kullaniliyor. Anadolu
///   Ajansi'nin beslemesi sikistirilmis donuyor ve guvenilir sekilde
///   cozulemedi; denendi, calismadi.
///
/// TELIF
///   RSS beslemeleri sendikasyon icin yayinlanir. Baslik + kisa ozet +
///   kaynak adi + ozgun baglanti gosteriyoruz; tam metin kopyalamiyoruz.
///   Gorseller beslemenin kendi sagladigi adreslerden yukleniyor.
///   Karta dokunulunca haber kaynagin sitesinde aciliyor.
///
/// GERCEKCI BEKLENTI
///   Deprem haberi ancak kayda deger bir deprem oldugunda cikar. Sakin
///   donemlerde bu liste BOS OLUR ve bu normaldir. Duyurular sekmesi bu
///   yuzden haberleri tek basina degil, resmi veri bultenleriyle
///   birlikte gosteriyor.
class HaberServisi {
  const HaberServisi._();

  /// TRT Haber son dakika beslemesi.
  ///
  /// Bu besleme <imageUrl> alani iceriyor; manset beslemesinde gorsel
  /// yalnizca description icindeki HTML'de gomulu geliyor.
  static const _trtSonDakika = 'https://www.trthaber.com/sondakika.rss';
  static const _trtManset = 'https://www.trthaber.com/manset.rss';

  static const _zamanAsimi = Duration(seconds: 15);

  /// Deprem haberlerini getirir.
  ///
  /// Iki besleme birlestirilir, tekrarlar baglantiya gore ayiklanir.
  /// Bir besleme basarisiz olursa digeri yine de kullanilir.
  static Future<List<Haber>> getir() async {
    final tumu = <Haber>[];

    final sonuclar = await Future.wait([
      _beslemeyiCek(_trtSonDakika),
      _beslemeyiCek(_trtManset),
    ]);

    for (final liste in sonuclar) {
      tumu.addAll(liste);
    }

    // Ayni haber iki beslemede de olabilir
    final gorulen = <String>{};
    final benzersiz = <Haber>[];
    for (final h in tumu) {
      if (gorulen.add(h.baglanti)) benzersiz.add(h);
    }

    return HaberFiltresi.suz(benzersiz);
  }

  static Future<List<Haber>> _beslemeyiCek(String adres) async {
    try {
      final yanit = await http
          .get(Uri.parse(adres))
          .timeout(_zamanAsimi);

      if (yanit.statusCode != 200) return const [];

      // Turkce karakterler icin utf8.decode sart
      final govde = utf8.decode(yanit.bodyBytes, allowMalformed: true);
      return _ayristir(govde);
    } on TimeoutException {
      debugPrint('Haber beslemesi zaman asimi: $adres');
      return const [];
    } catch (e) {
      debugPrint('Haber beslemesi okunamadi ($adres): $e');
      return const [];
    }
  }

  static List<Haber> _ayristir(String xmlMetni) {
    try {
      final belge = XmlDocument.parse(xmlMetni);
      final ogeler = belge.findAllElements('item');

      final sonuc = <Haber>[];
      for (final oge in ogeler) {
        final baslik = _metin(oge, 'title');
        final baglanti = _metin(oge, 'link');
        if (baslik.isEmpty || baglanti.isEmpty) continue;

        final hamOzet = _metin(oge, 'description');

        sonuc.add(Haber(
          baslik: _htmlTemizle(baslik),
          ozet: _htmlTemizle(hamOzet),
          baglanti: baglanti,
          gorselUrl: _gorselBul(oge, hamOzet),
          tarih: _tarihCoz(_metin(oge, 'pubDate')),
          kaynak: 'TRT Haber',
          kategori: _metin(oge, 'category'),
        ));
      }
      return sonuc;
    } catch (e) {
      debugPrint('RSS ayristirilamadi: $e');
      return const [];
    }
  }

  static String _metin(XmlElement oge, String ad) {
    try {
      return oge.getElement(ad)?.innerText.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Gorsel adresini bulur.
  ///
  /// Iki bicim var:
  ///   1. <imageUrl>https://...</imageUrl>          (sondakika.rss)
  ///   2. description icinde <img src="https://..."> (manset.rss)
  static String? _gorselBul(XmlElement oge, String aciklama) {
    final dogrudan = _metin(oge, 'imageUrl');
    if (dogrudan.startsWith('http')) return dogrudan;

    // enclosure etiketi bazi beslemelerde kullaniliyor
    final ek = oge.getElement('enclosure')?.getAttribute('url');
    if (ek != null && ek.startsWith('http')) return ek;

    final eslesme =
        RegExp(r'''<img[^>]+src=["']([^"']+)["']''').firstMatch(aciklama);
    final url = eslesme?.group(1);
    if (url != null && url.startsWith('http')) return url;

    return null;
  }

  /// HTML etiketlerini ve varliklarini temizler.
  static String _htmlTemizle(String ham) {
    var s = ham
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]*>'), ' ');

    const varliklar = {
      '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"',
      '&#39;': "'", '&apos;': "'", '&nbsp;': ' ',
    };
    varliklar.forEach((k, v) => s = s.replaceAll(k, v));

    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// RFC 822 tarihini cozer: "Sun, 26 Jul 2026 12:43:00 +0300"
  ///
  /// DateTime.tryParse bu bicimi anlamiyor, elle cozuyoruz.
  static DateTime _tarihCoz(String ham) {
    if (ham.isEmpty) return DateTime.now();

    const aylar = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };

    try {
      final e = RegExp(
        r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})',
      ).firstMatch(ham);
      if (e == null) return DateTime.now();

      final ay = aylar[e.group(2)];
      if (ay == null) return DateTime.now();

      return DateTime(
        int.parse(e.group(3)!),
        ay,
        int.parse(e.group(1)!),
        int.parse(e.group(4)!),
        int.parse(e.group(5)!),
        int.parse(e.group(6)!),
      );
    } catch (_) {
      return DateTime.now();
    }
  }
}
