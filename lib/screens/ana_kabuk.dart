import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/tercih_servisi.dart';
import '../utils/cam_tema.dart';
import '../utils/tema.dart';
import '../state/deprem_deposu.dart';
import 'acilis_ekrani.dart';
import 'acil_durum_ekrani.dart';
import 'ayarlar_sekmesi.dart';
import 'duyurular_sekmesi.dart';
import 'harita_sekmesi.dart';
import 'liste_sekmesi.dart';
import 'tanitim_ekrani.dart';

/// Uygulamanin ana iskeleti: ilk acilis kontrolu, alt sekme cubugu.
///
/// Neden alt sekme?
///   Telefonda basparmak ekranin altina rahat ulasir. Ust cubuktaki
///   ikonlara uzanmak buyuk ekranlarda zordur. Ayrica sekmeler
///   uygulamanin nelerden olustugunu ilk bakista gosterir.
///
/// Uc sekme de AYNI [DepremDeposu] ornegini paylasiyor. Bu sayede
/// listede uygulanan filtre haritada da gecerli oluyor ve veri
/// bir kez cekiliyor.
class AnaKabuk extends StatefulWidget {
  const AnaKabuk({super.key});

  @override
  State<AnaKabuk> createState() => _AnaKabukState();
}

class _AnaKabukState extends State<AnaKabuk> with WidgetsBindingObserver {
  final _depo = DepremDeposu();
  int _sekme = 0;

  /// null = henuz bilinmiyor (tercihler okunuyor)
  bool? _tanitimGerekli;

  /// Acilis animasyonu bitti mi?
  bool _acilisBitti = false;

  /// Duyurular sekmesinin IndexedStack icindeki sirasi.
  static const _duyuruSekmesi = 2;

  @override
  void initState() {
    super.initState();
    // Uygulama on plana dondugunde haberleri tazelemek icin dinliyoruz
    WidgetsBinding.instance.addObserver(this);
    _baslat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState durum) {
    // Kullanici uygulamayi arka plandan geri getirdiginde veri bayat
    // olabilir. Bayatsa tazeliyoruz; taze ise istek atilmiyor.
    if (durum == AppLifecycleState.resumed) {
      // On plana donunce: bayat duyurulari tazele ve periyodik
      // yenilemeyi yeniden baslat
      _depo.duyurulariTazele();
      _depo.yenile();
      _depo.periyodikBaslat();
    } else if (durum == AppLifecycleState.paused ||
        durum == AppLifecycleState.detached) {
      // Arka planda istek atmak pil ve veri israfi
      _depo.periyodikDurdur();
    }
  }

  Future<void> _baslat() async {
    // Acilis animasyonu oynarken tercihleri okuyup veriyi cekiyoruz.
    // Boylece animasyon "bosa gecen zaman" olmuyor; kullanici ekrani
    // izlerken liste arka planda hazirlaniyor.
    final goruldu = await TercihServisi.tanitimGoruldu();
    if (!mounted) return;
    setState(() => _tanitimGerekli = !goruldu);

    await _depo.baslat();
    if (!mounted) return;
    // Ilk veri geldikten sonra periyodik yenilemeyi baslat
    _depo.periyodikBaslat();
  }

  Future<void> _tanitimiBitir() async {
    await TercihServisi.tanitimiIsaretle();
    if (!mounted) return;
    setState(() => _tanitimGerekli = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _depo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Once acilis animasyonu. Animasyon suresi boyunca veri cekimi
    // arka planda devam ediyor.
    if (!_acilisBitti || _tanitimGerekli == null) {
      return AcilisEkrani(
        onTamamlandi: () {
          if (mounted) setState(() => _acilisBitti = true);
        },
      );
    }

    if (_tanitimGerekli == true) {
      return TanitimEkrani(depo: _depo, onTamamlandi: _tanitimiBitir);
    }

    // IndexedStack: sekme degistirince ekranlar bastan olusmaz,
    // kaydirma konumu ve harita gorunumu korunur.
    //
    // GlassScaffold: zemin gradyani, cam katmani, cubuklarin z-sirasi ve
    // kenar solmasi tek widget'ta hallediliyor. Alt cubuk artik icerigin
    // uzerinde yuzen bir cam hap; sekmeler zeminin uzerinden gecerken
    // arkasindaki liste bulaniklasarak goruluyor.
    return GlassScaffold(
      background: const CamZemin(),
      statusBarStyle: GlassStatusBarStyle.light,
      settings: CamAyar.panel,
      // CamGovde: sekmelerdeki ListTile, TextField, RefreshIndicator gibi
      // Material widgetlari cam iskelet icinde de calissin diye.
      body: CamGovde(
        child: IndexedStack(
          index: _sekme,
          children: [
            ListeSekmesi(depo: _depo),
            HaritaSekmesi(depo: _depo),
            DuyurularSekmesi(depo: _depo),
            AcilDurumEkrani(depo: _depo),
            AyarlarSekmesi(depo: _depo),
          ],
        ),
      ),
      // Ust kenar solmasi kapali: sekmelerin kendi basliklari var,
      // ust tarafta gizlenecek bir cubuk yok.
      topEdgeFade: false,
      bottomEdgeFadeExtent: 12,
      bottomBar: camCubuk(GlassTabBar.bottom(
        selectedIndex: _sekme,
        onTabSelected: (i) {
          if (i != _sekme) HapticFeedback.selectionClick();
          setState(() => _sekme = i);

          // IndexedStack sekmeleri bellekte tuttugu icin sekmeye
          // girmek kendiliginden yeni veri cekmiyor. Duyurulara
          // gecildiginde bayat veriyi tazeliyoruz.
          if (i == _duyuruSekmesi) _depo.duyurulariTazele();
        },
        // Bes sekme dar telefonlara da sigsin diye yatay boslugu ve
        // yazi boyutunu kisiyoruz.
        horizontalPadding: 14,
        verticalPadding: CamOlculer.cubukDikeyBosluk,
        spacing: 2,
        tabPadding: const EdgeInsets.symmetric(horizontal: 2),
        iconSize: 22,
        labelFontSize: 10,
        settings: CamAyar.cubuk,
        indicatorColor: Renkler.vurgu.withValues(alpha: 0.30),
        selectedIconColor: Renkler.vurgu,
        unselectedIconColor: Renkler.metinSolgun,
        selectedLabelColor: Renkler.metin,
        unselectedLabelColor: Renkler.metinSolgun,
        tabs: const [
          GlassTab(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Liste',
            semanticLabel: 'Deprem listesi',
            glowColor: Renkler.vurgu,
          ),
          GlassTab(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Harita',
            semanticLabel: 'Harita görünümü',
            glowColor: Renkler.vurgu,
          ),
          GlassTab(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Duyuru',
            semanticLabel: 'Resmî verilerden üretilen bültenler',
            glowColor: Renkler.vurgu,
          ),
          GlassTab(
            icon: Icon(Icons.sos_outlined),
            activeIcon: Icon(Icons.sos),
            label: 'Acil',
            semanticLabel: 'Acil durum: konum mesajı ve yakınlar',
            // Acil sekmesi kirmizi parliyor: panik aninda gozun
            // dogru yere gitmesi icin renk kodlamasi.
            glowColor: Color(0xFFE5484D),
          ),
          GlassTab(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ayarlar',
            semanticLabel: 'Ayarlar ve yerlerim',
            glowColor: Renkler.vurgu,
          ),
        ],
      )),
    );
  }
}
