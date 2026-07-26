// Iki kaynaktan gelen deprem kayitlarinin birlestirilmesi.
//
// Calistirmak icin:  flutter test
//
// Bu mantik risklidir: cok gevsek olursa AYRI depremleri birlestirip
// kayit gizler, cok siki olursa AYNI depremi iki kez gosterir. Ikisi de
// kullaniciyi yaniltir, o yuzden siniri iki taraftan da test ediyoruz.

import 'package:flutter_test/flutter_test.dart';

import 'package:deprem_takip/models/deprem.dart';
import 'package:deprem_takip/services/deprem_servisi.dart';

Deprem d({
  required DateTime tarih,
  double buyukluk = 4.0,
  double enlem = 38.0,
  double boylam = 37.0,
  String kaynak = 'AFAD',
  String yer = 'Test',
}) =>
    Deprem(
      id: '${kaynak}_${tarih.millisecondsSinceEpoch}',
      yer: yer,
      buyukluk: buyukluk,
      derinlik: 10,
      enlem: enlem,
      boylam: boylam,
      tarih: tarih,
      kaynak: kaynak,
    );

void main() {
  final an = DateTime(2026, 7, 26, 12, 0, 0);

  group('Aynı deprem tespiti', () {
    test('Birebir aynı kayıt aynı sayılıyor', () {
      expect(
        DepremServisi.ayniDepremMi(d(tarih: an), d(tarih: an)),
        isTrue,
      );
    });

    test('30 saniye ve 10 km fark: aynı deprem', () {
      // Iki kurum ayni depremi biraz farkli raporlar
      final a = d(tarih: an, enlem: 38.0, boylam: 37.0, kaynak: 'AFAD');
      final b = d(
        tarih: an.add(const Duration(seconds: 30)),
        enlem: 38.05,
        boylam: 37.05,
        kaynak: 'Kandilli',
      );
      expect(DepremServisi.ayniDepremMi(a, b), isTrue);
    });

    test('Zaman farkı toleransın hemen altında: aynı', () {
      final a = d(tarih: an);
      final b = d(tarih: an.add(const Duration(seconds: 119)));
      expect(DepremServisi.ayniDepremMi(a, b), isTrue);
    });

    test('Zaman farkı toleransın üstünde: farklı', () {
      final a = d(tarih: an);
      final b = d(tarih: an.add(const Duration(seconds: 121)));
      expect(DepremServisi.ayniDepremMi(a, b), isFalse);
    });

    test('Aynı anda ama uzak: farklı deprem', () {
      // Ayni saniyede iki ayri bolgede deprem olabilir
      final a = d(tarih: an, enlem: 38.0, boylam: 37.0);
      final b = d(tarih: an, enlem: 40.0, boylam: 29.0); // ~700 km
      expect(DepremServisi.ayniDepremMi(a, b), isFalse);
    });

    test('Yakın ama saatler sonra: farklı deprem (artçı)', () {
      final a = d(tarih: an, enlem: 38.0, boylam: 37.0);
      final b = d(
        tarih: an.add(const Duration(hours: 2)),
        enlem: 38.01,
        boylam: 37.01,
      );
      expect(DepremServisi.ayniDepremMi(a, b), isFalse);
    });

    test('Karşılaştırma simetrik', () {
      final a = d(tarih: an, enlem: 38.0, boylam: 37.0);
      final b = d(
        tarih: an.add(const Duration(seconds: 40)),
        enlem: 38.02,
        boylam: 37.02,
      );
      expect(
        DepremServisi.ayniDepremMi(a, b),
        DepremServisi.ayniDepremMi(b, a),
      );
    });
  });

  group('Birleştirme', () {
    test('Boş listeler sorun çıkarmıyor', () {
      expect(DepremServisi.birlestir(oncelikli: [], ek: []), isEmpty);
    });

    test('Öncelikli boşsa ek liste kullanılıyor', () {
      final ek = [d(tarih: an, kaynak: 'Kandilli')];
      final sonuc = DepremServisi.birlestir(oncelikli: [], ek: ek);
      expect(sonuc.length, 1);
      expect(sonuc.first.kaynak, 'Kandilli');
    });

    test('Ek boşsa öncelikli korunuyor', () {
      final onc = [d(tarih: an, kaynak: 'AFAD')];
      final sonuc = DepremServisi.birlestir(oncelikli: onc, ek: []);
      expect(sonuc.length, 1);
    });

    test('Çakışan kayıt tek kalıyor ve AFAD korunuyor', () {
      final afad = d(tarih: an, kaynak: 'AFAD', yer: 'AFAD kaydı');
      final kandilli = d(
        tarih: an.add(const Duration(seconds: 20)),
        enlem: 38.01,
        boylam: 37.01,
        kaynak: 'Kandilli',
        yer: 'Kandilli kaydı',
      );

      final sonuc = DepremServisi.birlestir(
        oncelikli: [afad],
        ek: [kandilli],
      );

      expect(sonuc.length, 1);
      expect(sonuc.first.kaynak, 'AFAD',
          reason: 'Resmî parametreler korunmalı');
    });

    test('AFAD\'da olmayan yeni kayıt ekleniyor', () {
      // Asil senaryo: AFAD gecikmeli, son saatlerdeki deprem sadece
      // Kandilli'de var
      final afad = [d(tarih: an.subtract(const Duration(hours: 12)))];
      final kandilli = [
        d(
          tarih: an.subtract(const Duration(minutes: 5)),
          buyukluk: 4.6,
          enlem: 39.5,
          boylam: 28.0,
          kaynak: 'Kandilli',
          yer: 'Yeni deprem',
        ),
      ];

      final sonuc = DepremServisi.birlestir(
        oncelikli: afad,
        ek: kandilli,
      );

      expect(sonuc.length, 2);
      expect(sonuc.first.yer, 'Yeni deprem',
          reason: 'En yeni kayıt başta olmalı');
    });

    test('Sonuç tarihe göre yeniden eskiye sıralı', () {
      final sonuc = DepremServisi.birlestir(
        oncelikli: [
          d(tarih: an.subtract(const Duration(hours: 5)), enlem: 36),
          d(tarih: an.subtract(const Duration(hours: 1)), enlem: 40),
        ],
        ek: [
          d(tarih: an.subtract(const Duration(hours: 3)),
              enlem: 41, boylam: 30, kaynak: 'Kandilli'),
        ],
      );

      expect(sonuc.length, 3);
      for (var i = 0; i < sonuc.length - 1; i++) {
        expect(
          sonuc[i].tarih.isAfter(sonuc[i + 1].tarih) ||
              sonuc[i].tarih == sonuc[i + 1].tarih,
          isTrue,
        );
      }
    });

    test('Birden fazla çakışma doğru eleniyor', () {
      final ortak1 = an;
      final ortak2 = an.subtract(const Duration(hours: 3));

      final afad = [
        d(tarih: ortak1, enlem: 38, boylam: 37),
        d(tarih: ortak2, enlem: 39, boylam: 28),
      ];
      final kandilli = [
        // ikisi de cakisan
        d(tarih: ortak1.add(const Duration(seconds: 15)),
            enlem: 38.01, boylam: 37.01, kaynak: 'Kandilli'),
        d(tarih: ortak2.add(const Duration(seconds: 45)),
            enlem: 39.02, boylam: 28.02, kaynak: 'Kandilli'),
        // bu yeni
        d(tarih: an.subtract(const Duration(minutes: 10)),
            enlem: 37, boylam: 35, kaynak: 'Kandilli', yer: 'Tek olan'),
      ];

      final sonuc = DepremServisi.birlestir(
        oncelikli: afad,
        ek: kandilli,
      );

      expect(sonuc.length, 3, reason: '2 çakışma elenmeli, 1 yeni eklenmeli');
      expect(sonuc.where((x) => x.kaynak == 'Kandilli').length, 1);
    });

    test('Hiçbir kayıt kaybolmuyor (çakışma yoksa)', () {
      final afad = List.generate(
        5,
        (i) => d(
          tarih: an.subtract(Duration(days: i + 1)),
          enlem: 36.0 + i,
          boylam: 30.0 + i,
        ),
      );
      final kandilli = List.generate(
        3,
        (i) => d(
          tarih: an.subtract(Duration(hours: i + 1)),
          enlem: 40.0 + i,
          boylam: 26.0 + i,
          kaynak: 'Kandilli',
        ),
      );

      final sonuc =
          DepremServisi.birlestir(oncelikli: afad, ek: kandilli);
      expect(sonuc.length, 8);
    });
  });

  group('Tolerans sabitleri makul mü', () {
    test('Zaman toleransı 1-5 dakika arasında', () {
      expect(DepremServisi.ayniDepremZamanToleransi.inSeconds,
          inInclusiveRange(60, 300));
    });

    test('Mesafe toleransı 20-100 km arasında', () {
      // Cok genis olursa ayri depremler birlesir
      expect(DepremServisi.ayniDepremMesafeKm, inInclusiveRange(20, 100));
    });
  });
}
