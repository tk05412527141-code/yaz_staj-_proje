// Hazirlik hatirlatmalarinin tarih hesabi ve saklama testleri.
//
// Calistirmak icin:  flutter test
//
// Bildirim zamanlamasinda hata, kullanicinin hic hatirlatma almamasi
// veya gecmise bildirim planlanmaya calisilmasi demek. Ozellikle
// "periyodu coktan gecmis" durumu sessizce basarisiz olabilir.

import 'package:flutter_test/flutter_test.dart';

import 'package:deprem_takip/models/hazirlik_maddesi.dart';
import 'package:deprem_takip/services/hatirlatma_planlayici.dart';

void main() {
  final simdi = DateTime(2026, 7, 26, 14, 30);
  final canta = HazirlikListesi.bul('canta')!; // 90 gun
  final belge = HazirlikListesi.bul('belge')!; // 365 gun

  group('Hazırlık listesi tutarlılığı', () {
    test('Liste boş değil', () {
      expect(HazirlikListesi.tumu, isNotEmpty);
    });

    test('Madde id\'leri benzersiz', () {
      final idler = HazirlikListesi.tumu.map((m) => m.id).toSet();
      expect(idler.length, HazirlikListesi.tumu.length);
    });

    test('Bildirim kimlikleri benzersiz', () {
      // Çakışırsa bir hatırlatma diğerini ezer ve kullanıcı sessizce
      // bir hatırlatmayı hiç almaz.
      expect(HatirlatmaPlanlayici.kimliklerBenzersizMi(), isTrue);
    });

    test('Her maddenin metinleri dolu', () {
      for (final m in HazirlikListesi.tumu) {
        expect(m.baslik, isNotEmpty);
        expect(m.aciklama, isNotEmpty);
        expect(m.hatirlatmaBaslik, isNotEmpty);
        expect(m.hatirlatmaGovde, isNotEmpty);
        expect(m.periyotGun, greaterThan(0));
      }
    });

    test('bul() bilinmeyen id için null döner', () {
      expect(HazirlikListesi.bul('olmayan'), isNull);
    });
  });

  group('Sonraki hatırlatma tarihi', () {
    test('Hiç tamamlanmamışsa birkaç gün sonra', () {
      const durum = HazirlikDurumu();
      final ne = HatirlatmaPlanlayici.sonrakiTarih(
        madde: canta,
        durum: durum,
        simdi: simdi,
      );

      expect(ne.isAfter(simdi), isTrue);
      expect(
        ne.difference(simdi).inDays,
        lessThanOrEqualTo(HatirlatmaPlanlayici.ilkDurtmeGun),
      );
    });

    test('Tamamlanmışsa periyot kadar sonra', () {
      final durum = HazirlikDurumu(
        tamamlanmaTarihleri: {canta.id: DateTime(2026, 7, 20)},
      );
      final ne = HatirlatmaPlanlayici.sonrakiTarih(
        madde: canta,
        durum: durum,
        simdi: simdi,
      );

      // 20 Temmuz + 90 gün = 18 Ekim
      expect(ne.year, 2026);
      expect(ne.month, 10);
      expect(ne.day, 18);
    });

    test('Periyot çoktan geçmişse geçmişe planlanmaz', () {
      // 2 yıl önce tamamlanmış: hedef tarih çoktan geçti
      final durum = HazirlikDurumu(
        tamamlanmaTarihleri: {canta.id: DateTime(2024, 1, 1)},
      );
      final ne = HatirlatmaPlanlayici.sonrakiTarih(
        madde: canta,
        durum: durum,
        simdi: simdi,
      );

      expect(ne.isAfter(simdi), isTrue,
          reason: 'Geçmiş bir tarihe bildirim planlanamaz');
    });

    test('Hatırlatma saati uygulanıyor', () {
      const durum = HazirlikDurumu(hatirlatmaSaati: 19);
      final ne = HatirlatmaPlanlayici.sonrakiTarih(
        madde: canta,
        durum: durum,
        simdi: simdi,
      );

      expect(ne.hour, 19);
      expect(ne.minute, 0);
      expect(ne.second, 0);
    });

    test('Farklı periyotlar farklı tarihler üretir', () {
      final durum = HazirlikDurumu(
        tamamlanmaTarihleri: {
          canta.id: DateTime(2026, 7, 20),
          belge.id: DateTime(2026, 7, 20),
        },
      );
      final cantaNe = HatirlatmaPlanlayici.sonrakiTarih(
          madde: canta, durum: durum, simdi: simdi);
      final belgeNe = HatirlatmaPlanlayici.sonrakiTarih(
          madde: belge, durum: durum, simdi: simdi);

      expect(belgeNe.isAfter(cantaNe), isTrue,
          reason: '365 günlük periyot 90 günlükten sonra gelmeli');
    });

    test('Tüm maddeler için gelecekte bir tarih üretilir', () {
      const durum = HazirlikDurumu();
      for (final m in HazirlikListesi.tumu) {
        final ne = HatirlatmaPlanlayici.sonrakiTarih(
            madde: m, durum: durum, simdi: simdi);
        expect(ne.isAfter(simdi), isTrue, reason: '${m.id} için geçmiş tarih');
      }
    });
  });

  group('Gecikmiş kontrolü', () {
    test('Tamamlanmamış madde gecikmiş sayılmaz', () {
      const durum = HazirlikDurumu();
      expect(
        HatirlatmaPlanlayici.gecikmisMi(
            madde: canta, durum: durum, simdi: simdi),
        isFalse,
      );
    });

    test('Yeni tamamlanmış madde gecikmiş değil', () {
      final durum = HazirlikDurumu(
        tamamlanmaTarihleri: {canta.id: DateTime(2026, 7, 20)},
      );
      expect(
        HatirlatmaPlanlayici.gecikmisMi(
            madde: canta, durum: durum, simdi: simdi),
        isFalse,
      );
    });

    test('Periyodu aşmış madde gecikmiş', () {
      final durum = HazirlikDurumu(
        tamamlanmaTarihleri: {canta.id: DateTime(2025, 1, 1)},
      );
      expect(
        HatirlatmaPlanlayici.gecikmisMi(
            madde: canta, durum: durum, simdi: simdi),
        isTrue,
      );
    });
  });

  group('Tamamlanma metni', () {
    String metin(DateTime? tarih) => HatirlatmaPlanlayici.tamamlanmaMetni(
          madde: canta,
          durum: tarih == null
              ? const HazirlikDurumu()
              : HazirlikDurumu(tamamlanmaTarihleri: {canta.id: tarih}),
          simdi: simdi,
        );

    test('Hiç yapılmadıysa', () {
      expect(metin(null), 'Henüz yapılmadı');
    });

    test('Bugün yapıldıysa', () {
      expect(metin(DateTime(2026, 7, 26, 9)), 'Bugün yapıldı');
    });

    test('Dün yapıldıysa', () {
      expect(metin(DateTime(2026, 7, 25, 9)), 'Dün yapıldı');
    });

    test('Birkaç gün önce', () {
      expect(metin(DateTime(2026, 7, 20, 9)), contains('gün önce'));
    });

    test('Aylar önce', () {
      expect(metin(DateTime(2026, 3, 1)), contains('ay önce'));
    });

    test('Bir yıldan uzun süre önce', () {
      expect(metin(DateTime(2024, 1, 1)), contains('yıldan uzun'));
    });
  });

  group('Hazırlık durumu saklama', () {
    test('Kodlanıp çözülünce aynı kalıyor', () {
      final orijinal = HazirlikDurumu(
        tamamlanmaTarihleri: {
          'canta': DateTime(2026, 7, 20, 10, 30),
          'belge': DateTime(2026, 1, 5),
        },
        acikHatirlatmalar: {'canta', 'tatbikat'},
        hatirlatmaSaati: 19,
      );

      final geri = HazirlikDurumu.coz(orijinal.kodla());

      expect(geri.tamamlanmaTarihleri.length, 2);
      expect(geri.tamamlanma('canta'), DateTime(2026, 7, 20, 10, 30));
      expect(geri.acikHatirlatmalar, {'canta', 'tatbikat'});
      expect(geri.hatirlatmaSaati, 19);
    });

    test('Boş girdi varsayılan durum döner', () {
      expect(HazirlikDurumu.coz(null).tamamlananSayisi, 0);
      expect(HazirlikDurumu.coz('').hatirlatmaSaati, 10);
    });

    test('Bozuk JSON çökme yaratmaz', () {
      final d = HazirlikDurumu.coz('{bozuk json');
      expect(d.tamamlananSayisi, 0);
      expect(d.acikHatirlatmalar, isEmpty);
    });

    test('Geçersiz saat değeri varsayılana düşer', () {
      final d = HazirlikDurumu.coz('{"saat": 99}');
      expect(d.hatirlatmaSaati, 10);
    });

    test('Bozuk tarih kayıtları atlanır', () {
      final d = HazirlikDurumu.coz(
        '{"tamamlanma": {"canta": "gecersiz", "belge": "2026-07-20T00:00:00"}}',
      );
      expect(d.tamamlanmaTarihleri.length, 1);
      expect(d.tamamlandiMi('belge'), isTrue);
    });

    test('İlerleme oranı doğru hesaplanıyor', () {
      final tumIdler = HazirlikListesi.tumu.map((m) => m.id).toList();
      final yarisi = <String, DateTime>{};
      for (var i = 0; i < tumIdler.length; i++) {
        if (i.isEven) yarisi[tumIdler[i]] = simdi;
      }
      final d = HazirlikDurumu(tamamlanmaTarihleri: yarisi);
      expect(d.ilerleme, closeTo(yarisi.length / tumIdler.length, 0.001));
      expect(d.ilerleme, inInclusiveRange(0.0, 1.0));
    });
  });
}
