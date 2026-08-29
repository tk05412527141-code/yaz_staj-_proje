import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/acil_kisi.dart';
import '../services/acil_durum_servisi.dart';
import '../services/konum_servisi.dart';
import '../state/deprem_deposu.dart';
import '../utils/cam_tema.dart';
import '../utils/tema.dart';
import 'acil_kisi_ekle_ekrani.dart';

/// Acil durum ekrani: konum mesaji gonderme ve acil kisiler.
///
/// TASARIM KARARLARI
///   1. BASILI TUTMA: Butona tek dokunusla basilmasi kolay; yanlislikla
///      aileye acil mesaj gitmesi hem utanc verici hem "kurt masali"
///      etkisi yaratir. 1.5 saniye basili tutmak gerekiyor.
///
///   2. DURUSTLUK: Buton mesaji KENDI GONDERMEZ, SMS uygulamasini dolu
///      acar. Bu ekranda acikca yazili. Acil durumda kullanicinin
///      "gitti" sanip beklemesi gercek zarar dogurur.
///
///   3. KONUM SEFFAFLIGI: Konumun GPS'ten mi, son bilinen konumdan mi,
///      yoksa kayitli adresten mi geldigi gosteriliyor.
class AcilDurumEkrani extends StatefulWidget {
  final DepremDeposu depo;

  const AcilDurumEkrani({super.key, required this.depo});

  @override
  State<AcilDurumEkrani> createState() => _AcilDurumEkraniState();
}

