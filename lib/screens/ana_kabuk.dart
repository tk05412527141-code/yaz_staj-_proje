import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/tercih_servisi.dart';
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

class _AnaKabukState extends State<AnaKabuk>
    with WidgetsBindingObserver {
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
    return Scaffold(
      body: IndexedStack(
        index: _sekme,
        children: [
          ListeSekmesi(depo: _depo),
          HaritaSekmesi(depo: _depo),
          DuyurularSekmesi(depo: _depo),
          AcilDurumEkrani(depo: _depo),
          AyarlarSekmesi(depo: _depo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _sekme,
        onDestinationSelected: (i) {
          if (i != _sekme) HapticFeedback.selectionClick();
          setState(() => _sekme = i);

          // IndexedStack sekmeleri bellekte tuttugu icin sekmeye
          // girmek kendiliginden yeni veri cekmiyor. Duyurulara
          // gecildiginde bayat veriyi tazeliyoruz.
          if (i == _duyuruSekmesi) _depo.duyurulariTazele();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Liste',
            tooltip: 'Deprem listesi',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
            tooltip: 'Harita görünümü',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Duyuru',
            tooltip: 'Resmî verilerden üretilen bültenler',
          ),
          NavigationDestination(
            icon: Icon(Icons.sos_outlined),
            selectedIcon: Icon(Icons.sos),
            label: 'Acil',
            tooltip: 'Acil durum: konum mesajı ve yakınlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
            tooltip: 'Ayarlar ve yerlerim',
          ),
        ],
      ),
    );
  }
}
