import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Konumun nereden geldigini belirtir.
///
/// Kullaniciya bunu GOSTERIYORUZ: acil durumda "bu gerçek GPS konumum mu,
/// yoksa evimin kayitli konumu mu?" sorusunun cevabini bilmek onemli.
enum KonumKaynagi {
  gps('GPS'),
  sonBilinen('Son bilinen konum'),
  kayitliYer('Kayıtlı yer'),
  yok('Konum alınamadı');

  final String etiket;
  const KonumKaynagi(this.etiket);
}

class KonumSonucu {
  final double? enlem;
  final double? boylam;
  final KonumKaynagi kaynak;

  /// GPS'in bildirdigi yatay dogruluk (metre). Yalnizca gps kaynaginda dolu.
  final double? dogrulukM;

  /// Kullaniciya gosterilecek hata/aciklama metni (varsa)
  final String? mesaj;

  const KonumSonucu({
    this.enlem,
    this.boylam,
    required this.kaynak,
    this.dogrulukM,
    this.mesaj,
  });

  bool get varMi => enlem != null && boylam != null;

  String get koordinatMetni => varMi
      ? '${enlem!.toStringAsFixed(5)}, ${boylam!.toStringAsFixed(5)}'
      : '—';

  /// Tarayicida veya harita uygulamasinda acilabilecek baglanti.
  String get haritaBaglantisi => varMi
      ? 'https://www.google.com/maps/search/?api=1&query=$enlem,$boylam'
      : '';
}

/// Acil durum mesaji icin konum saglar.
///
/// TASARIM
///   Acil durumda konum alinamamasi kabul edilebilir DEGIL: mesaj yine
///   gitmeli, sadece konumsuz. Bu yuzden basamakli bir yedekleme var:
///
///     1. GPS (en iyi)                       -> 12 saniye zaman asimi
///     2. Cihazin son bilinen konumu         -> aninda, GPS kapaliysa
///     3. Kullanicinin kayitli "Yerlerim"i   -> hic konum izni yoksa
///     4. Konumsuz mesaj                     -> hicbiri yoksa
///
/// GIZLILIK
///   Konum SADECE acil durum butonuna basildiginda okunur. Arka planda
///   takip yok, surekli dinleme yok, hicbir sunucuya gonderilmiyor.
class KonumServisi {
  const KonumServisi._();

  /// GPS icin ne kadar beklenecek.
  ///
  /// Acil durumda uzun beklemek anlamsiz: 12 saniyede sonuc gelmezse
  /// yedege gecip mesaji gondermek daha degerli.
  static const zamanAsimi = Duration(seconds: 12);

  /// Izin durumunu sorar (istem GOSTERMEZ).
  static Future<bool> izinVarMi() async {
    try {
      final izin = await Geolocator.checkPermission();
      return izin == LocationPermission.always ||
          izin == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Konum izni okunamadi: $e');
      return false;
    }
  }

  /// Konum servisinin (GPS) cihazda acik olup olmadigi.
  static Future<bool> servisAcikMi() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Konum servisi durumu okunamadi: $e');
      return false;
    }
  }

  /// Izin ister. Kullanici kalici olarak reddettiyse false doner.
  static Future<bool> izinIste() async {
    try {
      var izin = await Geolocator.checkPermission();

      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }

      // deniedForever: sistem artik istem gostermez, kullanici ayarlardan
      // acmali. Arayuzde bunu soylememiz gerekiyor.
      return izin == LocationPermission.always ||
          izin == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Konum izni istenemedi: $e');
      return false;
    }
  }

  /// Iznin kalici olarak reddedilip reddedilmedigi.
  static Future<bool> kaliciReddedildiMi() async {
    try {
      return await Geolocator.checkPermission() ==
          LocationPermission.deniedForever;
    } catch (_) {
      return false;
    }
  }

  /// Konumu basamakli yedeklemeyle getirir.
  ///
  /// [yedekEnlem]/[yedekBoylam] genelde kullanicinin kayitli "Evim"
  /// konumudur; GPS hicbir sekilde alinamazsa kullanilir.
  static Future<KonumSonucu> konumAl({
    double? yedekEnlem,
    double? yedekBoylam,
  }) async {
    // --- 1. GPS ---
    try {
      if (await izinVarMi() && await servisAcikMi()) {
        final konum = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: zamanAsimi,
          ),
        ).timeout(zamanAsimi + const Duration(seconds: 2));

        return KonumSonucu(
          enlem: konum.latitude,
          boylam: konum.longitude,
          kaynak: KonumKaynagi.gps,
          dogrulukM: konum.accuracy,
        );
      }
    } on TimeoutException {
      debugPrint('GPS zaman asimi, yedege geciliyor');
    } catch (e) {
      debugPrint('GPS okunamadi: $e');
    }

    // --- 2. Cihazin son bilinen konumu ---
    try {
      final son = await Geolocator.getLastKnownPosition();
      if (son != null) {
        return KonumSonucu(
          enlem: son.latitude,
          boylam: son.longitude,
          kaynak: KonumKaynagi.sonBilinen,
          dogrulukM: son.accuracy,
          mesaj: 'GPS alınamadı, son bilinen konum kullanıldı.',
        );
      }
    } catch (e) {
      debugPrint('Son bilinen konum okunamadi: $e');
    }

    // --- 3. Kullanicinin kayitli yeri ---
    if (yedekEnlem != null && yedekBoylam != null) {
      return KonumSonucu(
        enlem: yedekEnlem,
        boylam: yedekBoylam,
        kaynak: KonumKaynagi.kayitliYer,
        mesaj: 'GPS alınamadı, kayıtlı yerinin konumu kullanıldı.',
      );
    }

    // --- 4. Konum yok ---
    return const KonumSonucu(
      kaynak: KonumKaynagi.yok,
      mesaj: 'Konum alınamadı. Mesaj konum bilgisi olmadan gönderilecek.',
    );
  }

  /// Cihazin konum ayarlarini acar (kalici red durumunda kullaniciyi
  /// yonlendirmek icin).
  static Future<void> ayarlariAc() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Ayarlar acilamadi: $e');
    }
  }
}
