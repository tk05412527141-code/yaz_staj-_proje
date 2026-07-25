import 'package:flutter/material.dart';

/// Deprem buyuklugune gore renk, etiket ve boyut ureten yardimci sinif.
///
/// Renkler koyu zeminde okunakli olacak sekilde secildi. Skala,
/// deprem haritalarinin yaygin mantigini izler: kucuk depremler yesil,
/// buyuk depremler kirmizi.
class BuyuklukStili {
  const BuyuklukStili._();

  static Color renk(double buyukluk) {
    if (buyukluk < 2.0) return const Color(0xFF3FB950); // yesil
    if (buyukluk < 3.0) return const Color(0xFF7BC96F); // acik yesil
    if (buyukluk < 4.0) return const Color(0xFFE3B341); // amber
    if (buyukluk < 5.0) return const Color(0xFFF0883E); // turuncu
    if (buyukluk < 6.0) return const Color(0xFFFF7B72); // somon
    return const Color(0xFFF85149); // kirmizi
  }

  static String etiket(double buyukluk) {
    if (buyukluk < 2.0) return 'Çok hafif';
    if (buyukluk < 3.0) return 'Hafif';
    if (buyukluk < 4.0) return 'Orta';
    if (buyukluk < 5.0) return 'Hissedilir';
    if (buyukluk < 6.0) return 'Kuvvetli';
    return 'Büyük';
  }

  /// Kart ve rozetlerde kullanilan yumusak arka plan tonu.
  static Color zeminTonu(double buyukluk) {
    return renk(buyukluk).withValues(alpha: 0.14);
  }

  /// Haritadaki isaretcinin capi - buyuk depremler daha iri gorunur.
  static double isaretciBoyutu(double buyukluk) {
    final boyut = 16.0 + (buyukluk * 5.5);
    return boyut.clamp(16.0, 64.0);
  }
}
