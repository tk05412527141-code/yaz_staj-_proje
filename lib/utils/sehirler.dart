import 'package:flutter/material.dart';

/// Bir il merkezi ve koordinatlari.
class Sehir {
  final int plaka;
  final String ad;
  final double enlem;
  final double boylam;

  const Sehir(this.plaka, this.ad, this.enlem, this.boylam);
}

/// Kayitli konum eklerken kullanilan simgeler.
///
/// Kullanici "Ev", "İş", "Aile" gibi ayirt edebilsin diye.
class KonumSimgesi {
  const KonumSimgesi._();

  static const Map<String, IconData> tumu = {
    'ev': Icons.home_outlined,
    'is': Icons.business_center_outlined,
    'aile': Icons.favorite_border,
    'okul': Icons.school_outlined,
    'yildiz': Icons.star_border,
  };

  static const Map<String, String> adlar = {
    'ev': 'Ev',
    'is': 'İş',
    'aile': 'Aile',
    'okul': 'Okul',
    'yildiz': 'Diğer',
  };

  static IconData ikon(String anahtar) =>
      tumu[anahtar] ?? Icons.place_outlined;
}

/// Turkiye'nin 81 il merkezi.
///
/// Kullanicinin konum eklerken harita uzerinde ugrasmasi gerekmesin diye
/// hazir liste sunuyoruz. Koordinatlar il merkezlerine aittir; ilce
/// hassasiyeti gerekiyorsa haritadan secim yapilabilir.
class Sehirler {
  const Sehirler._();

