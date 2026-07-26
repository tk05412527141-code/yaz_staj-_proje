import 'dart:convert';

import 'package:flutter/material.dart';

/// Deprem oncesi yapilmasi gereken bir hazirlik maddesi.
///
/// NEDEN VAR?
///   Deprem uygulamalarinin neredeyse hepsi "ne oldu"yu anlatiyor.
///   "Ne yapmaliyim"a cevap veren az. Bu liste, deprem OLMADAN once
///   isine yarayan tek bolum.
///
///   Ayni zamanda bildirimlerin dayanagi: kullanici bir maddeyi
///   tamamladiginda, periyodu dolunca hatirlatma gonderiliyor.
class HazirlikMaddesi {
  final String id;
  final String baslik;
  final String aciklama;
  final IconData ikon;

  /// Kac gunde bir hatirlatilacak
  final int periyotGun;

  /// Bildirimde gosterilecek metin
  final String hatirlatmaBaslik;
  final String hatirlatmaGovde;

  /// Bildirim kimligi.
  ///
  /// ELLE atanmis sabit sayilar kullaniyoruz. id.hashCode kullanmak
  /// cazip gorunuyor ama iki sorunu var:
  ///   1. Dart'in String.hashCode degeri platformlar ve surumler
  ///      arasinda ayni olmak zorunda degil; degisirse eski planlanmis
  ///      bildirimler iptal edilemez hale gelir
  ///   2. Modulo ile daraltinca cakisma ihtimali dogar (5 madde icin
  ///      ~%0.1) ve cakisan iki hatirlatmadan biri digerini ezer
  final int bildirimId;

  const HazirlikMaddesi({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.ikon,
    required this.periyotGun,
    required this.hatirlatmaBaslik,
    required this.hatirlatmaGovde,
    required this.bildirimId,
  });

  String get periyotMetni {
    if (periyotGun < 30) return 'Her $periyotGun günde bir';
    if (periyotGun < 365) return 'Her ${(periyotGun / 30).round()} ayda bir';
    return 'Yılda bir';
  }
}

/// Uygulamada tanimli hazirlik maddeleri.
///
/// Icerik AFAD ve Kizilay'in yaygin olarak yayinladigi hazirlik
/// onerilerine dayaniyor. Tibbi veya muhendislik tavsiyesi degildir;
/// resmi kaynaklar esas alinmalidir.
class HazirlikListesi {
  const HazirlikListesi._();

  static const List<HazirlikMaddesi> tumu = [
    HazirlikMaddesi(
      id: 'canta',
      bildirimId: 1001,
      baslik: 'Deprem çantası',
      aciklama: 'Su, uzun ömürlü yiyecek, ilk yardım malzemesi, düdük, '
          'el feneri, powerbank, ilaçlar ve bir miktar nakit.',
      ikon: Icons.backpack_outlined,
      periyotGun: 90,
      hatirlatmaBaslik: 'Deprem çantanı kontrol et',
      hatirlatmaGovde: 'Suyun ve yiyeceklerin son kullanma tarihi geçmiş '
          'olabilir. Pilleri ve powerbank\'i de kontrol et.',
    ),
    HazirlikMaddesi(
      id: 'bulusma',
      bildirimId: 1002,
      baslik: 'Aile buluşma planı',
      aciklama: 'Ayrı yerlerdeyken nerede buluşacağınız, kimin kimi '
          'arayacağı ve şehir dışından bir irtibat kişisi belirleyin.',
      ikon: Icons.groups_outlined,
      periyotGun: 180,
      hatirlatmaBaslik: 'Aile buluşma planını tazele',
      hatirlatmaGovde: 'Herkes buluşma noktasını hatırlıyor mu? '
          'Telefonlar çekmezse ne yapacaksınız?',
    ),
    HazirlikMaddesi(
      id: 'sabitleme',
      bildirimId: 1003,
      baslik: 'Ev güvenliği',
      aciklama: 'Gardırop, kitaplık, televizyon ve su ısıtıcısını duvara '
          'sabitleyin. Yatakların üstünde ağır eşya bulundurmayın.',
      ikon: Icons.chair_outlined,
      periyotGun: 365,
      hatirlatmaBaslik: 'Ev güvenliğini gözden geçir',
      hatirlatmaGovde: 'Yeni aldığın mobilyalar sabitlendi mi? '
          'Yatak başlarında devrilebilecek eşya var mı?',
    ),
    HazirlikMaddesi(
      id: 'belge',
      bildirimId: 1004,
      baslik: 'Belge ve iletişim',
      aciklama: 'Kimlik, tapu, sigorta ve sağlık belgelerinin kopyasını '
          'çantada ve dijital olarak saklayın. Acil numaraları yazın.',
      ikon: Icons.folder_shared_outlined,
      periyotGun: 365,
      hatirlatmaBaslik: 'Belgelerini güncelle',
      hatirlatmaGovde: 'Kimlik, tapu ve sigorta belgelerinin kopyaları '
          'güncel mi? Acil durum numaraları elinin altında mı?',
    ),
    HazirlikMaddesi(
      id: 'tatbikat',
      bildirimId: 1005,
      baslik: 'Çök-Kapan-Tutun tatbikatı',
      aciklama: 'Sarsıntı anında sağlam bir masanın altına çökün, başınızı '
          'koruyun ve sarsıntı bitene kadar tutunun. Evde deneyin.',
      ikon: Icons.self_improvement_outlined,
      periyotGun: 180,
      hatirlatmaBaslik: 'Tatbikat zamanı',
      hatirlatmaGovde: 'Çök-Kapan-Tutun hareketini ailecek tekrar edin. '
          'Beş dakika sürer, refleks kazandırır.',
    ),
  ];

