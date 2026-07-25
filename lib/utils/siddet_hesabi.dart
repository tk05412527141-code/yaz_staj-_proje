import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Belirli bir noktada hissedilecek sarsintinin tahmini seviyesi.
///
/// Buyukluk (magnitude) tek basina "beni etkiler mi?" sorusuna cevap vermez.
/// 300 km uzaktaki 5.0 hic hissedilmezken, 10 km yakindaki 4.0 insani
/// yatagindan kaldirabilir. Bu sinif mesafe ve derinligi de hesaba katarak
/// kullaniciya anlamli bir cevap uretir.
enum HissedilirlikSeviyesi {
  hissedilmez(
    'Hissedilmez',
    'Bu konumda fark edilmesi beklenmiyor.',
    Color(0xFF5A6672),
  ),
  zor(
    'Zor hissedilir',
    'Duran veya üst katlardaki bazı kişiler fark edebilir.',
    Color(0xFF7BC96F),
  ),
  hafif(
    'Hafif hissedilir',
    'Bina içinde fark edilir; asılı eşyalar hafifçe sallanabilir.',
    Color(0xFFE3B341),
  ),
  belirgin(
    'Belirgin hissedilir',
    'Çoğu kişi hisseder; eşyalar sallanır, bazıları uyanır.',
    Color(0xFFF0883E),
  ),
  guclu(
    'Güçlü sarsıntı',
    'Herkes hisseder; mobilyalar oynayabilir, sıva çatlayabilir.',
    Color(0xFFFF7B72),
  ),
  cokGuclu(
    'Çok güçlü',
    'Ayakta durmak zorlaşır; hasar görülebilir.',
    Color(0xFFF85149),
  ),
  siddetli(
    'Şiddetli',
    'Ciddi hasar beklenir.',
    Color(0xFFD1242F),
  );

  final String etiket;
  final String aciklama;
  final Color renk;

  const HissedilirlikSeviyesi(this.etiket, this.aciklama, this.renk);

  bool get hissedilir => this != HissedilirlikSeviyesi.hissedilmez;
}

/// Bir deprem icin belirli bir noktadaki tahmin sonucu.
class SiddetSonucu {
  /// Yer yuzeyindeki mesafe (km)
  final double mesafeKm;

  /// Derinligi de hesaba katan gercek mesafe (km)
  final double hiposantrKm;

  /// Tahmini Mercalli siddeti (1–12 arasina kirpilmis)
  final double mmi;

  /// Kullanilan modelin gecerlilik araligi icinde miyiz?
  /// Degilse arayuzde "tahmin belirsiz" uyarisi gosterilmeli.
  final bool guvenilir;

  final HissedilirlikSeviyesi seviye;

  const SiddetSonucu({
    required this.mesafeKm,
    required this.hiposantrKm,
    required this.mmi,
    required this.guvenilir,
    required this.seviye,
  });

  String get mesafeMetni {
    if (mesafeKm < 1) return '1 km\'den yakın';
    if (mesafeKm < 10) return '${mesafeKm.toStringAsFixed(1)} km';
    return '${mesafeKm.round()} km';
  }
}

/// Mesafe ve tahmini sarsinti siddeti hesaplari.
///
/// KULLANILAN MODEL
///   Allen, T. I., Wald, D. J. & Worden, C. B. (2012)
///   "Intensity attenuation in active crustal regions"
///   Journal of Seismology, 16: 409–433
///
///   Hiposantr mesafeli surum. Katsayilar OpenQuake Engine'in acik kaynak
///   uygulamasindan alinmistir (AllenEtAl2012Rhypo).
///
/// GECERLILIK SINIRLARI (yayinda belirtilen)
///   - Buyukluk: MW 5.0 – 7.9
///   - Mesafe:   300 km'ye kadar
///
///   Uygulamada gosterilen depremlerin cogu M5'in altinda. Bu durumda model
///   ekstrapolasyon yapiyor demektir; bu yuzden [SiddetSonucu.guvenilir]
///   false doner ve arayuzde kesin bir sayi yerine kaba kategori gosterilir.
///
/// NOT: Bu bir TAHMINDIR. Gercek sarsinti; zemin yapisi, bina turu, kat
/// yuksekligi ve fay dogrultusuna gore ciddi olcude degisir. Resmi bir
/// siddet degeri degildir.
class SiddetHesabi {
  const SiddetHesabi._();

