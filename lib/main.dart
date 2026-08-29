import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'screens/ana_kabuk.dart';
import 'utils/cam_tema.dart';
import 'utils/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cam yuzeyler fragment shader ile ciziliyor. initialize() bu
  // shaderlari runApp'ten once derliyor: ilk karedeki beyaz parlama
  // kalkiyor ve Vulkan desteklemeyen Android cihazlarda acilista
  // ANR olusmuyor.
  await LiquidGlassWidgets.initialize();

  // Durum cubugu ikonlarini acik renk yap - koyu zeminde okunur olsun.
  // Gezinme cubugu artik seffaf: alt sekme cubugu cam oldugu icin
  // arkasindaki icerigin gorunmesi gerekiyor.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(LiquidGlassWidgets.wrap(
    child: const DepremTakipUygulamasi(),
    // MaterialApp kullaniyoruz: cam widgetlari cihazin ham parlakligina
    // degil, uygulamanin ThemeMode'una baksin. Bu satir olmazsa cihaz
    // acik temadayken golge ve kenarliklar kayboluyor.
    brightnessResolver: Theme.maybeBrightnessOf,
    theme: CamTema.veri(),
  ));
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