  static const List<Sehir> tumu = [
    Sehir(1, 'Adana', 37.0000, 35.3213),
    Sehir(2, 'Adıyaman', 37.7648, 38.2786),
    Sehir(3, 'Afyonkarahisar', 38.7638, 30.5403),
    Sehir(4, 'Ağrı', 39.7191, 43.0503),
    Sehir(5, 'Amasya', 40.6499, 35.8353),
    Sehir(6, 'Ankara', 39.9334, 32.8597),
    Sehir(7, 'Antalya', 36.8969, 30.7133),
    Sehir(8, 'Artvin', 41.1828, 41.8183),
    Sehir(9, 'Aydın', 37.8560, 27.8416),
    Sehir(10, 'Balıkesir', 39.6484, 27.8826),
    Sehir(11, 'Bilecik', 40.1451, 29.9799),
    Sehir(12, 'Bingöl', 38.8847, 40.4986),
    Sehir(13, 'Bitlis', 38.4006, 42.1095),
    Sehir(14, 'Bolu', 40.7392, 31.6089),
    Sehir(15, 'Burdur', 37.7203, 30.2908),
    Sehir(16, 'Bursa', 40.1885, 29.0610),
    Sehir(17, 'Çanakkale', 40.1553, 26.4142),
    Sehir(18, 'Çankırı', 40.6013, 33.6134),
    Sehir(19, 'Çorum', 40.5506, 34.9556),
    Sehir(20, 'Denizli', 37.7765, 29.0864),
    Sehir(21, 'Diyarbakır', 37.9144, 40.2306),
    Sehir(22, 'Edirne', 41.6818, 26.5623),
    Sehir(23, 'Elazığ', 38.6810, 39.2264),
    Sehir(24, 'Erzincan', 39.7500, 39.5000),
    Sehir(25, 'Erzurum', 39.9000, 41.2700),
    Sehir(26, 'Eskişehir', 39.7767, 30.5206),
    Sehir(27, 'Gaziantep', 37.0662, 37.3833),
    Sehir(28, 'Giresun', 40.9128, 38.3895),
    Sehir(29, 'Gümüşhane', 40.4386, 39.5086),
    Sehir(30, 'Hakkâri', 37.5744, 43.7408),
    Sehir(31, 'Hatay', 36.2025, 36.1606),
    Sehir(32, 'Isparta', 37.7648, 30.5566),
    Sehir(33, 'Mersin', 36.8121, 34.6415),
    Sehir(34, 'İstanbul', 41.0082, 28.9784),
    Sehir(35, 'İzmir', 38.4237, 27.1428),
    Sehir(36, 'Kars', 40.6013, 43.0975),
    Sehir(37, 'Kastamonu', 41.3887, 33.7827),
    Sehir(38, 'Kayseri', 38.7312, 35.4787),
    Sehir(39, 'Kırklareli', 41.7351, 27.2258),
    Sehir(40, 'Kırşehir', 39.1425, 34.1709),
    Sehir(41, 'Kocaeli', 40.7654, 29.9408),
    Sehir(42, 'Konya', 37.8746, 32.4932),
    Sehir(43, 'Kütahya', 39.4242, 29.9833),
    Sehir(44, 'Malatya', 38.3552, 38.3095),
    Sehir(45, 'Manisa', 38.6191, 27.4289),
    Sehir(46, 'Kahramanmaraş', 37.5858, 36.9371),
    Sehir(47, 'Mardin', 37.3212, 40.7245),
    Sehir(48, 'Muğla', 37.2154, 28.3634),
    Sehir(49, 'Muş', 38.7432, 41.5064),
    Sehir(50, 'Nevşehir', 38.6939, 34.6857),
    Sehir(51, 'Niğde', 37.9667, 34.6833),
    Sehir(52, 'Ordu', 40.9839, 37.8764),
    Sehir(53, 'Rize', 41.0201, 40.5234),
    Sehir(54, 'Sakarya', 40.7889, 30.4053),
    Sehir(55, 'Samsun', 41.2867, 36.3300),
    Sehir(56, 'Siirt', 37.9333, 41.9500),
    Sehir(57, 'Sinop', 42.0231, 35.1531),
    Sehir(58, 'Sivas', 39.7477, 37.0179),
    Sehir(59, 'Tekirdağ', 40.9833, 27.5167),
    Sehir(60, 'Tokat', 40.3167, 36.5500),
    Sehir(61, 'Trabzon', 41.0015, 39.7178),
    Sehir(62, 'Tunceli', 39.1079, 39.5401),
    Sehir(63, 'Şanlıurfa', 37.1591, 38.7969),
    Sehir(64, 'Uşak', 38.6823, 29.4082),
    Sehir(65, 'Van', 38.4891, 43.4089),
    Sehir(66, 'Yozgat', 39.8181, 34.8147),
    Sehir(67, 'Zonguldak', 41.4564, 31.7987),
    Sehir(68, 'Aksaray', 38.3687, 34.0370),
    Sehir(69, 'Bayburt', 40.2552, 40.2249),
    Sehir(70, 'Karaman', 37.1759, 33.2287),
    Sehir(71, 'Kırıkkale', 39.8468, 33.5153),
    Sehir(72, 'Batman', 37.8812, 41.1351),
    Sehir(73, 'Şırnak', 37.5164, 42.4611),
    Sehir(74, 'Bartın', 41.6344, 32.3375),
    Sehir(75, 'Ardahan', 41.1105, 42.7022),
    Sehir(76, 'Iğdır', 39.9237, 44.0450),
    Sehir(77, 'Yalova', 40.6500, 29.2667),
    Sehir(78, 'Karabük', 41.2061, 32.6204),
    Sehir(79, 'Kilis', 36.7184, 37.1212),
    Sehir(80, 'Osmaniye', 37.0742, 36.2464),
    Sehir(81, 'Düzce', 40.8438, 31.1565),
  ];

  /// Turkce karakterleri de dogru eslestiren arama.
  ///
  /// Kullanici "istanbul" yazinca "İstanbul" bulunmali, "sanliurfa" yazinca
  /// "Şanlıurfa" bulunmali. Bu yuzden once harfleri sadelestiriyoruz.
  static List<Sehir> ara(String sorgu) {
    final s = sadelestir(sorgu);
    if (s.isEmpty) return tumu;
    return tumu.where((sehir) => sadelestir(sehir.ad).contains(s)).toList();
  }

  static String sadelestir(String metin) {
    const donusum = {
      'ı': 'i', 'İ': 'i', 'I': 'i', 'i': 'i',
      'ş': 's', 'Ş': 's',
      'ğ': 'g', 'Ğ': 'g',
      'ü': 'u', 'Ü': 'u',
      'ö': 'o', 'Ö': 'o',
      'ç': 'c', 'Ç': 'c',
      'â': 'a', 'Â': 'a',
    };
    final tampon = StringBuffer();
    for (final harf in metin.split('')) {
      tampon.write(donusum[harf] ?? harf.toLowerCase());
    }
    return tampon.toString().trim();
  }
}
