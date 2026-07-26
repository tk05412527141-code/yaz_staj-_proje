import 'dart:convert';

/// Acil durumda konum mesaji gonderilecek kisi.
///
/// GIZLILIK
///   Kisiler yalnizca telefonda saklanir. Rehber erisim izni ISTENMEZ —
///   kullanici numarayi elle girer. Bu bilincli bir tercih: rehber izni
///   uygulamanin tum kisilerini gormesi demek ve acil durum ozelligi icin
///   gereksiz genis bir yetki.
class AcilKisi {
  final String id;
  final String ad;

  /// Ham telefon numarasi (kullanicinin girdigi bicimde)
  final String telefon;

  /// Kisiyle iliski: "Anne", "Kardes", "Komsu" gibi. Bos olabilir.
  final String iliski;

  const AcilKisi({
    required this.id,
    required this.ad,
    required this.telefon,
    this.iliski = '',
  });

  /// SMS ve WhatsApp baglantilarinda kullanilacak temiz numara.
  ///
  /// Bosluk, parantez, tire gibi karakterler temizlenir; bas taraftaki
  /// + korunur cunku uluslararasi bicim icin gerekli.
  String get temizTelefon => AcilKisi.telefonTemizle(telefon);

  /// WhatsApp uluslararasi bicim ister (+ olmadan, ulke kodlu).
  ///
  /// Turkiye numaralari icin donusum:
  ///   0555 111 22 33  -> 905551112233
  ///   +90 555 ...     -> 905551112233
  ///   555 111 22 33   -> 905551112233
  String get whatsappTelefon {
    var n = temizTelefon.replaceAll('+', '');

    // Basta 0 varsa at (yerel bicim) ve ulke kodu ekle
    if (n.startsWith('0')) {
      n = n.substring(1);
    }
    // Ulke kodu yoksa Turkiye varsay
    if (!n.startsWith('90') && n.length == 10) {
      n = '90$n';
    }
    return n;
  }

  AcilKisi kopyala({String? ad, String? telefon, String? iliski}) {
    return AcilKisi(
      id: id,
      ad: ad ?? this.ad,
      telefon: telefon ?? this.telefon,
      iliski: iliski ?? this.iliski,
    );
  }

  // ------------------------------------------------------------------
  // Telefon dogrulama ve temizleme
  // ------------------------------------------------------------------

  /// Numaradan gorsel karakterleri atar. + isareti korunur.
  static String telefonTemizle(String ham) {
    final tampon = StringBuffer();
    for (var i = 0; i < ham.length; i++) {
      final harf = ham[i];
      if (harf == '+' && tampon.isEmpty) {
        tampon.write(harf);
      } else if (RegExp(r'[0-9]').hasMatch(harf)) {
        tampon.write(harf);
      }
    }
    return tampon.toString();
  }

  /// Numara gonderilebilir gorunuyor mu?
  ///
  /// Cok siki dogrulama yapmiyoruz: kullanici sabit hat, kisa numara veya
  /// yabanci numara girebilir. Sadece bariz hatalari yakaliyoruz.
  static bool telefonGecerliMi(String ham) {
    final temiz = telefonTemizle(ham);
    final rakamlar = temiz.replaceAll('+', '');

    if (rakamlar.isEmpty) return false;
    // Turkiye cep: 10 hane (5xx...), ulke kodlu: 12 hane (905xx...)
    // Sabit hat ve yabanci numaralar icin genis bir aralik biraktik
    if (rakamlar.length < 7 || rakamlar.length > 15) return false;

    return true;
  }

  /// Ekranda okunakli bicim: 0555 111 22 33
  String get gosterimTelefon {
    final r = temizTelefon.replaceAll('+', '');

    // 905551112233 -> 0555 111 22 33
    var yerel = r;
    if (yerel.startsWith('90') && yerel.length == 12) {
      yerel = '0${yerel.substring(2)}';
    } else if (yerel.length == 10) {
      yerel = '0$yerel';
    }

    if (yerel.length == 11) {
      return '${yerel.substring(0, 4)} ${yerel.substring(4, 7)} '
          '${yerel.substring(7, 9)} ${yerel.substring(9)}';
    }
    return telefon; // taniyamadiysak kullanicinin yazdigini goster
  }

  // ------------------------------------------------------------------
  // Saklama
  // ------------------------------------------------------------------

  Map<String, dynamic> jsonaCevir() => {
        'id': id,
        'ad': ad,
        'telefon': telefon,
        'iliski': iliski,
      };

  static AcilKisi? jsondanOku(Map<String, dynamic> j) {
    final id = j['id'];
    final ad = j['ad'];
    final telefon = j['telefon'];

    if (id is! String || ad is! String || telefon is! String) return null;
    if (telefon.trim().isEmpty) return null;

    return AcilKisi(
      id: id,
      ad: ad,
      telefon: telefon,
      iliski: j['iliski'] is String ? j['iliski'] as String : '',
    );
  }

  static String listeyiKodla(List<AcilKisi> kisiler) {
    return jsonEncode(kisiler.map((k) => k.jsonaCevir()).toList());
  }

  static List<AcilKisi> listeyiCoz(String? kodlanmis) {
    if (kodlanmis == null || kodlanmis.isEmpty) return [];
    try {
      final cozulmus = jsonDecode(kodlanmis);
      if (cozulmus is! List) return [];

      final sonuc = <AcilKisi>[];
      for (final oge in cozulmus) {
        if (oge is! Map<String, dynamic>) continue;
        final k = jsondanOku(oge);
        if (k != null) sonuc.add(k);
      }
      return sonuc;
    } catch (_) {
      return [];
    }
  }
}
