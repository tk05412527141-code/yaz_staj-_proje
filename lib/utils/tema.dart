import 'package:flutter/material.dart';

/// Uygulamanin renk paleti ve tema tanimi.
///
/// Tasarim yonu: koyu "izleme merkezi" gorunumu.
/// Koyu zeminde buyukluk renkleri one cikiyor, goz yormuyor ve
/// deprem/afet uygulamalarinin alistigi gorsel dile uyuyor.
class Renkler {
  const Renkler._();

  static const zemin = Color(0xFF0B0F14); // en arka plan
  static const yuzey = Color(0xFF151B23); // kartlar
  static const yuzeyUst = Color(0xFF1D2530); // kart uzeri ogeler
  static const kenarlik = Color(0xFF263140);

  static const metin = Color(0xFFE6EDF3);
  static const metinSolgun = Color(0xFF8B98A5);

  static const vurgu = Color(0xFFFF6B35); // turuncu - ana vurgu
  static const canli = Color(0xFF3FB950); // yesil - "canli" gostergesi
}

class Tema {
  const Tema._();

  static ThemeData koyu() {
    const semasi = ColorScheme.dark(
      primary: Renkler.vurgu,
      onPrimary: Colors.white,
      secondary: Renkler.vurgu,
      surface: Renkler.yuzey,
      onSurface: Renkler.metin,
      onSurfaceVariant: Renkler.metinSolgun,
      outline: Renkler.kenarlik,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: semasi,
      scaffoldBackgroundColor: Renkler.zemin,

      appBarTheme: const AppBarTheme(
        backgroundColor: Renkler.zemin,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Renkler.metin,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: Renkler.yuzey,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Renkler.kenarlik),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Renkler.yuzey,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Renkler.vurgu.withValues(alpha: 0.18),
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((durumlar) {
          final secili = durumlar.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
            color: secili ? Renkler.metin : Renkler.metinSolgun,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((durumlar) {
          final secili = durumlar.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: secili ? Renkler.vurgu : Renkler.metinSolgun,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Renkler.yuzeyUst,
        selectedColor: Renkler.vurgu,
        side: const BorderSide(color: Renkler.kenarlik),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Renkler.metin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Renkler.yuzeyUst,
        hintStyle: const TextStyle(color: Renkler.metinSolgun, fontSize: 15),
        prefixIconColor: Renkler.metinSolgun,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Renkler.kenarlik),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Renkler.kenarlik),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Renkler.vurgu, width: 1.5),
        ),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: Renkler.vurgu,
        thumbColor: Renkler.vurgu,
        inactiveTrackColor: Renkler.kenarlik,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: Renkler.metinSolgun,
        textColor: Renkler.metin,
      ),

      dividerTheme: const DividerThemeData(
        color: Renkler.kenarlik,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Renkler.yuzey,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Renkler.yuzeyUst,
        contentTextStyle: TextStyle(color: Renkler.metin),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
