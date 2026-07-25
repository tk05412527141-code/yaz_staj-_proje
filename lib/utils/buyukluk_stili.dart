import 'package:flutter/material.dart';

/// Deprem buyuklugune gore renk ve etiket ureten yardimci sinif.
///
/// Renk skalasi, deprem haritalarinda yaygin kullanilan mantiga dayaniyor:
/// kucuk depremler yesil/mavi, buyuk depremler turuncu/kirmizi.
class BuyuklukStili {
  const BuyuklukStili._();

  static Color renk(double buyukluk) {
    if (buyukluk < 2.0) return const Color(0xFF4CAF50); // yesil
    if (buyukluk < 3.0) return const Color(0xFF8BC34A); // acik yesil
    if (buyukluk < 4.0) return const Color(0xFFFFC107); // sari
    if (buyukluk < 5.0) return const Color(0xFFFF9800); // turuncu
    if (buyukluk < 6.0) return const Color(0xFFFF5722); // koyu turuncu
    return const Color(0xFFD32F2F); // kirmizi
  }

  static String etiket(double buyukluk) {
    if (buyukluk < 2.0) return 'Cok hafif';
    if (buyukluk < 3.0) return 'Hafif';
    if (buyukluk < 4.0) return 'Orta';
    if (buyukluk < 5.0) return 'Hissedilir';
    if (buyukluk < 6.0) return 'Kuvvetli';
    return 'Buyuk';
  }

  /// Haritadaki isaretcinin buyuklugu - buyuk depremler daha iri gorunur.
  static double isaretciBoyutu(double buyukluk) {
    final boyut = 18.0 + (buyukluk * 5.0);
    return boyut.clamp(18.0, 60.0);
  }
}