  // Allen ve ark. (2012) - hiposantr mesafeli surum katsayilari
  static const _c0 = 2.085;
  static const _c1 = 1.428;
  static const _c2 = -1.402;
  static const _c4 = 0.078;
  static const _m1 = -0.209;
  static const _m2 = 2.042;

  /// Modelin gecerli oldugu en uzak mesafe (km)
  static const gecerliMesafeKm = 300.0;

  /// Modelin gecerli oldugu en kucuk buyukluk
  static const gecerliMinBuyukluk = 5.0;

  static const _dunyaYaricapiKm = 6371.0088;

  /// Iki koordinat arasindaki yer yuzeyi mesafesi (haversine formulu).
  static double mesafeKm(
    double enlem1,
    double boylam1,
    double enlem2,
    double boylam2,
  ) {
    double radyan(double derece) => derece * math.pi / 180.0;

    final f1 = radyan(enlem1);
    final f2 = radyan(enlem2);
    final dF = radyan(enlem2 - enlem1);
    final dL = radyan(boylam2 - boylam1);

    final a = math.sin(dF / 2) * math.sin(dF / 2) +
        math.cos(f1) * math.cos(f2) * math.sin(dL / 2) * math.sin(dL / 2);

    return 2 * _dunyaYaricapiKm * math.asin(math.min(1.0, math.sqrt(a)));
  }

  /// Ham Mercalli siddeti (kirpilmamis).
  static double _hamMmi(double buyukluk, double hiposantrKm) {
    final rm = _m1 + _m2 * math.exp(buyukluk - 5.0);
    var deger = _c0 +
        _c1 * buyukluk +
        _c2 * math.log(math.sqrt(hiposantrKm * hiposantrKm + rm * rm));

    // 50 km'nin otesinde ek bir mesafe terimi devreye giriyor
    if (hiposantrKm > 50.0) {
      deger += _c4 * math.log(hiposantrKm / 50.0);
    }
    return deger;
  }

  /// Bir depremin belirli bir noktada tahmini etkisini hesaplar.
  static SiddetSonucu hesapla({
    required double depremEnlem,
    required double depremBoylam,
    required double derinlikKm,
    required double buyukluk,
    required double noktaEnlem,
    required double noktaBoylam,
  }) {
    final yuzeyMesafe = mesafeKm(
      depremEnlem,
      depremBoylam,
      noktaEnlem,
      noktaBoylam,
    );

    // Derinligi de hesaba kat: gercek mesafe hipotenus kadar
    final derinlik = derinlikKm.isFinite && derinlikKm > 0 ? derinlikKm : 0.0;
    final hiposantr = math.sqrt(
      yuzeyMesafe * yuzeyMesafe + derinlik * derinlik,
    );

    // Sifira bolunmeyi onlemek icin en az 1 km kabul ediyoruz
    final guvenliMesafe = math.max(1.0, hiposantr);

    var mmi = _hamMmi(buyukluk, guvenliMesafe);
    if (!mmi.isFinite) mmi = 1.0;
    mmi = mmi.clamp(1.0, 12.0);

    final guvenilir =
        hiposantr <= gecerliMesafeKm && buyukluk >= gecerliMinBuyukluk;

    return SiddetSonucu(
      mesafeKm: yuzeyMesafe,
      hiposantrKm: hiposantr,
      mmi: mmi,
      guvenilir: guvenilir,
      seviye: seviyeBul(mmi),
    );
  }

  /// Mercalli degerini kullanicinin anlayacagi bir kategoriye cevirir.
  ///
  /// Kesin sayi yerine kategori gosteriyoruz; cunku modelin belirsizligi
  /// ondalik hassasiyeti anlamsiz kilacak kadar buyuk.
  static HissedilirlikSeviyesi seviyeBul(double mmi) {
    if (mmi < 2.0) return HissedilirlikSeviyesi.hissedilmez;
    if (mmi < 3.5) return HissedilirlikSeviyesi.zor;
    if (mmi < 4.5) return HissedilirlikSeviyesi.hafif;
    if (mmi < 5.5) return HissedilirlikSeviyesi.belirgin;
    if (mmi < 6.5) return HissedilirlikSeviyesi.guclu;
    if (mmi < 7.5) return HissedilirlikSeviyesi.cokGuclu;
    return HissedilirlikSeviyesi.siddetli;
  }
}
