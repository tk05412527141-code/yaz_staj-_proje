import '../models/hazirlik_maddesi.dart';
import 'bildirim_servisi.dart';

/// Hazirlik hatirlatmalarinin ne zaman gonderilecegini hesaplar ve planlar.
///
/// TASARIM
///   Cihaz bildirimleri "her 3 ayda bir" gibi uzun periyotlari kendi
///   basina tekrarlayamaz. Bu yuzden yaklasim su:
///     1. Her madde icin SADECE bir sonraki tarih planlanir
///     2. Uygulama her acildiginda planlama yenilenir
///
///   Kullanici uygulamayi hic acmasa bile planlanan bildirim gider;
///   acildiginda ise bir sonraki planlanir. Pratikte calisan ve ek
///   altyapi gerektirmeyen yontem bu.
class HatirlatmaPlanlayici {
  const HatirlatmaPlanlayici._();

  /// Hic tamamlanmamis bir madde icin ilk durtme kac gun sonra?
  ///
  /// Hemen bildirim gondermek rahatsiz edici, 90 gun beklemek ise
  /// anlamsiz olurdu. Birkac gun sonra hatirlatmak dengeli.
  static const ilkDurtmeGun = 3;

  /// Periyodu coktan gecmis maddeler icin bildirim ne kadar
  /// ertelenecek. Gecmis bir tarihe bildirim planlanamaz.
  static const gecikmisErtelemeGun = 1;

  /// Bir maddenin bir sonraki hatirlatma zamani.
  ///
  /// Saf fonksiyon: test edilebilmesi icin [simdi] disaridan verilebilir.
  static DateTime sonrakiTarih({
    required HazirlikMaddesi madde,
    required HazirlikDurumu durum,
    DateTime? simdi,
  }) {
    final an = simdi ?? DateTime.now();
    final saat = durum.hatirlatmaSaati;
    final tamamlanma = durum.tamamlanma(madde.id);

    // Hic tamamlanmamis: birkac gun sonra nazik bir durtme
    if (tamamlanma == null) {
      return _saatUygula(an.add(const Duration(days: ilkDurtmeGun)), saat);
    }

    // Tamamlanmis: periyot dolunca hatirlat
    final hedef = _saatUygula(
      tamamlanma.add(Duration(days: madde.periyotGun)),
      saat,
    );

    // Periyot coktan gectiyse gecmise bildirim planlanamaz; yarina al
    if (!hedef.isAfter(an)) {
      return _saatUygula(
        an.add(const Duration(days: gecikmisErtelemeGun)),
        saat,
      );
    }

    return hedef;
  }

  /// Verilen gunun belirtilen saatine sabitler (dakika/saniye sifirlanir).
  static DateTime _saatUygula(DateTime gun, int saat) {
    return DateTime(gun.year, gun.month, gun.day, saat);
  }

  /// Bir maddenin hatirlatmasinin gecikip gecikmedigi.
  /// Arayuzde "gecikmis" rozeti gostermek icin.
  static bool gecikmisMi({
    required HazirlikMaddesi madde,
    required HazirlikDurumu durum,
    DateTime? simdi,
  }) {
    final tamamlanma = durum.tamamlanma(madde.id);
    if (tamamlanma == null) return false;

    final an = simdi ?? DateTime.now();
    return an.isAfter(tamamlanma.add(Duration(days: madde.periyotGun)));
  }

  /// Bir maddenin tamamlanmasinin uzerinden gecen sureyi anlatir.
  static String tamamlanmaMetni({
    required HazirlikMaddesi madde,
    required HazirlikDurumu durum,
    DateTime? simdi,
  }) {
    final tamamlanma = durum.tamamlanma(madde.id);
    if (tamamlanma == null) return 'Henüz yapılmadı';

    final an = simdi ?? DateTime.now();
    final gun = an.difference(tamamlanma).inDays;

    if (gun <= 0) return 'Bugün yapıldı';
    if (gun == 1) return 'Dün yapıldı';
    if (gun < 30) return '$gun gün önce yapıldı';
    if (gun < 365) return '${(gun / 30).round()} ay önce yapıldı';
    return '${(gun / 365).floor()} yıldan uzun süre önce yapıldı';
  }

  /// Tum acik hatirlatmalari yeniden planlar.
  ///
  /// Once hepsi iptal edilip yeniden kuruluyor; boylece kapatilan
  /// hatirlatmalarin eski planlari geride kalmiyor.
  ///
  /// Kac bildirimin planlandigini dondurur.
  static Future<int> yenidenPlanla(HazirlikDurumu durum) async {
    if (!await BildirimServisi.baslat()) return 0;

    var planlanan = 0;

    for (final madde in HazirlikListesi.tumu) {
      // Once eskisini temizle
      await BildirimServisi.iptalEt(madde.bildirimId);

      if (!durum.hatirlatmaAcikMi(madde.id)) continue;

      final ne = sonrakiTarih(madde: madde, durum: durum);
      final oldu = await BildirimServisi.planla(
        id: madde.bildirimId,
        baslik: madde.hatirlatmaBaslik,
        govde: madde.hatirlatmaGovde,
        ne: ne,
      );
      if (oldu) planlanan++;
    }

    return planlanan;
  }

  /// Bildirim kimliklerinin cakisip cakismadigini kontrol eder.
  ///
  /// Kimlikler id.hashCode'dan turetildigi icin teorik olarak cakisabilir;
  /// cakisirsa bir hatirlatma digerinin uzerine yazilir. Test bunu yakalar.
  static bool kimliklerBenzersizMi() {
    final kimlikler = HazirlikListesi.tumu.map((m) => m.bildirimId).toSet();
    return kimlikler.length == HazirlikListesi.tumu.length;
  }
}