class _AcilDurumEkraniState extends State<AcilDurumEkrani>
    with SingleTickerProviderStateMixin {
  late final AnimationController _basiliTutma;

  bool _hazirlaniyor = false;
  KonumSonucu? _sonKonum;

  static const _basiliTutmaSuresi = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _basiliTutma = AnimationController(
      vsync: this,
      duration: _basiliTutmaSuresi,
    )..addStatusListener((durum) {
        if (durum == AnimationStatus.completed) _acilDurumTetikle();
      });
  }

  @override
  void dispose() {
    _basiliTutma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.depo,
      builder: (context, _) {
        final kisiler = widget.depo.acilKisiler;

        // Bu sekme AnaKabuk'un GlassScaffold + CamGovde'si icinde
        // yasiyor; Material baglami ve zemin oradan geliyor.
        return SafeArea(
          bottom: false,
          child: ListView(
            // Alt bosluk: yuzen cam sekme cubugu icerigi kapatmasin.
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              CamOlculer.altBosluk(context) + 8,
            ),
            children: [
              const Text(
                'Acil Durum',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Renkler.metin,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                kisiler.isEmpty
                    ? 'Önce yakınlarını ekle. Butona bastığında konumun '
                        'onlara gidecek mesaja hazır olarak eklenir.'
                    : 'Butonu basılı tut: konumunu içeren mesaj '
                        '${kisiler.length} kişi için hazırlanır.',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Renkler.metinSolgun,
                ),
              ),
              const SizedBox(height: 26),
              _acilButon(kisiler),
              const SizedBox(height: 18),
              _kisitUyarisi(),
              const SizedBox(height: 20),
              _ikincilEylemler(kisiler),
              const SizedBox(height: 24),
              _kisilerBolumu(kisiler),
              const SizedBox(height: 22),
              _konumBilgisi(),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // Ana buton
  // ------------------------------------------------------------------

  Widget _acilButon(List<AcilKisi> kisiler) {
    final etkin = kisiler.isNotEmpty && !_hazirlaniyor;

    return Center(
      child: Semantics(
        button: true,
        enabled: etkin,
        label: etkin
            ? 'Acil durum mesajı. Göndermek için 1,5 saniye basılı tut.'
            : 'Acil durum mesajı. Önce acil kişi eklemelisin.',
        child: ExcludeSemantics(
          child: GestureDetector(
            onTapDown: etkin ? (_) => _basmaBasla() : null,
            onTapUp: (_) => _basmaBirak(),
            onTapCancel: _basmaBirak,
            child: AnimatedBuilder(
              animation: _basiliTutma,
              builder: (context, _) {
                final ilerleme = _basiliTutma.value;
                return SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Basili tutma ilerleme cemberi
                      GlassProgressIndicator.circular(
                        value: ilerleme,
                        size: 210,
                        strokeWidth: 6,
                        backgroundColor: Renkler.kenarlik,
                        color: const Color(0xFFF85149),
                      ),

                      // Buton govdesi: basili tuttukca cam kizariyor ve
                      // kalinlasiyor. Ilerleme hem cemberden hem camin
                      // renginden okunuyor - panik aninda tek gostergeye
                      // guvenmemek gerekiyor.
                      GlassCard(
                        width: 176,
                        height: 176,
                        padding: EdgeInsets.zero,
                        quality: GlassQuality.standard,
                        settings: etkin
                            ? CamAyar.vurgulu.copyWith(
                                glassColor: const Color(0xFFF85149)
                                    .withValues(alpha: 0.15 + ilerleme * 0.55),
                                thickness: 30 + ilerleme * 14,
                              )
                            : CamAyar.panel,
                        // Kendi katmani: yoksa buton basili tutulurken
                        // kizaran cam rengi yok sayilir.
                        useOwnLayer: true,
                        shape: LiquidOval(
                          side: BorderSide(
                            color: etkin
                                ? const Color(0xFFF85149)
                                : Renkler.kenarlik,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hazirlaniyor
                                  ? Icons.more_horiz
                                  : Icons.sos_rounded,
                              size: 46,
                              color: etkin ? Colors.white : Renkler.metinSolgun,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: Text(
                                _hazirlaniyor
                                    ? 'Konum alınıyor…'
                                    : (etkin ? 'BASILI TUT' : 'KİŞİ EKLE'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: etkin
                                      ? Colors.white
                                      : Renkler.metinSolgun,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _basmaBasla() {
    HapticFeedback.mediumImpact();
    _basiliTutma.forward();
  }

  void _basmaBirak() {
    if (_basiliTutma.status != AnimationStatus.completed) {
      _basiliTutma.reverse();
    }
  }

  // ------------------------------------------------------------------
  // Kisit uyarisi - gizlenmemesi gereken bilgi
  // ------------------------------------------------------------------

  Widget _kisitUyarisi() {
    return GlassCard(
      quality: GlassQuality.minimal,
      padding: const EdgeInsets.all(13),
      shape: const LiquidRoundedSuperellipse(borderRadius: 16),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 17, color: Renkler.metinSolgun),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mesaj kendiliğinden gönderilmez. Telefonun mesaj uygulaması '
              'alıcılar ve metin hazır şekilde açılır; son "gönder" '
              'dokunuşunu sen yaparsın. iOS ve Android bunu zorunlu kılıyor.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Renkler.metinSolgun,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Ikincil eylemler
  // ------------------------------------------------------------------

  Widget _ikincilEylemler(List<AcilKisi> kisiler) {
    return Row(
      children: [
        Expanded(
          child: _eylemKutusu(
            ikon: Icons.check_circle_outline,
            renk: Renkler.canli,
            baslik: 'İyiyim',
            altYazi: 'Yakınlarını rahatlat',
            onTap: kisiler.isEmpty ? null : _iyiyimGonder,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _eylemKutusu(
            ikon: Icons.local_phone_outlined,
            renk: const Color(0xFFF85149),
            baslik: '112',
            altYazi: 'Acil çağrı merkezi',
            onTap: _yuzOnIkiAra,
          ),
        ),
      ],
    );
  }

  Widget _eylemKutusu({
    required IconData ikon,
    required Color renk,
    required String baslik,
    required String altYazi,
    required VoidCallback? onTap,
  }) {
    final etkin = onTap != null;

    // "İyiyim" ve "112": her biri kendi renginde tonlanmis cam.
    // Devre disiyken cam notrlesip soluyor, dokunulamayacagi belli.
    return GlassButton.custom(
      onTap: onTap ?? () {},
      enabled: etkin,
      label: '$baslik, $altYazi',
      settings: etkin ? CamAyar.tonlu(renk, yogunluk: 0.16) : CamAyar.panel,
      useOwnLayer: true,
      shape: LiquidRoundedSuperellipse(
        borderRadius: 18,
        side: BorderSide(
          color: etkin ? renk.withValues(alpha: 0.4) : Renkler.kenarlik,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 24, color: etkin ? renk : Renkler.metinSolgun),
            const SizedBox(height: 8),
            Text(
              baslik,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: etkin ? Renkler.metin : Renkler.metinSolgun,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              altYazi,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: Renkler.metinSolgun,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Kisiler
  // ------------------------------------------------------------------

  Widget _kisilerBolumu(List<AcilKisi> kisiler) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ACİL KİŞİLER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Renkler.metinSolgun,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _kisiEkle(),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Ekle'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (kisiler.isEmpty)
          GlassCard(
            width: double.infinity,
            quality: GlassQuality.minimal,
            padding: const EdgeInsets.all(20),
            shape: const LiquidRoundedSuperellipse(borderRadius: 18),
            child: const Column(
              children: [
                Icon(Icons.person_add_alt,
                    size: 32, color: Renkler.metinSolgun),
                SizedBox(height: 12),
                Text(
                  'Henüz kişi eklemedin',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Renkler.metin,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Rehber izni istemiyoruz — numarayı elle gireceksin. '
                  'Kişiler yalnızca telefonunda saklanır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Renkler.metinSolgun,
                  ),
                ),
              ],
            ),
          )
        else
          for (final k in kisiler) ...[
            _kisiKarti(k),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _kisiKarti(AcilKisi kisi) {
    return GlassCard(
      quality: GlassQuality.minimal,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const LiquidRoundedSuperellipse(borderRadius: 18),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Renkler.yuzeyUst,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(
                kisi.ad.isNotEmpty ? kisi.ad[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Renkler.metin,
                ),
              ),
            ),
            title: Text(
              kisi.iliski.isEmpty ? kisi.ad : '${kisi.ad} · ${kisi.iliski}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              kisi.gosterimTelefon,
              style: const TextStyle(
                fontSize: 12.5,
                color: Renkler.metinSolgun,
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Renkler.metinSolgun),
              color: Renkler.yuzeyUst,
              onSelected: (secim) {
                if (secim == 'duzenle') {
                  _kisiEkle(duzenlenen: kisi);
                } else if (secim == 'sil') {
                  _silmeOnayi(kisi);
                } else if (secim == 'ara') {
                  AcilDurumServisi.aramaAc(kisi.telefon);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'ara', child: Text('Ara')),
                PopupMenuItem(value: 'duzenle', child: Text('Düzenle')),
                PopupMenuItem(value: 'sil', child: Text('Sil')),
              ],
            ),
          ),
          const GlassDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _whatsappGonder(kisi),
                    icon: const Icon(Icons.chat_outlined, size: 17),
                    label: const Text('WhatsApp'),
                    style: TextButton.styleFrom(
                      foregroundColor: Renkler.metinSolgun,
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => AcilDurumServisi.aramaAc(kisi.telefon),
                    icon: const Icon(Icons.phone_outlined, size: 17),
                    label: const Text('Ara'),
                    style: TextButton.styleFrom(
                      foregroundColor: Renkler.metinSolgun,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Konum bilgisi
  // ------------------------------------------------------------------

  Widget _konumBilgisi() {
    final k = _sonKonum;

    return GlassCard(
      quality: GlassQuality.minimal,
      padding: const EdgeInsets.all(13),
      shape: const LiquidRoundedSuperellipse(borderRadius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location,
                  size: 16, color: Renkler.metinSolgun),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  k == null
                      ? 'Konum yalnızca butona bastığında okunur'
                      : 'Son konum: ${k.kaynak.etiket}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Renkler.metin,
                  ),
                ),
              ),
            ],
          ),
          if (k != null && k.varMi) ...[
            const SizedBox(height: 6),
            Text(
              k.koordinatMetni +
                  (k.dogrulukM != null
                      ? '  ·  ±${k.dogrulukM!.round()} m'
                      : ''),
              style: const TextStyle(
                fontSize: 12,
                color: Renkler.metinSolgun,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Arka planda konum takibi yapılmaz, konumun hiçbir sunucuya '
            'gönderilmez.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: Renkler.metinSolgun,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Eylemler
  // ------------------------------------------------------------------

  Future<KonumSonucu> _konumHazirla() async {
    setState(() => _hazirlaniyor = true);

    // Kayitli "Yerlerim"in ilki yedek olarak kullanilir
    final yedek =
        widget.depo.konumlar.isNotEmpty ? widget.depo.konumlar.first : null;

    // Izin yoksa iste (kalici reddedildiyse istem gosterilmez, yedege duser)
    if (!await KonumServisi.izinVarMi()) {
      await KonumServisi.izinIste();
    }

    final konum = await KonumServisi.konumAl(
      yedekEnlem: yedek?.enlem,
      yedekBoylam: yedek?.boylam,
    );

    if (mounted) {
      setState(() {
        _hazirlaniyor = false;
        _sonKonum = konum;
      });
    }
    return konum;
  }

  Future<void> _acilDurumTetikle() async {
    HapticFeedback.heavyImpact();
    _basiliTutma.reset();

    final kisiler = widget.depo.acilKisiler;
    if (kisiler.isEmpty) return;

    final konum = await _konumHazirla();
    final mesaj = AcilDurumServisi.mesajOlustur(konum: konum);

    // Konum sorunluysa kullaniciyi bilgilendir ama mesaji ENGELLEMEyiz
    if (konum.mesaj != null && mounted) {
      _bilgi(konum.mesaj!);
    }

    final sonuc = await AcilDurumServisi.smsAc(
      kisiler: kisiler,
      mesaj: mesaj,
    );

    if (!mounted) return;

    if (sonuc != GonderimSonucu.acildi) {
      // SMS acilamadi: mesaji panoya kopyalayip kullaniciya soyle
      await AcilDurumServisi.panoyaKopyala(mesaj);
      if (!mounted) return;
      _bilgi(
        'Mesaj uygulaması açılamadı. Mesaj panoya kopyalandı — '
        'istediğin yere yapıştırabilirsin.',
        uzun: true,
      );
    }
  }

  Future<void> _iyiyimGonder() async {
    HapticFeedback.selectionClick();
    final kisiler = widget.depo.acilKisiler;
    if (kisiler.isEmpty) return;

    final konum = await _konumHazirla();
    final mesaj = AcilDurumServisi.iyiyimMesajiOlustur(konum: konum);

    final sonuc = await AcilDurumServisi.smsAc(
      kisiler: kisiler,
      mesaj: mesaj,
    );

    if (!mounted) return;
    if (sonuc != GonderimSonucu.acildi) {
      await AcilDurumServisi.panoyaKopyala(mesaj);
      if (!mounted) return;
      _bilgi('Mesaj panoya kopyalandı.');
    }
  }

  Future<void> _whatsappGonder(AcilKisi kisi) async {
    HapticFeedback.selectionClick();
    final konum = await _konumHazirla();
    final mesaj = AcilDurumServisi.mesajOlustur(konum: konum);

    final sonuc = await AcilDurumServisi.whatsappAc(
      kisi: kisi,
      mesaj: mesaj,
    );

    if (!mounted) return;
    if (sonuc == GonderimSonucu.uygulamaYok) {
      _bilgi('WhatsApp açılamadı. Kurulu olduğundan emin ol.');
    } else if (sonuc != GonderimSonucu.acildi) {
      await AcilDurumServisi.panoyaKopyala(mesaj);
      if (!mounted) return;
      _bilgi('Mesaj panoya kopyalandı.');
    }
  }

  Future<void> _yuzOnIkiAra() async {
    HapticFeedback.mediumImpact();

    final onay = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: Renkler.yuzey,
        title: const Text('112 aranacak'),
        content: const Text(
          'Arama ekranı 112 yazılı olarak açılacak. Aramayı sen '
          'başlatacaksın.\n\nGerçek bir acil durum yoksa aramayın — '
          'acil hatlar meşgul edilmemeli.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text(
              'Devam',
              style: TextStyle(color: Color(0xFFF85149)),
            ),
          ),
        ],
      ),
    );

    if (onay != true) return;
    final sonuc = await AcilDurumServisi.aramaAc('112');
    if (!mounted) return;
    if (sonuc != GonderimSonucu.acildi) {
      _bilgi('Arama ekranı açılamadı.');
    }
  }

  Future<void> _kisiEkle({AcilKisi? duzenlenen}) async {
    final sonuc = await Navigator.of(context).push<AcilKisi>(
      MaterialPageRoute(
        builder: (_) => AcilKisiEkleEkrani(duzenlenen: duzenlenen),
      ),
    );
    if (sonuc == null) return;

    HapticFeedback.mediumImpact();
    if (duzenlenen == null) {
      await widget.depo.acilKisiEkle(sonuc);
    } else {
      await widget.depo.acilKisiGuncelle(sonuc);
    }
  }

  Future<void> _silmeOnayi(AcilKisi kisi) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: Renkler.yuzey,
        title: const Text('Kişiyi sil'),
        content: Text('"${kisi.ad}" acil kişiler listesinden kaldırılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child:
                const Text('Sil', style: TextStyle(color: Color(0xFFF85149))),
          ),
        ],
      ),
    );

    if (onay == true) {
      HapticFeedback.mediumImpact();
      await widget.depo.acilKisiSil(kisi.id);
    }
  }

  void _bilgi(String mesaj, {bool uzun = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        duration: Duration(seconds: uzun ? 6 : 3),
      ),
    );
  }
}
