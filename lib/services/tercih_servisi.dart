import 'package:shared_preferences/shared_preferences.dart';

/// Kullanicinin filtre tercihlerini telefonda saklar.
///
/// Uygulama kapatilip acildiginda kullanici ayni ayarlari bulur;
/// her seferinde bastan secmek zorunda kalmaz.
///
/// Arka planda iOS'ta NSUserDefaults, Android'de SharedPreferences kullanilir.
class TercihServisi {
  const TercihServisi._();

  static const _kKaynak = 'kaynak';
  static const _kGunSayisi = 'gun_sayisi';
  static const _kMinBuyukluk = 'min_buyukluk';
  static const _kSiralama = 'siralama';
  static const _kKonumlar = 'kayitli_konumlar';
  static const _kTanitimGoruldu = 'tanitim_goruldu';
  static const _kHazirlik = 'hazirlik_durumu';
  static const _kAcilKisiler = 'acil_kisiler';

  /// Kayitli tercihleri okur. Hic kayit yoksa bos map doner.
  ///
  /// Tercihler kritik veri degil; okuma basarisiz olursa uygulama
  /// varsayilanlarla acilmaya devam etmeli, cokmemelidir.
  static Future<Map<String, Object>> oku() async {
    try {
      final p = await SharedPreferences.getInstance();
      final sonuc = <String, Object>{};

      final kaynak = p.getString(_kKaynak);
      if (kaynak != null) sonuc[_kKaynak] = kaynak;

      final gun = p.getInt(_kGunSayisi);
      if (gun != null) sonuc[_kGunSayisi] = gun;

      final minB = p.getDouble(_kMinBuyukluk);
      if (minB != null) sonuc[_kMinBuyukluk] = minB;

      final sira = p.getString(_kSiralama);
      if (sira != null) sonuc[_kSiralama] = sira;

      return sonuc;
    } catch (_) {
      return {};
    }
  }

  static Future<void> kaydet({
    required String kaynak,
    required int gunSayisi,
    required double minBuyukluk,
    required String siralama,
  }) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kKaynak, kaynak);
      await p.setInt(_kGunSayisi, gunSayisi);
      await p.setDouble(_kMinBuyukluk, minBuyukluk);
      await p.setString(_kSiralama, siralama);
    } catch (_) {
      // Sessizce gec - tercih kaydedilemezse uygulama calismaya devam etsin.
    }
  }

  static Future<void> temizle() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kKaynak);
      await p.remove(_kGunSayisi);
      await p.remove(_kMinBuyukluk);
      await p.remove(_kSiralama);
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Kayitli konumlar (JSON metni olarak saklanir)
  // ------------------------------------------------------------------

  static Future<String?> konumlariOku() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString(_kKonumlar);
    } catch (_) {
      return null;
    }
  }

  static Future<void> konumlariKaydet(String kodlanmis) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kKonumlar, kodlanmis);
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Hazirlik durumu (JSON metni)
  // ------------------------------------------------------------------

  static Future<String?> hazirligiOku() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString(_kHazirlik);
    } catch (_) {
      return null;
    }
  }

  static Future<void> hazirligiKaydet(String kodlanmis) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kHazirlik, kodlanmis);
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Acil durum kisileri (JSON metni)
  // ------------------------------------------------------------------

  static Future<String?> acilKisileriOku() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString(_kAcilKisiler);
    } catch (_) {
      return null;
    }
  }

  static Future<void> acilKisileriKaydet(String kodlanmis) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kAcilKisiler, kodlanmis);
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Ilk acilis tanitimi
  // ------------------------------------------------------------------

  /// Kullanici tanitim ekranlarini daha once gordu mu?
  ///
  /// Okuma basarisiz olursa "gordu" kabul ediyoruz; boylece bir hata
  /// yuzunden kullanici her acilista tanitimla karsilasmaz.
  static Future<bool> tanitimGoruldu() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_kTanitimGoruldu) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> tanitimiIsaretle() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kTanitimGoruldu, true);
    } catch (_) {}
  }

  /// Tanitimi bir sonraki acilista tekrar gostermek icin.
  static Future<void> tanitimiSifirla() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kTanitimGoruldu);
    } catch (_) {}
  }

  // Anahtar isimlerini disariya acmak yerine hazir sabitler veriyoruz.
  static String get anahtarKaynak => _kKaynak;
  static String get anahtarGun => _kGunSayisi;
  static String get anahtarMinBuyukluk => _kMinBuyukluk;
  static String get anahtarSiralama => _kSiralama;
}
