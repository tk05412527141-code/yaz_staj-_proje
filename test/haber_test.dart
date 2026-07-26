// Haber filtreleme testleri.
//
// Calistirmak icin:  flutter test
//
// Filtreler bu ozelligin kalbi: gevsek olursa alakasiz haber gorunur,
// siki olursa gercek deprem haberi gizlenir. Ikisi de kotu.

import 'package:flutter_test/flutter_test.dart';

import 'package:deprem_takip/models/haber.dart';

Haber h({
  String baslik = '',
  String ozet = '',
  String kategori = '',
  DateTime? tarih,
}) =>
    Haber(
      baslik: baslik,
      ozet: ozet,
      baglanti: 'https://ornek/haber-${baslik.hashCode}',
      tarih: tarih ?? DateTime(2026, 7, 26, 12),
      kaynak: 'TRT Haber',
      kategori: kategori,
    );

void main() {
  group('Deprem ile ilgili mi', () {
    test('Başlıkta "deprem" geçen haber kabul ediliyor', () {
      expect(
        HaberFiltresi.depremleIlgiliMi(
            h(baslik: 'Malatya\'da 4.1 büyüklüğünde deprem')),
        isTrue,
      );
    });

    test('Sadece özette geçse de yakalanıyor', () {
      expect(
        HaberFiltresi.depremleIlgiliMi(
            h(baslik: 'AFAD açıklama yaptı', ozet: 'Sarsıntı hissedildi')),
        isTrue,
      );
    });

    test('AFAD ve Kandilli anahtar kelime sayılıyor', () {
      expect(HaberFiltresi.depremleIlgiliMi(h(baslik: 'AFAD duyurdu')), isTrue);
      expect(
          HaberFiltresi.depremleIlgiliMi(h(baslik: 'Kandilli açıkladı')),
          isTrue);
    });

    test('Türkçe karakter farkı sorun çıkarmıyor', () {
      // 'artçı' ve 'artci' ikisi de yakalanmali
      expect(HaberFiltresi.depremleIlgiliMi(h(baslik: 'ARTÇI SARSINTI')),
          isTrue);
      expect(HaberFiltresi.depremleIlgiliMi(h(baslik: 'artci sarsinti')),
          isTrue);
    });

    test('Alakasız haber eleniyor', () {
      expect(
        HaberFiltresi.depremleIlgiliMi(
            h(baslik: 'Merkez Bankası faiz kararını açıkladı')),
        isFalse,
      );
      expect(
        HaberFiltresi.depremleIlgiliMi(h(baslik: 'Fethiye\'de orman yangını')),
        isFalse,
      );
      expect(
        HaberFiltresi.depremleIlgiliMi(
            h(baslik: 'Filenin Sultanları finale yükseldi')),
        isFalse,
      );
    });
  });

  group('Türkiye ile ilgili mi', () {
    test('Kategori "Türkiye" ise doğrudan kabul', () {
      expect(
        HaberFiltresi.turkiyeIleIlgiliMi(
            h(baslik: 'Deprem oldu', kategori: 'Türkiye')),
        isTrue,
      );
    });

    test('Kategori "Gündem" ise kabul', () {
      expect(
        HaberFiltresi.turkiyeIleIlgiliMi(
            h(baslik: 'Deprem oldu', kategori: 'Gündem')),
        isTrue,
      );
    });

    test('Yabancı ülke haberi eleniyor', () {
      expect(
        HaberFiltresi.turkiyeIleIlgiliMi(
            h(baslik: 'Japonya\'da 6.2 büyüklüğünde deprem',
              kategori: 'Dünya')),
        isFalse,
      );
      expect(
        HaberFiltresi.turkiyeIleIlgiliMi(
            h(baslik: 'Endonezya açıklarında deprem', kategori: 'Dünya')),
        isFalse,
      );
    });

    test('Türkiye geçen yabancı haber korunuyor', () {
      // "Yunanistan'da deprem, Türkiye'de de hissedildi" gibi
      expect(
        HaberFiltresi.turkiyeIleIlgiliMi(h(
          baslik: 'Yunanistan\'da deprem',
          ozet: 'Türkiye\'nin batı illerinde de hissedildi',
          kategori: 'Dünya',
        )),
        isTrue,
      );
    });

    test('Deniz adları Türkiye sinyali sayılıyor', () {
      expect(
        HaberFiltresi.turkiyeIleIlgiliMi(
            h(baslik: 'Ege Denizi\'nde deprem', kategori: 'Dünya')),
        isTrue,
      );
    });
  });

  group('Tahmin iddiası', () {
    test('Kâhin iddiası işaretleniyor', () {
      expect(
        HaberFiltresi.tahminIddiasiMi(
            h(baslik: 'Deprem kahini yeni tarih verdi')),
        isTrue,
      );
    });

    test('"Ne zaman olacak" kalıbı işaretleniyor', () {
      expect(
        HaberFiltresi.tahminIddiasiMi(
            h(baslik: 'Beklenen İstanbul depremi ne zaman olacak?')),
        isTrue,
      );
    });

    test('Normal deprem haberi işaretlenmiyor', () {
      expect(
        HaberFiltresi.tahminIddiasiMi(
            h(baslik: 'Malatya\'da 4.1 büyüklüğünde deprem meydana geldi')),
        isFalse,
      );
    });

    test('AFAD açıklaması işaretlenmiyor', () {
      expect(
        HaberFiltresi.tahminIddiasiMi(
            h(baslik: 'AFAD: Deprem sonrası 12 artçı kaydedildi')),
        isFalse,
      );
    });
  });

  group('Süzme', () {
    test('Sadece deprem + Türkiye haberleri kalıyor', () {
      final liste = [
        h(baslik: 'Malatya\'da deprem', kategori: 'Türkiye'),
        h(baslik: 'Merkez Bankası faiz kararı', kategori: 'Ekonomi'),
        h(baslik: 'Japonya\'da deprem', kategori: 'Dünya'),
        h(baslik: 'AFAD\'dan artçı açıklaması', kategori: 'Gündem'),
      ];

      final sonuc = HaberFiltresi.suz(liste);
      expect(sonuc.length, 2);
      expect(sonuc.any((x) => x.baslik.contains('Malatya')), isTrue);
      expect(sonuc.any((x) => x.baslik.contains('AFAD')), isTrue);
      expect(sonuc.any((x) => x.baslik.contains('Japonya')), isFalse);
    });

    test('Sonuç tarihe göre yeniden eskiye sıralı', () {
      final liste = [
        h(baslik: 'Eski deprem', kategori: 'Türkiye',
          tarih: DateTime(2026, 7, 20)),
        h(baslik: 'Yeni deprem', kategori: 'Türkiye',
          tarih: DateTime(2026, 7, 26)),
      ];
      final sonuc = HaberFiltresi.suz(liste);
      expect(sonuc.first.baslik, 'Yeni deprem');
    });

    test('Boş liste boş sonuç', () {
      expect(HaberFiltresi.suz([]), isEmpty);
    });

    test('Hiç deprem haberi yoksa boş dönüyor', () {
      // Sakin donemde bu NORMAL bir durum
      final liste = [
        h(baslik: 'Orman yangını', kategori: 'Türkiye'),
        h(baslik: 'Voleybol maçı', kategori: 'Spor'),
      ];
      expect(HaberFiltresi.suz(liste), isEmpty);
    });
  });

  group('Haber modeli', () {
    test('Geçen süre metni üretiliyor', () {
      final yeni = h(tarih: DateTime.now().subtract(const Duration(hours: 2)));
      expect(yeni.gecenSure, contains('saat'));
    });

    test('Gelecek tarih çökme yaratmıyor', () {
      final ileri = h(tarih: DateTime.now().add(const Duration(days: 1)));
      expect(ileri.gecenSure, isNotEmpty);
    });
  });
}
