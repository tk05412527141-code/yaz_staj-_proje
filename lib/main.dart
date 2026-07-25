import 'package:flutter/material.dart';

import 'screens/ana_ekran.dart';

void main() {
  runApp(const DepremTakipUygulamasi());
}

class DepremTakipUygulamasi extends StatelessWidget {
  const DepremTakipUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deprem Takip',
      debugShowCheckedModeBanner: false,

      // Acik tema
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
        ),
        useMaterial3: true,
      ),

      // Koyu tema - telefonun ayarina gore otomatik secilir
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,

      home: const AnaEkran(),
    );
  }
}
