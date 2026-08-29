import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'tema.dart';

/// Liquid Glass (iOS 26) tasarim katmani.
///
/// Uygulamanin mantigi ve renk kimligi degismedi; burada sadece
/// cam yuzeylerin nasil gorunecegi tanimlaniyor.
///
/// Neden ayri dosya?
///   [Tema] Material tarafini (yazi, buton, giris alani) tarif ediyor.
///   Cam katmani bunun uzerine biniyor ve kendi ayarlarini istiyor.
///   Ikisini ayirinca hangi ayarin neyi etkiledigi karisimiyor.
///
/// Cam felsefesi (iOS 26):
///   Cam SADECE gezinme ve kontrol katmani icindir - ust cubuk, alt
///   sekme cubugu, yuzen butonlar, sayfalar. Icerik (liste satirlari,
///   deprem kartlari) opak kalir. Her seyi camlastirmak okunurlugu
///   bozar; deprem buyuklugu gibi kritik sayilar net gorunmeli.
class CamAyar {
  const CamAyar._();

  /// Gezinme cubuklari: ust bar, alt sekme cubugu.
  /// Kalin ve doygun - arkasindan gecen icerik belli olsun ama
  /// cubuktaki ikonlar okunur kalsin.
  static const cubuk = LiquidGlassSettings(
    thickness: 26,
    blur: 9,
    lightIntensity: 0.55,
    ambientStrength: 0.10,
    refractiveIndex: 1.22,
    saturation: 1.45,
    glassColor: Color(0x14FFFFFF),
  );

  /// Yuzen paneller: harita kontrolleri, durum karti, alt sayfalar.
  /// Cubuklardan biraz daha ince; icerigin uzerinde durdugu icin
  /// fazla kalin olursa altindaki harita kayboluyor.
  static const panel = LiquidGlassSettings(
    thickness: 20,
    blur: 8,
    lightIntensity: 0.5,
    ambientStrength: 0.08,
    refractiveIndex: 1.2,
    saturation: 1.35,
    glassColor: Color(0x0FFFFFFF),
  );

  /// Kucuk kontroller: cip, buton, anahtar.
  /// Ince ve keskin - dokunma hedefi kucuk oldugu icin parlama
  /// belirgin olmali ki basilabilir oldugu anlasilsin.
  static const kontrol = LiquidGlassSettings(
    thickness: 16,
    blur: 6,
    lightIntensity: 0.6,
    ambientStrength: 0.06,
    refractiveIndex: 1.25,
    saturation: 1.4,
    specularSharpness: GlassSpecularSharpness.sharp,
  );

  /// Vurgu yuzeyleri: acil durum butonu gibi dikkat cekmesi gerekenler.
  static const vurgulu = LiquidGlassSettings(
    thickness: 30,
    blur: 10,
    lightIntensity: 0.7,
    ambientStrength: 0.14,
    refractiveIndex: 1.3,
    saturation: 1.6,
    glassColor: Color(0x1AFF6B35),
  );

  /// Duruma gore renklenen cam.
  ///
  /// Ornegin durum karti: sakinken yesil, sarsinti varken buyukluk
  /// rengiyle tonlanmis cam. Renk bilgisi camin kendisine giriyor,
  /// ustune ayri bir katman koymaya gerek kalmiyor.
  static LiquidGlassSettings tonlu(Color renk, {double yogunluk = 0.12}) =>
      panel.copyWith(glassColor: renk.withValues(alpha: yogunluk));
}

class CamTema {
  const CamTema._();

  /// Uygulama genelindeki cam varsayilanlari.
  /// [LiquidGlassWidgets.wrap] icinde bir kez veriliyor; her widget
  /// tek tek ayarlanmak zorunda kalmiyor.
  static GlassThemeData veri() {
    const koyuDeger = GlassThemeVariant(
      settings: GlassThemeSettings(
        thickness: 24,
        blur: 8,
        lightIntensity: 0.55,
        ambientStrength: 0.08,
        refractiveIndex: 1.22,
        saturation: 1.4,
      ),
      quality: GlassQuality.standard,
      glowColors: GlassGlowColors(
        primary: Renkler.vurgu,
        success: Renkler.canli,
        danger: Color(0xFFE5484D),
        glowBlurRadius: 14,
        glowSpreadRadius: 0.3,
        glowOpacity: 0.75,
      ),
      borderRadius: 20,
    );

    // Uygulama her zaman koyu; iki varyant da ayni olsun ki sistem
    // acik temaya gecse bile cam ayarlari degismesin.
    return const GlassThemeData(light: koyuDeger, dark: koyuDeger);
  }
}

