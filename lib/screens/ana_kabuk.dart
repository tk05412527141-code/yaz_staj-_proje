import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/tercih_servisi.dart';
import '../state/deprem_deposu.dart';
import 'ayarlar_sekmesi.dart';
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

class _AnaKabukState extends State<AnaKabuk> {
  final _depo = DepremDeposu();
  int _sekme = 0;

  /// null = henuz bilinmiyor (tercihler okunuyor)
  bool? _tanitimGerekli;

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    // Tanitim kontrolu ile veri cekmeyi ayni anda baslatiyoruz;
    // kullanici tanitimi bitirdiginde liste hazir olsun.
    final goruldu = await TercihServisi.tanitimGoruldu();
    if (!mounted) return;
    setState(() => _tanitimGerekli = !goruldu);

    await _depo.baslat();
  }

  Future<void> _tanitimiBitir() async {
    await TercihServisi.tanitimiIsaretle();
    if (!mounted) return;
    setState(() => _tanitimGerekli = false);
  }

  @override
  void dispose() {
    _depo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tercihler okunana kadar kisa bir bekleme ekrani.
    // Tanitim gerekiyorsa listenin bir an gorunup kaybolmasini onler.
    if (_tanitimGerekli == null) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
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
          AyarlarSekmesi(depo: _depo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _sekme,
        onDestinationSelected: (i) {
          if (i != _sekme) HapticFeedback.selectionClick();
          setState(() => _sekme = i);
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
