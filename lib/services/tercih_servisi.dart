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

  // Anahtar isimlerini disariya acmak yerine hazir sabitler veriyoruz.
  static String get anahtarKaynak => _kKaynak;
  static String get anahtarGun => _kGunSayisi;
  static String get anahtarMinBuyukluk => _kMinBuyukluk;
  static String get anahtarSiralama => _kSiralama;
}