/// Cam cubuklarin kapladigi alanlar.
///
/// Alt sekme cubugu artik ekranin uzerinde YUZUYOR (iOS 26 davranisi),
/// yani icerigin altini kapatiyor. Kaydirilabilir listelerin sonuna bu
/// kadar bosluk birakmak gerekiyor, yoksa son deprem karti cubugun
/// altinda kaliyor ve okunamiyor.
class CamOlculer {
  const CamOlculer._();

  /// [GlassTabBar.bottom] varsayilan hap yuksekligi.
  static const cubukYuksekligi = 64.0;

  /// Hapin ust ve alt bosluğu (tek taraf).
  static const cubukDikeyBosluk = 18.0;

  /// Ust cubuk (GlassAppBar) varsayilan yuksekligi.
  static const ustCubukYuksekligi = 44.0;

  /// Alt sekme cubugunun kapladigi toplam yukseklik.
  static double altBosluk(BuildContext context) =>
      cubukYuksekligi +
      cubukDikeyBosluk * 2 +
      MediaQuery.paddingOf(context).bottom;

  /// Ust cam cubugun kapladigi toplam yukseklik (durum cubugu dahil).
  static double ustBosluk(BuildContext context) =>
      ustCubukYuksekligi + MediaQuery.paddingOf(context).top;
}

/// Cam yuzeylerin kirilma yapacagi arka plan.
///
/// Neden gerekli?
///   Cam, arkasindaki seyi bulaniklastirip kirarak gorunur olur.
///   Duz tek renk bir zeminde cam efekti "yok" gibi durur - kiracak
///   bir sey olmadigi icin. Bu yuzden koyu zemine, gozu yormayan
///   genis ve yumusak isik lekeleri koyuyoruz. Deprem uygulamasinin
///   ciddi tonunu bozmuyor ama cam canlaniyor.
class CamZemin extends StatelessWidget {
  const CamZemin({super.key, this.vurguRengi, this.yogunluk = 1.0});

  /// Ekrana ozel vurgu rengi (orn. acil ekraninda kirmizi).
  final Color? vurguRengi;

  /// Isik lekelerinin gucu. 0 = duz zemin, 1 = varsayilan.
  final double yogunluk;

