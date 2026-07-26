import 'package:flutter/material.dart';

import '../utils/tema.dart';

/// Uygulama acilirken gosterilen animasyonlu giris ekrani.
///
/// TASARIM FIKRI
///   Logodaki sismik halkalar sabit bir goruntu. Animasyonda bu halkalari
///   logonun disina dogru YAYILAN canli halkalarla surduruyoruz — logo
///   sanki hala titresiyormus gibi duruyor ve gorsel dil butunlesiyor.
///
/// AKIS (toplam ~2.2 saniye)
///   0.0–0.7  logo hafif buyume + belirme
///   0.4–2.2  halkalar disari dogru yayilir (surekli)
///   0.7–1.2  uygulama adi ve alt yazi asagidan belirir
///   2.2      uygulamaya gecis
///
/// NOT: Bu Flutter tarafindaki acilis. Ondan once isletim sisteminin
/// gosterdigi yerel acilis ekrani var (Android launch_background.xml,
/// iOS LaunchScreen.storyboard). Ikisinin de zemini ayni koyu renk,
/// boylece gecis dikissiz gorunuyor.
class AcilisEkrani extends StatefulWidget {
  /// Animasyon bitince cagrilir.
  final VoidCallback onTamamlandi;

  const AcilisEkrani({super.key, required this.onTamamlandi});

  @override
  State<AcilisEkrani> createState() => _AcilisEkraniState();
}

class _AcilisEkraniState extends State<AcilisEkrani>
    with TickerProviderStateMixin {
  /// Tek seferlik giris animasyonu (logo + yazi)
  late final AnimationController _giris;

  /// Surekli tekrarlayan halka animasyonu
  late final AnimationController _halkalar;

  late final Animation<double> _logoOlcek;
  late final Animation<double> _logoSaydam;
  late final Animation<double> _yaziSaydam;
  late final Animation<Offset> _yaziKayma;

  @override
  void initState() {
    super.initState();

    _giris = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _halkalar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo: hafif kucukten baslayip yerine oturur (elasticOut yerine
    // easeOutBack - daha olculu, "ciddi uygulama" hissi bozulmasin)
    _logoOlcek = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _giris,
        curve: const Interval(0.0, 0.58, curve: Curves.easeOutBack),
      ),
    );

    _logoSaydam = CurvedAnimation(
      parent: _giris,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
    );

    _yaziSaydam = CurvedAnimation(
      parent: _giris,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _yaziKayma = Tween<Offset>(
      begin: const Offset(0, 0.55),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _giris,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _baslat();
  }

  Future<void> _baslat() async {
    _giris.forward();

    // Halkalar logo belirmeye baslayinca devreye girsin
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    _halkalar.repeat();

    await Future<void>.delayed(const Duration(milliseconds: 1820));
    if (!mounted) return;
    widget.onTamamlandi();
  }

  @override
  void dispose() {
    _giris.dispose();
    _halkalar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Renkler.zemin,
      body: Semantics(
        label: 'Depremin Nabzı açılıyor',
        child: ExcludeSemantics(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Logodan disari yayilan sismik halkalar
                      AnimatedBuilder(
                        animation: _halkalar,
                        builder: (context, _) => CustomPaint(
                          size: const Size(260, 260),
                          painter: _HalkaBoyayici(ilerleme: _halkalar.value),
                        ),
                      ),

                      // Logo
                      FadeTransition(
                        opacity: _logoSaydam,
                        child: ScaleTransition(
                          scale: _logoOlcek,
                          child: _logo(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 34),

                // Uygulama adi ve alt yazi
                FadeTransition(
                  opacity: _yaziSaydam,
                  child: SlideTransition(
                    position: _yaziKayma,
                    child: const Column(
                      children: [
                        Text(
                          'Depremin Nabzı',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: Renkler.metin,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Yerlerinizde ne kadar hissedilir?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Renkler.metinSolgun,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Renkler.vurgu.withValues(alpha: 0.22),
            blurRadius: 38,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          'assets/logo.png',
          width: 132,
          height: 132,
          fit: BoxFit.cover,
          // Gorsel yuklenemezse uygulama acilmaya devam etsin
          errorBuilder: (_, __, ___) => Container(
            color: Renkler.yuzey,
            alignment: Alignment.center,
            child: const Icon(Icons.public, size: 56, color: Renkler.vurgu),
          ),
        ),
      ),
    );
  }
}

/// Logonun cevresinde disari dogru yayilan halkalar.
///
/// Ayni anda uc halka var, aralarinda 1/3 faz farki. Her halka disari
/// dogru buyurken sonuyor; boylece kesintisiz bir dalga hissi olusuyor.
class _HalkaBoyayici extends CustomPainter {
  /// 0–1 arasi dongusel ilerleme
  final double ilerleme;

  const _HalkaBoyayici({required this.ilerleme});

  static const _halkaSayisi = 3;
  static const _baslangicYaricap = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    final merkez = Offset(size.width / 2, size.height / 2);
    final enBuyukYaricap = size.width / 2;

    for (var i = 0; i < _halkaSayisi; i++) {
      // Her halkayi esit araliklarla kaydir
      final faz = (ilerleme + i / _halkaSayisi) % 1.0;

      final yaricap =
          _baslangicYaricap + faz * (enBuyukYaricap - _baslangicYaricap);

      // Disa dogru giderken sonme
      final saydamlik = (1.0 - faz) * 0.5;
      if (saydamlik <= 0.01) continue;

      final firca = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - faz * 0.5)
        ..color = Renkler.vurgu.withValues(alpha: saydamlik);

      canvas.drawCircle(merkez, yaricap, firca);
    }
  }

  @override
  bool shouldRepaint(_HalkaBoyayici eski) => eski.ilerleme != ilerleme;
}
