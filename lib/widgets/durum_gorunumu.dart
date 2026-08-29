import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../utils/cam_tema.dart';
import '../utils/tema.dart';

/// Bos liste, hata gibi durumlarda gosterilen ortak ekran.
///
/// Iyi bir bos/hata ekrani su uc soruya cevap verir:
///   1. Ne oldu?
///   2. Neden oldu?
///   3. Simdi ne yapabilirim?
/// Bu yuzden her zaman bir eylem butonu var.
class DurumGorunumu extends StatelessWidget {
  final IconData ikon;
  final Color? ikonRengi;
  final String baslik;
  final String aciklama;
  final String eylemYazisi;
  final VoidCallback onEylem;

  /// Isteğe bagli ikincil eylem (orn. "Filtreleri sıfırla")
  final String? ikinciEylemYazisi;
  final VoidCallback? onIkinciEylem;

  const DurumGorunumu({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.eylemYazisi,
    required this.onEylem,
    this.ikonRengi,
    this.ikinciEylemYazisi,
    this.onIkinciEylem,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: (ikonRengi ?? Renkler.vurgu).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, size: 38, color: ikonRengi ?? Renkler.vurgu),
            ),
            const SizedBox(height: 20),
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Renkler.metin,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              aciklama,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Renkler.metinSolgun,
              ),
            ),
            const SizedBox(height: 24),
            // Ana eylem: prominent cam. Bos/hata ekraninda tek cikis
            // yolu bu buton oldugu icin ekrandaki en kalin yuzey o.
            GlassButton.custom(
              onTap: onEylem,
              label: eylemYazisi,
              height: 50,
              style: GlassButtonStyle.prominent,
              settings: CamAyar.tonlu(ikonRengi ?? Renkler.vurgu),
              useOwnLayer: true,
              shape: const LiquidRoundedSuperellipse(borderRadius: 25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 18,
                      color: ikonRengi ?? Renkler.vurgu,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      eylemYazisi,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Renkler.metin,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ikinciEylemYazisi != null && onIkinciEylem != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onIkinciEylem,
                child: Text(
                  ikinciEylemYazisi!,
                  style: const TextStyle(color: Renkler.metinSolgun),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
