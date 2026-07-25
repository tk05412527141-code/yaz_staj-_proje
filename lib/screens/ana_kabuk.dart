import 'package:flutter/material.dart';

import '../state/deprem_deposu.dart';
import 'ayarlar_sekmesi.dart';
import 'harita_sekmesi.dart';
import 'liste_sekmesi.dart';

/// Uygulamanin ana iskeleti: alt sekme cubugu ve sekmeler.
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

  @override
  void initState() {
    super.initState();
    _depo.baslat();
  }

  @override
  void dispose() {
    _depo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        onDestinationSelected: (i) => setState(() => _sekme = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Liste',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
