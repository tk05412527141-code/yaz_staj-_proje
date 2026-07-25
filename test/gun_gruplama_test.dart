// Liste gruplamasinin testleri.
//
// Calistirmak icin:  flutter test
//
// Gruplama gorunuste basit ama sinir durumlari cok: gece yarisini asan
// kayitlar, yil degisimi, bos liste, tek kayit. Bunlar test edilmezse
// kullanici "Bugün" basligi altinda dunun depremini gorebilir.

import 'package:flutter_test/flutter_test.dart';

import 'package:deprem_takip/models/deprem.dart';
import 'package:deprem_takip/utils/gun_gruplama.dart';

Deprem d(DateTime tarih, {double buyukluk = 3.0}) => Deprem(
      id: tarih.microsecondsSinceEpoch.toString(),
      yer: 'Test',
      buyukluk: buyukluk,
      derinlik: 10,
      enlem: 38,
      boylam: 37,
      tarih: tarih,
      kaynak: 'Test',
    );

void main() {
  final simdi = DateTime(2026, 7, 26, 14, 30);

  group('Temel gruplama', () {
    test('Boş liste boş sonuç verir', () {
      expect(GunGruplama.grupla([], simdi: simdi), isEmpty);
    });

    test('Tek deprem tek grup', () {
      final gruplar = GunGruplama.grupla(
        [d(DateTime(2026, 7, 26, 9))],
        simdi: simdi,
      );
      expect(gruplar.length, 1);
      expect(gruplar.first.depremler.length, 1);
    });

    test('Aynı günün depremleri tek grupta toplanır', () {
      final gruplar = GunGruplama.grupla([
        d(DateTime(2026, 7, 26, 23, 59)),
        d(DateTime(2026, 7, 26, 12, 0)),
        d(DateTime(2026, 7, 26, 0, 1)),
      ], simdi: simdi);

      expect(gruplar.length, 1);
      expect(gruplar.first.depremler.length, 3);
    });

    test('Farklı günler ayrı gruplara düşer', () {
      final gruplar = GunGruplama.grupla([
        d(DateTime(2026, 7, 26, 10)),
        d(DateTime(2026, 7, 25, 23)),
        d(DateTime(2026, 7, 24, 5)),
      ], simdi: simdi);

      expect(gruplar.length, 3);
      expect(gruplar.map((g) => g.depremler.length), [1, 1, 1]);
    });

    test('Gece yarısı sınırı doğru ayrılıyor', () {
      // 23:59 ve 00:01 ayrı günler olmalı
      final gruplar = GunGruplama.grupla([
        d(DateTime(2026, 7, 26, 0, 1)),
        d(DateTime(2026, 7, 25, 23, 59)),
      ], simdi: simdi);

      expect(gruplar.length, 2);
    });

    test('Hiçbir deprem kaybolmaz', () {
      final liste = [
        d(DateTime(2026, 7, 26, 10)),
        d(DateTime(2026, 7, 26, 9)),
        d(DateTime(2026, 7, 25, 8)),
        d(DateTime(2026, 7, 20, 7)),
        d(DateTime(2025, 12, 31, 6)),
      ];
      final gruplar = GunGruplama.grupla(liste, simdi: simdi);
      final toplam =
          gruplar.fold<int>(0, (t, g) => t + g.depremler.length);
      expect(toplam, liste.length);
    });

    test('Grup içi sıra korunur', () {
      final ilk = d(DateTime(2026, 7, 26, 10));
      final ikinci = d(DateTime(2026, 7, 26, 9));
      final gruplar = GunGruplama.grupla([ilk, ikinci], simdi: simdi);
      expect(gruplar.first.depremler[0].tarih, ilk.tarih);
      expect(gruplar.first.depremler[1].tarih, ikinci.tarih);
    });
  });

  group('Başlık metinleri', () {
    String baslikIcin(DateTime tarih) =>
        GunGruplama.grupla([d(tarih)], simdi: simdi).first.baslik;

    test('Bugün', () {
      expect(baslikIcin(DateTime(2026, 7, 26, 3)), 'Bugün');
    });

    test('Dün', () {
      expect(baslikIcin(DateTime(2026, 7, 25, 20)), 'Dün');
    });

    test('Aynı yıl içindeki eski tarih ay adıyla', () {
      expect(baslikIcin(DateTime(2026, 7, 20, 8)), '20 Temmuz');
    });

    test('Farklı yıldaki tarih yıl da içerir', () {
      expect(baslikIcin(DateTime(2025, 12, 31, 8)), '31 Aralık 2025');
    });

    test('Tüm ay adları Türkçe ve dolu', () {
      for (var ay = 1; ay <= 12; ay++) {
        final baslik = GunGruplama.baslikUret(
          DateTime(2026, ay, 15),
          bugun: DateTime(2026, 7, 26),
          dun: DateTime(2026, 7, 25),
        );
        expect(baslik, isNotEmpty);
        expect(baslik, contains('15'));
      }
    });

    test('Ay sınırlarında hata yok (Ocak ve Aralık)', () {
      expect(
        GunGruplama.baslikUret(DateTime(2026, 1, 1),
            bugun: DateTime(2026, 7, 26), dun: DateTime(2026, 7, 25)),
        '1 Ocak',
      );
      expect(
        GunGruplama.baslikUret(DateTime(2026, 12, 31),
            bugun: DateTime(2026, 7, 26), dun: DateTime(2026, 7, 25)),
        '31 Aralık',
      );
    });
  });

  group('Yıl geçişi', () {
    test('31 Aralık / 1 Ocak ayrı gruplar', () {
      final yilbasi = DateTime(2026, 1, 1, 12);
      final gruplar = GunGruplama.grupla([
        d(DateTime(2026, 1, 1, 1)),
        d(DateTime(2025, 12, 31, 23)),
      ], simdi: yilbasi);

      expect(gruplar.length, 2);
      expect(gruplar[0].baslik, 'Bugün');
      expect(gruplar[1].baslik, 'Dün');
    });
  });
}
