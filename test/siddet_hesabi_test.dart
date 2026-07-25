// Mesafe ve tahmini sarsinti siddeti hesaplarinin testleri.
//
// Calistirmak icin:  flutter test
//
// Bu dosya projenin en kritik bolumunu koruyor: kullaniciya "bu depremi
// hissedeceksiniz / hissetmeyeceksiniz" demek. Yanlis hesap, yaniltici
// bilgi demek; bu yuzden hem bilinen depremlerle hem de sinir durumlariyla
// test ediliyor.

import 'package:flutter_test/flutter_test.dart';

import 'package:deprem_takip/utils/siddet_hesabi.dart';

void main() {
  group('Mesafe hesabi (haversine)', () {
    test('İstanbul – Ankara yaklaşık 350 km', () {
      final m = SiddetHesabi.mesafeKm(41.0082, 28.9784, 39.9334, 32.8597);
      expect(m, closeTo(350, 15));
    });

    test('İstanbul – İzmir yaklaşık 330 km', () {
      final m = SiddetHesabi.mesafeKm(41.0082, 28.9784, 38.4237, 27.1428);
      expect(m, closeTo(328, 15));
    });

    test('Aynı nokta 0 km', () {
      expect(SiddetHesabi.mesafeKm(39.0, 35.0, 39.0, 35.0), closeTo(0, 0.001));
    });

    test('Mesafe simetrik', () {
      final ileri = SiddetHesabi.mesafeKm(41.0, 29.0, 37.0, 35.0);
      final geri = SiddetHesabi.mesafeKm(37.0, 35.0, 41.0, 29.0);
      expect(ileri, closeTo(geri, 0.001));
    });
  });

  group('Şiddet tahmini – bilinen senaryolar', () {
    SiddetSonucu senaryo(double buyukluk, double mesafeDerece, double derinlik) {
      // Enlem farkı üzerinden mesafe kurgulamak yerine doğrudan
      // iki nokta veriyoruz; 1 derece enlem ≈ 111 km
      return SiddetHesabi.hesapla(
        depremEnlem: 38.0,
        depremBoylam: 37.0,
        derinlikKm: derinlik,
        buyukluk: buyukluk,
        noktaEnlem: 38.0 + mesafeDerece,
        noktaBoylam: 37.0,
      );
    }

    test('Büyük deprem merkez üstünde şiddetli', () {
      final s = senaryo(7.8, 0, 8.6);
      expect(s.seviye, HissedilirlikSeviyesi.siddetli);
      expect(s.mmi, greaterThan(7.5));
    });

    test('Küçük deprem çok uzakta hissedilmez', () {
      final s = senaryo(4.1, 3.0, 11.5); // ~333 km
      expect(s.seviye, HissedilirlikSeviyesi.hissedilmez);
    });

    test('Orta deprem yakında hissedilir', () {
      final s = senaryo(5.0, 0.27, 10); // ~30 km
      expect(s.seviye.hissedilir, isTrue);
    });

    test('Çok küçük deprem orta mesafede hissedilmez', () {
      final s = senaryo(2.0, 0.45, 5); // ~50 km
      expect(s.seviye, HissedilirlikSeviyesi.hissedilmez);
    });
  });

  group('Şiddet tahmini – matematiksel tutarlılık', () {
    double mmiAt(double buyukluk, double dereceFark) {
      return SiddetHesabi.hesapla(
        depremEnlem: 38.0,
        depremBoylam: 37.0,
        derinlikKm: 10,
        buyukluk: buyukluk,
        noktaEnlem: 38.0 + dereceFark,
        noktaBoylam: 37.0,
      ).mmi;
    }

    test('Mesafe arttıkça şiddet azalır', () {
      final mesafeler = [0.0, 0.1, 0.3, 0.9, 1.8, 3.6];
      var onceki = 99.0;
      for (final d in mesafeler) {
        final v = mmiAt(6.0, d);
        expect(v, lessThanOrEqualTo(onceki),
            reason: '$d derecede şiddet artmış olmamalı');
        onceki = v;
      }
    });

    test('Büyüklük arttıkça şiddet artar', () {
      var onceki = -99.0;
      for (final m in [3.0, 4.0, 5.0, 6.0, 7.0]) {
        final v = mmiAt(m, 0.45);
        expect(v, greaterThanOrEqualTo(onceki));
        onceki = v;
      }
    });

    test('Derinlik arttıkça yüzeydeki şiddet azalır', () {
      double mmiDerinlik(double derinlik) => SiddetHesabi.hesapla(
            depremEnlem: 38.0,
            depremBoylam: 37.0,
            derinlikKm: derinlik,
            buyukluk: 5.5,
            noktaEnlem: 38.0,
            noktaBoylam: 37.0,
          ).mmi;

      expect(mmiDerinlik(5), greaterThan(mmiDerinlik(50)));
      expect(mmiDerinlik(50), greaterThan(mmiDerinlik(150)));
    });
  });

  group('Sınır durumları', () {
    test('MMI 1 ile 12 arasında kalır', () {
      final kucuk = SiddetHesabi.hesapla(
        depremEnlem: 38, depremBoylam: 37, derinlikKm: 10,
        buyukluk: 0.5, noktaEnlem: 45, noktaBoylam: 45,
      );
      expect(kucuk.mmi, greaterThanOrEqualTo(1.0));

      final buyuk = SiddetHesabi.hesapla(
        depremEnlem: 38, depremBoylam: 37, derinlikKm: 1,
        buyukluk: 9.5, noktaEnlem: 38, noktaBoylam: 37,
      );
      expect(buyuk.mmi, lessThanOrEqualTo(12.0));
    });

    test('Sıfır derinlik ve sıfır mesafe çökmeye yol açmaz', () {
      final s = SiddetHesabi.hesapla(
        depremEnlem: 38, depremBoylam: 37, derinlikKm: 0,
        buyukluk: 5.0, noktaEnlem: 38, noktaBoylam: 37,
      );
      expect(s.mmi.isFinite, isTrue);
      expect(s.mmi, greaterThan(0));
    });

    test('Negatif derinlik yok sayılır', () {
      final s = SiddetHesabi.hesapla(
        depremEnlem: 38, depremBoylam: 37, derinlikKm: -5,
        buyukluk: 5.0, noktaEnlem: 38, noktaBoylam: 37,
      );
      expect(s.mmi.isFinite, isTrue);
    });
  });

  group('Güvenilirlik bayrağı', () {
    SiddetSonucu s(double buyukluk, double dereceFark) => SiddetHesabi.hesapla(
          depremEnlem: 38, depremBoylam: 37, derinlikKm: 10,
          buyukluk: buyukluk, noktaEnlem: 38 + dereceFark, noktaBoylam: 37,
        );

    test('Model aralığındaki deprem güvenilir sayılır', () {
      expect(s(6.0, 0.18).guvenilir, isTrue); // M6.0, ~20 km
    });

    test('M5 altı güvenilir sayılmaz (ekstrapolasyon)', () {
      expect(s(3.0, 0.18).guvenilir, isFalse);
    });

    test('300 km üstü güvenilir sayılmaz', () {
      expect(s(7.0, 3.6).guvenilir, isFalse); // ~400 km
    });
  });

  group('Seviye eşikleri', () {
    test('Eşikler doğru kategoriye düşüyor', () {
      expect(SiddetHesabi.seviyeBul(1.5), HissedilirlikSeviyesi.hissedilmez);
      expect(SiddetHesabi.seviyeBul(2.0), HissedilirlikSeviyesi.zor);
      expect(SiddetHesabi.seviyeBul(3.5), HissedilirlikSeviyesi.hafif);
      expect(SiddetHesabi.seviyeBul(4.5), HissedilirlikSeviyesi.belirgin);
      expect(SiddetHesabi.seviyeBul(5.5), HissedilirlikSeviyesi.guclu);
      expect(SiddetHesabi.seviyeBul(6.5), HissedilirlikSeviyesi.cokGuclu);
      expect(SiddetHesabi.seviyeBul(8.0), HissedilirlikSeviyesi.siddetli);
    });

    test('Sadece "hissedilmez" hissedilir değil', () {
      for (final seviye in HissedilirlikSeviyesi.values) {
        expect(
          seviye.hissedilir,
          seviye != HissedilirlikSeviyesi.hissedilmez,
        );
      }
    });

    test('Her seviyenin etiketi ve açıklaması dolu', () {
      for (final seviye in HissedilirlikSeviyesi.values) {
        expect(seviye.etiket, isNotEmpty);
        expect(seviye.aciklama, isNotEmpty);
      }
    });
  });
}
