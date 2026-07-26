import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/ana_kabuk.dart';
import 'utils/tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Durum cubugu ikonlarini acik renk yap - koyu zeminde okunur olsun.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Renkler.yuzey,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const DepremTakipUygulamasi());
}

class DepremTakipUygulamasi extends StatelessWidget {
  const DepremTakipUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Depremin Nabzı',
      debugShowCheckedModeBanner: false,

      // Uygulama koyu tema uzerine tasarlandi; sistem ayarindan
      // bagimsiz olarak her zaman koyu gorunur.
      theme: Tema.koyu(),
      darkTheme: Tema.koyu(),
      themeMode: ThemeMode.dark,

      home: const AnaKabuk(),
    );
  }
}
