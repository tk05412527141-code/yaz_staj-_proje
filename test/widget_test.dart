// Deprem modelinin JSON cozumleme testleri.
//
// Calistirmak icin:  flutter test
//
// Neden arayuz yerine model test ediliyor?
//   Arayuz testi internetten veri cekmeyi gerektirirdi ve internetsiz
//   ortamda basarisiz olurdu. Buradaki mantik ise projenin en kritik ve
//   en hataya acik kismi: iki farkli kurumun farkli formatlarini tek
//   modele cevirmek.
//
// Kullanilan ornek veriler API'lerden gercekten donen yanitlardir.

import 'package:flutter_test/flutter_test.dart';

import 'package:deprem_takip/models/deprem.dart';

void main() {
  group('AFAD verisi', () {
    // AFAD tum sayilari METIN olarak gonderir: "magnitude": "3.7"
    final ornek = <String, dynamic>{
      'eventID': '723876',
      'location': 'Kalar, Süleymaniye (Irak)',
      'latitude': '34.92383',
      'longitude': '45.0975',
      'depth': '7',
      'magnitude': '3.7',
      'date': '2026-07-25T07:40:15',
    };

    test('metin olarak gelen sayilar dogru cevriliyor', () {
      final d = Deprem.afaddan(ornek);
      expect(d.buyukluk, 3.7);
      expect(d.derinlik, 7.0); // tam sayi gelen deger de calismali
      expect(d.enlem, closeTo(34.9238, 0.001));
      expect(d.boylam, closeTo(45.0975, 0.001));
    });

    test('tarih dogru cozumleniyor', () {
      final d = Deprem.afaddan(ornek);
      expect(d.tarih, DateTime(2026, 7, 25, 7, 40, 15));
    });

    test('kaynak adi AFAD olarak isaretleniyor', () {
      expect(Deprem.afaddan(ornek).kaynak, 'AFAD');
    });
  });

  group('Kandilli verisi', () {
    // DIKKAT: koordinatlar GeoJSON sirasinda gelir -> [boylam, enlem]
    final ornek = <String, dynamic>{
      'earthquake_id': 'P68bB3iEe9UTA',
      'title': 'SALMANIPAK-PAZARCIK (KAHRAMANMARAS)',
      'mag': 1.9,
      'depth': 4.6,
      'geojson': {
        'type': 'Point',
        'coordinates': [37.1942, 37.412], // [boylam, enlem]
      },
      'date_time': '2026-07-25 23:49:05',
    };

    test('GeoJSON koordinat sirasi dogru okunuyor', () {
      final d = Deprem.kandilliden(ornek);
      // Kahramanmaras yaklasik 37.4 K, 37.2 D
      expect(d.enlem, closeTo(37.412, 0.001));
      expect(d.boylam, closeTo(37.1942, 0.001));
    });

    test('bosluklu tarih formati cozumleniyor', () {
      final d = Deprem.kandilliden(ornek);
      expect(d.tarih, DateTime(2026, 7, 25, 23, 49, 5));
    });

    test('kaynak adi Kandilli olarak isaretleniyor', () {
      expect(Deprem.kandilliden(ornek).kaynak, 'Kandilli');
    });
  });

  group('Bozuk veriye dayaniklilik', () {
    test('bos JSON cokme yaratmiyor', () {
      final d = Deprem.afaddan({});
      expect(d.buyukluk, 0);
      expect(d.derinlik, 0);
      expect(d.yer, 'Bilinmeyen konum');
    });

    test('sayi yerine metin gelirse 0 kullaniliyor', () {
      final d = Deprem.afaddan({'magnitude': 'abc', 'depth': null});
      expect(d.buyukluk, 0);
      expect(d.derinlik, 0);
    });

    test('gecersiz tarih uygulamayi durdurmuyor', () {
      final d = Deprem.afaddan({'date': 'gecersiz'});
      expect(d.tarih, isA<DateTime>());
    });

    test('eksik koordinat 0 olarak ele aliniyor', () {
      final d = Deprem.kandilliden({
        'geojson': {'coordinates': <num>[]},
      });
      expect(d.enlem, 0);
      expect(d.boylam, 0);
    });

    test('geojson alani hic yoksa cokmuyor', () {
      final d = Deprem.kandilliden({'mag': 2.0});
      expect(d.enlem, 0);
      expect(d.buyukluk, 2.0);
    });
  });

  group('Goruntuleme yardimcilari', () {
    final d = Deprem(
      id: '1',
      yer: 'Akçadağ (Malatya)',
      buyukluk: 4.1,
      derinlik: 11.46,
      enlem: 38.35067,
      boylam: 37.86183,
      tarih: DateTime(2026, 7, 23, 7, 26),
      kaynak: 'AFAD',
    );

    test('tarih okunabilir bicimde yazdiriliyor', () {
      expect(d.tarihMetni, '23.07.2026 07:26');
    });

    test('koordinat metni 4 basamakli', () {
      expect(d.koordinatMetni, '38.3507, 37.8618');
    });

    test('paylasim metni tum alanlari iceriyor', () {
      final metin = d.paylasimMetni;
      expect(metin, contains('Akçadağ'));
      expect(metin, contains('4.1'));
      expect(metin, contains('11.5'));
      expect(metin, contains('AFAD'));
    });

    test('gecen sure metni bos degil', () {
      expect(d.gecenSure, isNotEmpty);
    });
  });
}
