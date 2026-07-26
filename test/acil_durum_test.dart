// Acil durum kisileri, telefon bicimleri ve mesaj olusturma testleri.
//
// Calistirmak icin:  flutter test
//
// Bu bolum acil durumda kullanilacagi icin sessiz hatalar kabul edilemez:
// yanlis bicimlenmis bir numara, mesajin hic gitmemesi demek.

import 'package:flutter_test/flutter_test.dart';

import 'package:deprem_takip/models/acil_kisi.dart';
import 'package:deprem_takip/services/acil_durum_servisi.dart';
import 'package:deprem_takip/services/konum_servisi.dart';

void main() {
  group('Telefon temizleme', () {
    test('Boşluk ve noktalama atılıyor', () {
      expect(AcilKisi.telefonTemizle('0555 111 22 33'), '05551112233');
      expect(AcilKisi.telefonTemizle('(0555) 111-22-33'), '05551112233');
    });

    test('Baştaki + korunuyor', () {
      expect(AcilKisi.telefonTemizle('+90 555 111 22 33'), '+905551112233');
    });

    test('Ortadaki + atılıyor', () {
      // Sadece bastaki + anlamli; ortada olan yazim hatasidir
      expect(AcilKisi.telefonTemizle('0555+1112233'), '05551112233');
    });

    test('Harfler atılıyor', () {
      expect(AcilKisi.telefonTemizle('0555abc1112233'), '05551112233');
    });

    test('Boş girdi boş sonuç', () {
      expect(AcilKisi.telefonTemizle(''), '');
    });
  });

  group('Telefon doğrulama', () {
    test('Geçerli Türkiye cep numaraları', () {
      expect(AcilKisi.telefonGecerliMi('0555 111 22 33'), isTrue);
      expect(AcilKisi.telefonGecerliMi('5551112233'), isTrue);
      expect(AcilKisi.telefonGecerliMi('+90 555 111 22 33'), isTrue);
    });

    test('Sabit hat ve kısa numaralar kabul ediliyor', () {
      // Cok siki dogrulama yapmiyoruz: kullanici sabit hat girebilir
      expect(AcilKisi.telefonGecerliMi('0212 111 22 33'), isTrue);
      expect(AcilKisi.telefonGecerliMi('1122334'), isTrue);
    });

    test('Boş ve çok kısa numaralar reddediliyor', () {
      expect(AcilKisi.telefonGecerliMi(''), isFalse);
      expect(AcilKisi.telefonGecerliMi('123'), isFalse);
      expect(AcilKisi.telefonGecerliMi('abc'), isFalse);
    });

    test('Aşırı uzun numara reddediliyor', () {
      expect(AcilKisi.telefonGecerliMi('1' * 20), isFalse);
    });
  });

  group('WhatsApp numara biçimi', () {
    AcilKisi kisi(String tel) =>
        AcilKisi(id: '1', ad: 'Test', telefon: tel);

    test('Yerel biçim ülke koduna çevriliyor', () {
      expect(kisi('0555 111 22 33').whatsappTelefon, '905551112233');
    });

    test('Ülke kodlu biçim korunuyor', () {
      expect(kisi('+90 555 111 22 33').whatsappTelefon, '905551112233');
    });

    test('Kodsuz 10 hane Türkiye varsayılıyor', () {
      expect(kisi('5551112233').whatsappTelefon, '905551112233');
    });

    test('Sonuçta + işareti kalmıyor', () {
      // wa.me baglantisi + kabul etmiyor
      expect(kisi('+905551112233').whatsappTelefon, isNot(contains('+')));
    });
  });

  group('Görüntülenen telefon biçimi', () {
    AcilKisi kisi(String tel) =>
        AcilKisi(id: '1', ad: 'Test', telefon: tel);

    test('Yerel biçim gruplanıyor', () {
      expect(kisi('05551112233').gosterimTelefon, '0555 111 22 33');
    });

    test('Ülke kodlu numara yerel biçimde gösteriliyor', () {
      expect(kisi('+905551112233').gosterimTelefon, '0555 111 22 33');
    });

    test('Tanınmayan biçim olduğu gibi gösteriliyor', () {
      expect(kisi('1122334').gosterimTelefon, '1122334');
    });
  });

  group('Kişi saklama', () {
    test('Kodlanıp çözülünce aynı kalıyor', () {
      final liste = [
        const AcilKisi(
            id: '1', ad: 'Ayşe', telefon: '05551112233', iliski: 'Anne'),
        const AcilKisi(id: '2', ad: 'Mehmet', telefon: '+905559998877'),
      ];

      final geri = AcilKisi.listeyiCoz(AcilKisi.listeyiKodla(liste));

      expect(geri.length, 2);
      expect(geri[0].ad, 'Ayşe');
      expect(geri[0].iliski, 'Anne');
      expect(geri[1].telefon, '+905559998877');
      expect(geri[1].iliski, '');
    });

    test('Boş girdi boş liste', () {
      expect(AcilKisi.listeyiCoz(null), isEmpty);
      expect(AcilKisi.listeyiCoz(''), isEmpty);
    });

    test('Bozuk JSON çökme yaratmaz', () {
      expect(AcilKisi.listeyiCoz('{bozuk'), isEmpty);
    });

    test('Telefonu boş kayıtlar atlanıyor', () {
      // Telefonsuz bir acil kisi ise yaramaz, saklamanin anlami yok
      final geri = AcilKisi.listeyiCoz(
        '[{"id":"1","ad":"Test","telefon":""},'
        '{"id":"2","ad":"Geçerli","telefon":"05551112233"}]',
      );
      expect(geri.length, 1);
      expect(geri.first.ad, 'Geçerli');
    });

    test('Eksik alanlı kayıtlar atlanıyor', () {
      final geri = AcilKisi.listeyiCoz('[{"id":"1"},{"ad":"Sadece ad"}]');
      expect(geri, isEmpty);
    });
  });

  group('Acil durum mesajı', () {
    const gpsKonum = KonumSonucu(
      enlem: 39.9334,
      boylam: 32.8597,
      kaynak: KonumKaynagi.gps,
      dogrulukM: 12,
    );

    test('Konumlu mesaj koordinat ve bağlantı içeriyor', () {
      final m = AcilDurumServisi.mesajOlustur(konum: gpsKonum);
      expect(m, contains('ACİL'));
      expect(m, contains('39.93'));
      expect(m, contains('32.85'));
      expect(m, contains('http'));
    });

    test('Konum yoksa mesaj yine üretiliyor', () {
      // Konum alinamamasi mesajin gitmemesine sebep OLMAMALI
      final m = AcilDurumServisi.mesajOlustur(
        konum: const KonumSonucu(kaynak: KonumKaynagi.yok),
      );
      expect(m, contains('ACİL'));
      expect(m, contains('Konum alınamadı'));
    });

    test('Kayıtlı yer konumu mesajda belirtiliyor', () {
      // Alici, koordinatin anlik GPS olmadigini bilmeli
      final m = AcilDurumServisi.mesajOlustur(
        konum: const KonumSonucu(
          enlem: 39.9,
          boylam: 32.8,
          kaynak: KonumKaynagi.kayitliYer,
        ),
      );
      expect(m, contains('Kayıtlı adres'));
    });

    test('Son bilinen konum mesajda belirtiliyor', () {
      final m = AcilDurumServisi.mesajOlustur(
        konum: const KonumSonucu(
          enlem: 39.9,
          boylam: 32.8,
          kaynak: KonumKaynagi.sonBilinen,
        ),
      );
      expect(m, contains('Son bilinen'));
    });

    test('Ek not mesaja ekleniyor', () {
      final m = AcilDurumServisi.mesajOlustur(
        konum: gpsKonum,
        ekNot: 'Binada mahsur kaldım',
      );
      expect(m, contains('Binada mahsur kaldım'));
    });

    test('Mesaj makul uzunlukta', () {
      // Cok uzun SMS bolunur ve gecikir
      final m = AcilDurumServisi.mesajOlustur(konum: gpsKonum);
      expect(m.length, lessThan(320));
    });

    test('İyiyim mesajı acil ifadesi içermiyor', () {
      final m = AcilDurumServisi.iyiyimMesajiOlustur(konum: gpsKonum);
      expect(m, contains('İyiyim'));
      expect(m.contains('ACİL'), isFalse);
    });
  });

  group('Konum sonucu', () {
    test('Koordinat yoksa varMi false', () {
      const k = KonumSonucu(kaynak: KonumKaynagi.yok);
      expect(k.varMi, isFalse);
      expect(k.koordinatMetni, '—');
      expect(k.haritaBaglantisi, isEmpty);
    });

    test('Koordinat varsa bağlantı üretiliyor', () {
      const k = KonumSonucu(
        enlem: 39.9334,
        boylam: 32.8597,
        kaynak: KonumKaynagi.gps,
      );
      expect(k.varMi, isTrue);
      expect(k.haritaBaglantisi, contains('39.9334'));
      expect(k.haritaBaglantisi, startsWith('https://'));
    });

    test('Her kaynağın etiketi dolu', () {
      for (final k in KonumKaynagi.values) {
        expect(k.etiket, isNotEmpty);
      }
    });
  });
}
