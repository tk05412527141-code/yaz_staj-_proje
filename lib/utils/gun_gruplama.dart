import '../models/deprem.dart';

/// Ayni gune ait depremler.
class GunGrubu {
  /// Grubun tarihi (saat bilgisi sifirlanmis)
  final DateTime gun;

  /// Baslikta gosterilecek metin: "Bugün", "Dün" veya "24 Temmuz"
  final String baslik;

  final List<Deprem> depremler;

  const GunGrubu({
    required this.gun,
    required this.baslik,
    required this.depremler,
  });
}

/// Deprem listesini gunlere ayirir.
///
/// NEDEN?
///   200 kartlik duz bir liste zaman algisini kaybettiriyor. Kullanici
///   "bu dun muydu, gecen hafta miydi?" diye kartlarin icindeki
///   "3 gun once" yazisini okumak zorunda kaliyor.
///
///   Gun basliklari listeyi taranabilir hale getiriyor.
///
/// NOT: Liste zaten tarihe gore sirali geldiginde gruplar da sirali olur.
/// Buyukluge gore siralamada gruplama anlamsizlasacagi icin cagiran taraf
/// bu durumda gruplamayi kullanmamali.
class GunGruplama {
  const GunGruplama._();

  static List<GunGrubu> grupla(List<Deprem> depremler, {DateTime? simdi}) {
    if (depremler.isEmpty) return const [];

    final bugun = _gunBasi(simdi ?? DateTime.now());
    final dun = bugun.subtract(const Duration(days: 1));

    final gruplar = <GunGrubu>[];
    DateTime? aktifGun;
    var aktifListe = <Deprem>[];

    void grubuKapat() {
      if (aktifGun == null || aktifListe.isEmpty) return;
      gruplar.add(GunGrubu(
        gun: aktifGun!,
        baslik: baslikUret(aktifGun!, bugun: bugun, dun: dun),
        depremler: aktifListe,
      ));
    }

    for (final d in depremler) {
      final gun = _gunBasi(d.tarih);
      if (aktifGun == null || gun != aktifGun) {
        grubuKapat();
        aktifGun = gun;
        aktifListe = <Deprem>[];
      }
      aktifListe.add(d);
    }
    grubuKapat();

    return gruplar;
  }

  static DateTime _gunBasi(DateTime t) => DateTime(t.year, t.month, t.day);

  static String baslikUret(
    DateTime gun, {
    required DateTime bugun,
    required DateTime dun,
  }) {
    if (gun == bugun) return 'Bugün';
    if (gun == dun) return 'Dün';

    const aylar = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    final ay = aylar[gun.month - 1];

    // Farkli yildaysa yili da yaz
    if (gun.year != bugun.year) return '${gun.day} $ay ${gun.year}';
    return '${gun.day} $ay';
  }
}