  static HazirlikMaddesi? bul(String id) {
    for (final m in tumu) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// Kullanicinin hazirlik durumu: hangi madde ne zaman tamamlandi.
///
/// Telefonda JSON olarak saklanir.
class HazirlikDurumu {
  /// madde id -> son tamamlanma tarihi
  final Map<String, DateTime> tamamlanmaTarihleri;

  /// Hatirlatmalari acik olan madde id'leri
  final Set<String> acikHatirlatmalar;

  /// Hatirlatmalarin gonderilecegi saat (0-23)
  final int hatirlatmaSaati;

  const HazirlikDurumu({
    this.tamamlanmaTarihleri = const {},
    this.acikHatirlatmalar = const {},
    this.hatirlatmaSaati = 10,
  });

  bool tamamlandiMi(String id) => tamamlanmaTarihleri.containsKey(id);
  bool hatirlatmaAcikMi(String id) => acikHatirlatmalar.contains(id);

  DateTime? tamamlanma(String id) => tamamlanmaTarihleri[id];

  int get tamamlananSayisi => tamamlanmaTarihleri.length;

  double get ilerleme => HazirlikListesi.tumu.isEmpty
      ? 0
      : tamamlananSayisi / HazirlikListesi.tumu.length;

  HazirlikDurumu kopyala({
    Map<String, DateTime>? tamamlanmaTarihleri,
    Set<String>? acikHatirlatmalar,
    int? hatirlatmaSaati,
  }) {
    return HazirlikDurumu(
      tamamlanmaTarihleri: tamamlanmaTarihleri ?? this.tamamlanmaTarihleri,
      acikHatirlatmalar: acikHatirlatmalar ?? this.acikHatirlatmalar,
      hatirlatmaSaati: hatirlatmaSaati ?? this.hatirlatmaSaati,
    );
  }

  // ------------------------------------------------------------------
  // Saklama
  // ------------------------------------------------------------------

  String kodla() {
    return jsonEncode({
      'tamamlanma': tamamlanmaTarihleri
          .map((k, v) => MapEntry(k, v.toIso8601String())),
      'acik': acikHatirlatmalar.toList(),
      'saat': hatirlatmaSaati,
    });
  }

  static HazirlikDurumu coz(String? kodlanmis) {
    if (kodlanmis == null || kodlanmis.isEmpty) return const HazirlikDurumu();

    try {
      final j = jsonDecode(kodlanmis);
      if (j is! Map<String, dynamic>) return const HazirlikDurumu();

      final tarihler = <String, DateTime>{};
      final ham = j['tamamlanma'];
      if (ham is Map) {
        ham.forEach((anahtar, deger) {
          if (anahtar is! String || deger is! String) return;
          final t = DateTime.tryParse(deger);
          if (t != null) tarihler[anahtar] = t;
        });
      }

      final acik = <String>{};
      final hamAcik = j['acik'];
      if (hamAcik is List) {
        for (final e in hamAcik) {
          if (e is String) acik.add(e);
        }
      }

      var saat = 10;
      final hamSaat = j['saat'];
      if (hamSaat is int && hamSaat >= 0 && hamSaat <= 23) saat = hamSaat;

      return HazirlikDurumu(
        tamamlanmaTarihleri: tarihler,
        acikHatirlatmalar: acik,
        hatirlatmaSaati: saat,
      );
    } catch (_) {
      return const HazirlikDurumu();
    }
  }
}
