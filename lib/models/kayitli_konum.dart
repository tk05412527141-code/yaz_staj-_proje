import 'dart:convert';

/// Kullanicinin takip ettigi bir yer: ev, iş, ailenin evi, yurt...
///
/// Uygulamanin en kisisel parcasi. Kullanici "Türkiye'deki tüm depremler"
/// yerine "benim yerlerimi etkileyen depremler" gorebilsin diye var.
class KayitliKonum {
  final String id;
  final String ad;
  final double enlem;
  final double boylam;

  /// Listede gosterilecek simge anahtari (bkz. [KonumSimgesi])
  final String simge;

  const KayitliKonum({
    required this.id,
    required this.ad,
    required this.enlem,
    required this.boylam,
    this.simge = 'ev',
  });

  KayitliKonum kopyala({String? ad, String? simge}) {
    return KayitliKonum(
      id: id,
      ad: ad ?? this.ad,
      enlem: enlem,
      boylam: boylam,
      simge: simge ?? this.simge,
    );
  }

  Map<String, dynamic> jsonaCevir() => {
        'id': id,
        'ad': ad,
        'enlem': enlem,
        'boylam': boylam,
        'simge': simge,
      };

  static KayitliKonum? jsondanOku(Map<String, dynamic> j) {
    final id = j['id'];
    final ad = j['ad'];
    final enlem = j['enlem'];
    final boylam = j['boylam'];

    // Bozuk kayitlari sessizce atla - uygulama acilmaya devam etsin
    if (id is! String || ad is! String) return null;
    if (enlem is! num || boylam is! num) return null;

    return KayitliKonum(
      id: id,
      ad: ad,
      enlem: enlem.toDouble(),
      boylam: boylam.toDouble(),
      simge: j['simge'] is String ? j['simge'] as String : 'ev',
    );
  }

  static String listeyiKodla(List<KayitliKonum> konumlar) {
    return jsonEncode(konumlar.map((k) => k.jsonaCevir()).toList());
  }

  static List<KayitliKonum> listeyiCoz(String? kodlanmis) {
    if (kodlanmis == null || kodlanmis.isEmpty) return [];
    try {
      final cozulmus = jsonDecode(kodlanmis);
      if (cozulmus is! List) return [];

      final sonuc = <KayitliKonum>[];
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