  @override
  Widget build(BuildContext context) {
    final vurgu = vurguRengi ?? Renkler.vurgu;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10171F), Renkler.zemin, Color(0xFF070A0E)],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Ust sol: vurgu rengiyle sicak bir leke
          Positioned(
            top: -140,
            left: -100,
            child: _Leke(
              renk: vurgu.withValues(alpha: 0.20 * yogunluk),
              cap: 380,
            ),
          ),
          // Alt sag: soguk mavi karsi denge
          Positioned(
            bottom: -160,
            right: -120,
            child: _Leke(
              renk: const Color(0xFF2D6FB8).withValues(alpha: 0.18 * yogunluk),
              cap: 420,
            ),
          ),
          // Orta: cok soluk yesil - "canli veri" hissi
          Positioned(
            top: 260,
            right: -60,
            child: _Leke(
              renk: Renkler.canli.withValues(alpha: 0.07 * yogunluk),
              cap: 260,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cam iskeletin icine Material baglami tasiyan sarmalayici.
///
/// NEDEN GEREKLI?
///   [GlassScaffold] Cupertino tabanli calisiyor (CupertinoPageScaffold).
///   Yani agacta Material yok. ListTile, TextField, Divider, InkWell,
///   RefreshIndicator gibi Material widgetlari bunu sart kosuyor;
///   bulamayinca hem cokuyorlar hem de butun yazilarin altini SARI
///   cift cizgiyle ciziyorlar ("No Material widget found").
///
///   Seffaf bir Scaffold ikisini birden veriyor: Material baglamini ve
///   snackbar'larin ihtiyaci olan ScaffoldMessenger yuvasini. Zemini
///   seffaf oldugu icin arkadaki cam gradyanini gizlemiyor.
///
///   resizeToAvoidBottomInset kapali: klavye boslugunu disaridaki
///   CupertinoPageScaffold zaten uyguluyor, iki kez uygulanirsa
///   form ekranlarinda icerik gereginden fazla yukari itiliyor.
class CamGovde extends StatelessWidget {
  const CamGovde({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: child,
    );
  }
}

/// Cam cubuklara (ust bar, alt sekme cubugu) Material baglami tasir.
///
/// [GlassScaffold] cubuklari govdenin KARDESI olarak yerlestiriyor;
/// yani [CamGovde]'nin disinda kaliyorlar ve Material baglamini
/// alamiyorlar. Sonuc: sekme etiketlerinin ve baslik yazilarinin
/// altinda sari cift cizgi.
///
/// Neden duz `Material(...)` yetmiyor?
///   GlassScaffold, govdenin ust/alt boslugunu `cubuk is
///   PreferredSizeWidget` kontrolüyle cubugun kendi yuksekliginden
///   okuyor. Duz Material'a sarmak bu tipi kaybettiriyor ve cubuk
///   yuksekligi varsayilan 60'a dusuyor - icerik yanlis konumlaniyor.
///   [PreferredSize] hem seffaf Material veriyor hem de olcuyu
///   oldugu gibi aktariyor.
PreferredSizeWidget camCubuk(PreferredSizeWidget cubuk) {
  return PreferredSize(
    preferredSize: cubuk.preferredSize,
    child: Material(type: MaterialType.transparency, child: cubuk),
  );
}

/// Ustune acilan (push edilen) ekranlarin ortak cam iskeleti.
///
/// Detay, Yerlerim, Hazirlik gibi ekranlarin hepsi ayni yapiyi
/// istiyordu: zemin gradyani + cam ust cubuk + cam geri butonu.
/// Her ekranda tekrar yazmak yerine tek yerde topladik; boylece
/// gezinme cubugu her ekranda ayni davraniyor.
class CamSayfa extends StatelessWidget {
  const CamSayfa({
    super.key,
    required this.baslik,
    required this.govde,
    this.eylemler,
    this.vurguRengi,
    this.yuzenler,
  });

  final String baslik;

  /// Sayfa icerigi. Ust cubuk icerigin UZERINDE yuzdugu icin,
  /// kaydirilabilir govdelerin ustune [CamOlculer.ustBosluk] kadar
  /// bosluk konmali.
  final Widget govde;

  /// Ust cubugun sagindaki butonlar.
  final List<Widget>? eylemler;

  /// Zemin lekelerinin rengi (orn. acil ekranlarinda kirmizi).
  final Color? vurguRengi;

  /// Icerigin uzerinde duran ogeler (orn. yuzen ekleme butonu).
  final List<Widget>? yuzenler;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: CamZemin(vurguRengi: vurguRengi),
      statusBarStyle: GlassStatusBarStyle.light,
      settings: CamAyar.panel,
      bodyOverlays: yuzenler,
      appBar: camCubuk(GlassAppBar(
        leading: Semantics(
          button: true,
          label: 'Geri',
          child: ExcludeSemantics(
            child: GlassIconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 17,
                color: Renkler.metin,
              ),
              size: 40,
              settings: CamAyar.kontrol,
              useOwnLayer: true,
              glowColor: vurguRengi ?? Renkler.vurgu,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          baslik,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Renkler.metin,
          ),
        ),
        actions: eylemler,
      )),
      body: CamGovde(child: govde),
    );
  }
}

/// Yumusak kenarli tek bir isik lekesi.
class _Leke extends StatelessWidget {
  const _Leke({required this.renk, required this.cap});

  final Color renk;
  final double cap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cap,
      height: cap,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [renk, renk.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
