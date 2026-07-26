import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/acil_kisi.dart';
import 'konum_servisi.dart';

/// Mesajin nasil gonderilmeye calisildigi ve sonucu.
enum GonderimSonucu {
  acildi('Mesaj uygulaması açıldı'),
  uygulamaYok('Uygulama bulunamadı'),
  kisiYok('Kayıtlı kişi yok'),
  hata('Gönderilemedi');

  final String etiket;
  const GonderimSonucu(this.etiket);
}

/// Acil durum mesajini olusturur ve gonderim kanallarini acar.
///
/// ONEMLI KISIT
///   Bu servis mesaji KENDI BASINA GONDEREMEZ. Ne iOS ne Android bir
///   uygulamanin kullanici onayi olmadan SMS gondermesine izin veriyor.
///   (Android'de SEND_SMS izni var ama Play Store, varsayilan SMS
///   uygulamasi olmayan uygulamalari bu izinle reddediyor.)
///
///   Yaptigi sey: alicilar ve mesaj hazir sekilde SMS/WhatsApp
///   uygulamasini acmak. Son "gonder" dokunusu kullanicida.
///
///   Bu kisiti arayuzde acikca yaziyoruz. Acil durumda insanin mesajin
///   gittigini sanip beklemesi gercek zarar dogurur.
class AcilDurumServisi {
  const AcilDurumServisi._();

  /// Acil durum mesajini olusturur.
  ///
  /// Kisa tutuluyor: SMS 160 karakterde bolunur ve uzun mesaj gecikebilir.
  static String mesajOlustur({
    required KonumSonucu konum,
    String? ekNot,
  }) {
    final parcalar = <String>['ACİL: Yardıma ihtiyacım var.'];

    if (konum.varMi) {
      parcalar.add('Konumum: ${konum.koordinatMetni}');
      parcalar.add(konum.haritaBaglantisi);

      // Konum GPS degilse bunu mesajda da belirtiyoruz - alici
      // koordinatin ne kadar guvenilir oldugunu bilmeli
      if (konum.kaynak == KonumKaynagi.kayitliYer) {
        parcalar.add('(Kayıtlı adres konumu, anlık GPS değil)');
      } else if (konum.kaynak == KonumKaynagi.sonBilinen) {
        parcalar.add('(Son bilinen konum)');
      }
    } else {
      parcalar.add('Konum alınamadı.');
    }

    if (ekNot != null && ekNot.trim().isNotEmpty) {
      parcalar.add(ekNot.trim());
    }

    parcalar.add('— Depremin Nabzı uygulaması');
    return parcalar.join('\n');
  }

  /// "İyiyim" mesaji - sarsintidan sonra yakinlari rahatlatmak icin.
  static String iyiyimMesajiOlustur({required KonumSonucu konum}) {
    final parcalar = <String>['İyiyim, güvendeyim. Endişelenmeyin.'];
    if (konum.varMi) {
      parcalar.add('Konumum: ${konum.koordinatMetni}');
      parcalar.add(konum.haritaBaglantisi);
    }
    parcalar.add('— Depremin Nabzı uygulaması');
    return parcalar.join('\n');
  }

  // ------------------------------------------------------------------
  // SMS
  // ------------------------------------------------------------------

  /// SMS uygulamasini alicilar ve mesaj dolu olarak acar.
  ///
  /// Neden SMS onerilir?
  ///   Deprem aninda mobil veri ve Wi-Fi cokerken SMS altyapisi genelde
  ///   daha dayanikli kaliyor. Internet gerektirmeyen tek kanal.
  static Future<GonderimSonucu> smsAc({
    required List<AcilKisi> kisiler,
    required String mesaj,
  }) async {
    if (kisiler.isEmpty) return GonderimSonucu.kisiYok;

    // iOS coklu aliciyi virgul, Android noktali virgul ile ayirir.
    // Ikisini de kabul eden bicim: virgul (iOS) / ; (Android)
    // Guvenli yol: platforma gore ayirici sec.
    final ayirici = defaultTargetPlatform == TargetPlatform.iOS ? ',' : ';';
    final numaralar = kisiler.map((k) => k.temizTelefon).join(ayirici);

    // Govdeyi encode ediyoruz; satir sonlari ve Turkce karakterler
    // aksi halde bozulur
    final adres = Uri.parse(
      'sms:$numaralar?body=${Uri.encodeComponent(mesaj)}',
    );

    return _ac(adres);
  }

  // ------------------------------------------------------------------
  // WhatsApp
  // ------------------------------------------------------------------

  /// WhatsApp'i tek kisi icin acar.
  ///
  /// WhatsApp coklu alici desteklemiyor: her kisi icin ayri acmak
  /// gerekiyor. Arayuzde bu yuzden kisi kisi buton gosteriyoruz.
  static Future<GonderimSonucu> whatsappAc({
    required AcilKisi kisi,
    required String mesaj,
  }) async {
    final numara = kisi.whatsappTelefon;
    if (numara.isEmpty) return GonderimSonucu.hata;

    // wa.me evrensel baglanti: uygulama kuruluysa uygulamayi,
    // degilse tarayiciyi acar
    final adres = Uri.parse(
      'https://wa.me/$numara?text=${Uri.encodeComponent(mesaj)}',
    );

    return _ac(adres);
  }

  // ------------------------------------------------------------------
  // Telefon
  // ------------------------------------------------------------------

  /// Arama ekranini acar (numarayi yazar, otomatik ARAMAZ).
  static Future<GonderimSonucu> aramaAc(String numara) async {
    final temiz = AcilKisi.telefonTemizle(numara);
    if (temiz.isEmpty) return GonderimSonucu.hata;
    return _ac(Uri.parse('tel:$temiz'));
  }

  // ------------------------------------------------------------------
  // Pano
  // ------------------------------------------------------------------

  /// Mesaji panoya kopyalar. Her durumda calisan yedek yol.
  static Future<bool> panoyaKopyala(String mesaj) async {
    try {
      await Clipboard.setData(ClipboardData(text: mesaj));
      return true;
    } catch (e) {
      debugPrint('Panoya kopyalanamadi: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------

  static Future<GonderimSonucu> _ac(Uri adres) async {
    try {
      final acilabilir = await canLaunchUrl(adres);
      if (!acilabilir) return GonderimSonucu.uygulamaYok;

      final oldu = await launchUrl(
        adres,
        mode: LaunchMode.externalApplication,
      );
      return oldu ? GonderimSonucu.acildi : GonderimSonucu.hata;
    } catch (e) {
      debugPrint('Baglanti acilamadi ($adres): $e');
      return GonderimSonucu.hata;
    }
  }
}
