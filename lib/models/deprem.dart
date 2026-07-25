/// Bir depremi temsil eden model sinifi.
///
/// AFAD ve Kandilli API'leri farkli JSON yapilari donuyor. Bu sinif ikisini de
/// tek bir ortak formata cevirir; boylece uygulamanin geri kalani hangi
/// kaynaktan geldigini bilmek zorunda kalmaz.
class Deprem {
  final String id;
  final String yer;
  final double buyukluk;
  final double derinlik; // km
  final double enlem;
  final double boylam;
  final DateTime tarih;
  final String kaynak; // "AFAD" veya "Kandilli"

  const Deprem({
    required this.id,
    required this.yer,
    required this.buyukluk,
    required this.derinlik,
    required this.enlem,
    required this.boylam,
    required this.tarih,
    required this.kaynak,
  });

  /// AFAD API'sinden gelen JSON'u Deprem nesnesine cevirir.
  ///
  /// DIKKAT: AFAD tum sayisal degerleri METIN olarak gonderiyor
  /// ("magnitude": "3.7" gibi). Bu yuzden double.tryParse kullaniyoruz.
  factory Deprem.afaddan(Map<String, dynamic> json) {
    return Deprem(
      id: json['eventID']?.toString() ?? '',
      yer: json['location']?.toString() ?? 'Bilinmeyen konum',
      buyukluk: double.tryParse(json['magnitude']?.toString() ?? '') ?? 0,
      derinlik: double.tryParse(json['depth']?.toString() ?? '') ?? 0,
      enlem: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      boylam: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      tarih: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      kaynak: 'AFAD',
    );
  }

  /// Kandilli API'sinden gelen JSON'u Deprem nesnesine cevirir.
  ///
  /// DIKKAT: Koordinatlar GeoJSON standardinda geliyor, yani sira
  /// [boylam, enlem] seklinde - alisildik [enlem, boylam] sirasinin TERSI.
  /// Bu, harita uygulamalarinda en sik yapilan hatalardan biridir.
  factory Deprem.kandilliden(Map<String, dynamic> json) {
    final geo = json['geojson'] as Map<String, dynamic>?;
    final koordinatlar = (geo?['coordinates'] as List?) ?? const <num>[0, 0];

    final double boylam =
        koordinatlar.isNotEmpty ? (koordinatlar[0] as num).toDouble() : 0;
    final double enlem =
        koordinatlar.length > 1 ? (koordinatlar[1] as num).toDouble() : 0;

    // Kandilli tarihi "2026-07-25 23:49:05" formatinda gonderiyor.
    // DateTime.tryParse arada bosluk yerine "T" bekledigi icin degistiriyoruz.
    final tarihMetni = (json['date_time']?.toString() ?? '').replaceFirst(' ', 'T');

    return Deprem(
      id: json['earthquake_id']?.toString() ?? '',
      yer: json['title']?.toString() ?? 'Bilinmeyen konum',
      buyukluk: (json['mag'] as num?)?.toDouble() ?? 0,
      derinlik: (json['depth'] as num?)?.toDouble() ?? 0,
      enlem: enlem,
      boylam: boylam,
      tarih: DateTime.tryParse(tarihMetni) ?? DateTime.now(),
      kaynak: 'Kandilli',
    );
  }

  /// "3 saat once" gibi okunabilir bir zaman metni uretir.
  String get gecenSure {
    final fark = DateTime.now().difference(tarih);

    if (fark.isNegative) return 'az once';
    if (fark.inMinutes < 1) return 'az once';
    if (fark.inMinutes < 60) return '${fark.inMinutes} dakika once';
    if (fark.inHours < 24) return '${fark.inHours} saat once';
    if (fark.inDays < 30) return '${fark.inDays} gun once';
    return '${(fark.inDays / 30).floor()} ay once';
  }

  /// "25.07.2026 23:49" formatinda tarih metni.
  String get tarihMetni {
    String iki(int n) => n.toString().padLeft(2, '0');
    return '${iki(tarih.day)}.${iki(tarih.month)}.${tarih.year} '
        '${iki(tarih.hour)}:${iki(tarih.minute)}';
  }

  /// "38.3507, 37.8618" - kopyalanabilir koordinat metni.
  String get koordinatMetni =>
      '${enlem.toStringAsFixed(4)}, ${boylam.toStringAsFixed(4)}';

  /// Konumu tarayicida veya harita uygulamasinda acan baglanti.
  String get haritaBaglantisi =>
      'https://www.openstreetmap.org/?mlat=$enlem&mlon=$boylam#map=10/$enlem/$boylam';

  /// Paylasilmaya / kopyalanmaya hazir ozet metin.
  String get paylasimMetni => '''
$yer
Büyüklük: ${buyukluk.toStringAsFixed(1)} · Derinlik: ${derinlik.toStringAsFixed(1)} km
Tarih: $tarihMetni
Konum: $koordinatMetni
Kaynak: $kaynak
$haritaBaglantisi''';
}
