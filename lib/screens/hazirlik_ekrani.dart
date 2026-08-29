import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/hazirlik_maddesi.dart';
import '../services/bildirim_servisi.dart';
import '../services/hatirlatma_planlayici.dart';
import '../state/deprem_deposu.dart';
import '../utils/cam_tema.dart';
import '../utils/tema.dart';
import 'erken_uyari_ekrani.dart';

/// Deprem oncesi hazirlik kontrol listesi ve hatirlatma ayarlari.
///
/// Uygulamanin "deprem olmadan once" ise yarayan tek bolumu.
/// Kullanici bir maddeyi tamamladiginda periyodu dolunca hatirlatiliyor.
class HazirlikEkrani extends StatefulWidget {
  final DepremDeposu depo;

  const HazirlikEkrani({super.key, required this.depo});

  @override
  State<HazirlikEkrani> createState() => _HazirlikEkraniState();
}

class _HazirlikEkraniState extends State<HazirlikEkrani> {
  bool _izinVar = false;
  bool _izinKontrolEdildi = false;

  @override
  void initState() {
    super.initState();
    _izniKontrolEt();
  }

  Future<void> _izniKontrolEt() async {
    final var_ = await BildirimServisi.izinVarMi();
    if (!mounted) return;
    setState(() {
      _izinVar = var_;
      _izinKontrolEdildi = true;
    });
  }

  Future<void> _izinIste() async {
    HapticFeedback.selectionClick();
    final verildi = await BildirimServisi.izinIste();
    if (!mounted) return;

    setState(() => _izinVar = verildi);

    if (verildi) {
      await widget.depo.hatirlatmalariYenidenPlanla();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bildirim izni verilmedi. Telefon ayarlarından açabilirsin.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.depo,
      builder: (context, _) {
        final durum = widget.depo.hazirlik;

        return CamSayfa(
          baslik: 'Hazırlık',
          vurguRengi: Renkler.canli,
          govde: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              CamOlculer.ustBosluk(context) + 8,
              16,
              28,
            ),
            children: [
              _ilerlemeKarti(durum),
              const SizedBox(height: 16),
              if (_izinKontrolEdildi && !_izinVar) ...[
                _izinKarti(),
                const SizedBox(height: 16),
              ],
              _bolumBasligi('KONTROL LİSTESİ'),
              for (final madde in HazirlikListesi.tumu) ...[
                _maddeKarti(madde, durum),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              _hatirlatmaSaatiKarti(durum),
              const SizedBox(height: 16),
              _erkenUyariBaglantisi(),
              const SizedBox(height: 18),
              const Text(
                'İçerik AFAD ve Kızılay\'ın yaygın hazırlık önerilerine '
                'dayanır. Resmî kaynakları esas alın.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: Renkler.metinSolgun,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------

  Widget _ilerlemeKarti(HazirlikDurumu durum) {
    final oran = durum.ilerleme;
    final tamam = durum.tamamlananSayisi;
    final toplam = HazirlikListesi.tumu.length;

    final renk = oran >= 1.0
        ? Renkler.canli
        : (oran >= 0.5 ? const Color(0xFFE3B341) : Renkler.vurgu);

    return GlassCard(
      quality: GlassQuality.standard,
      settings: CamAyar.tonlu(renk, yogunluk: 0.13),
      useOwnLayer: true,
      padding: const EdgeInsets.all(16),
      shape: LiquidRoundedSuperellipse(
        borderRadius: 20,
        side: BorderSide(color: renk.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  oran >= 1.0
                      ? 'Hazırlığın tamam'
                      : 'Hazırlığın $tamam/$toplam',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: renk,
                  ),
                ),
              ),
              Text(
                '%${(oran * 100).round()}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: renk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: oran,
              minHeight: 7,
              backgroundColor: Renkler.yuzeyUst,
              valueColor: AlwaysStoppedAnimation(renk),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            oran >= 1.0
                ? 'Hepsini işaretledin. Periyodu gelince hatırlatacağız.'
                : 'Bir maddeyi yaptıysan işaretle; süresi dolunca '
                    'hatırlatalım.',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Renkler.metinSolgun,
            ),
          ),
        ],
      ),
    );
  }

  Widget _izinKarti() {
    return GlassCard(
      quality: GlassQuality.minimal,
      settings: CamAyar.tonlu(Renkler.vurgu, yogunluk: 0.16),
      useOwnLayer: true,
      padding: const EdgeInsets.all(14),
      shape: LiquidRoundedSuperellipse(
        borderRadius: 18,
        side: BorderSide(color: Renkler.vurgu.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: Renkler.vurgu, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Hatırlatmaların çalışması için bildirim izni gerekiyor.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Renkler.metin,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GlassButton.custom(
            onTap: _izinIste,
            label: 'İzin ver',
            height: 42,
            style: GlassButtonStyle.prominent,
            settings: CamAyar.tonlu(Renkler.vurgu, yogunluk: 0.22),
            useOwnLayer: true,
            shape: const LiquidRoundedSuperellipse(borderRadius: 21),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'İzin ver',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Renkler.metin,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _maddeKarti(HazirlikMaddesi madde, HazirlikDurumu durum) {
    final tamamlandi = durum.tamamlandiMi(madde.id);
    final gecikmis = HatirlatmaPlanlayici.gecikmisMi(
      madde: madde,
      durum: durum,
    );
    final hatirlatmaAcik = durum.hatirlatmaAcikMi(madde.id);

    final renk = gecikmis
        ? const Color(0xFFE3B341)
        : (tamamlandi ? Renkler.canli : Renkler.metinSolgun);

    return GlassCard(
      quality: GlassQuality.minimal,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const LiquidRoundedSuperellipse(borderRadius: 20),
      child: Column(
        children: [
          Semantics(
            button: true,
            checked: tamamlandi,
            label: '${madde.baslik}. '
                '${HatirlatmaPlanlayici.tamamlanmaMetni(madde: madde, durum: durum)}',
            child: ExcludeSemantics(
              child: InkWell(
                onTap: () => _tamamlanmaDegistir(madde, durum),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: tamamlandi
                              ? renk.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: tamamlandi ? renk : Renkler.kenarlik,
                            width: 1.6,
                          ),
                        ),
                        child: tamamlandi
                            ? Icon(Icons.check, size: 17, color: renk)
                            : null,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(madde.ikon,
                                    size: 16, color: Renkler.metinSolgun),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    madde.baslik,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: Renkler.metin,
                                    ),
                                  ),
                                ),
                                if (gecikmis)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: renk.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Süresi geçti',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: renk,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              madde.aciklama,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: Renkler.metinSolgun,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              HatirlatmaPlanlayici.tamamlanmaMetni(
                                madde: madde,
                                durum: durum,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: renk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const GlassDivider(),

          // Hatirlatma anahtari
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.alarm, size: 16, color: Renkler.metinSolgun),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    madde.periyotMetni + ' hatırlat',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Renkler.metinSolgun,
                    ),
                  ),
                ),
                // Renk temadan geliyor (colorScheme.primary). activeColor /
                // activeThumbColor Flutter surumleri arasinda degisti,
                // parametre vermeyerek surum bagimliligindan kaciniyoruz.
                GlassSwitch(
                  value: hatirlatmaAcik,
                  onChanged: (acik) => _hatirlatmaDegistir(madde, acik),
                  activeColor: Renkler.vurgu,
                  settings: CamAyar.kontrol,
                  useOwnLayer: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hatirlatmaSaatiKarti(HazirlikDurumu durum) {
    return GlassCard(
      quality: GlassQuality.minimal,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const LiquidRoundedSuperellipse(borderRadius: 20),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Hatırlatma saati'),
            subtitle: const Text(
              'Bildirimler günün bu saatinde gönderilir',
              style: TextStyle(color: Renkler.metinSolgun, fontSize: 12.5),
            ),
            trailing: Text(
              '${durum.hatirlatmaSaati.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Renkler.vurgu,
              ),
            ),
            onTap: () => _saatSec(durum),
          ),
          const GlassDivider(),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Test bildirimi gönder'),
            subtitle: const Text(
              'Bildirimlerin çalıştığını doğrula',
              style: TextStyle(color: Renkler.metinSolgun, fontSize: 12.5),
            ),
            onTap: _testBildirimi,
          ),
        ],
      ),
    );
  }

  Widget _erkenUyariBaglantisi() {
    return GlassCard(
      quality: GlassQuality.minimal,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const LiquidRoundedSuperellipse(borderRadius: 20),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Renkler.vurgu.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.crisis_alert, size: 20, color: Renkler.vurgu),
        ),
        title: const Text(
          'Erken uyarı nasıl alınır?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Bu uygulama erken uyarı veremez — nedenini ve ne yapman '
          'gerektiğini oku',
          style: TextStyle(
              color: Renkler.metinSolgun, fontSize: 12.5, height: 1.35),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ErkenUyariEkrani()),
        ),
      ),
    );
  }

  Widget _bolumBasligi(String yazi) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          yazi,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Renkler.metinSolgun,
          ),
        ),
      );

  // ------------------------------------------------------------------
  // Eylemler
  // ------------------------------------------------------------------

  Future<void> _tamamlanmaDegistir(
      HazirlikMaddesi madde, HazirlikDurumu durum) async {
    HapticFeedback.selectionClick();
    final simdiTamam = durum.tamamlandiMi(madde.id);
    await widget.depo.hazirlikMaddesiDegistir(madde.id, !simdiTamam);

    if (!mounted) return;
    if (!simdiTamam) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${madde.baslik} işaretlendi · '
              '${madde.periyotMetni.toLowerCase()} hatırlatılacak'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _hatirlatmaDegistir(HazirlikMaddesi madde, bool acik) async {
    HapticFeedback.selectionClick();

    // Hatirlatma aciliyorsa once izin gerekli
    if (acik && !_izinVar) {
      final verildi = await BildirimServisi.izinIste();
      if (!mounted) return;
      setState(() => _izinVar = verildi);
      if (!verildi) return;
    }

    await widget.depo.hatirlatmaDegistir(madde.id, acik);
  }

  Future<void> _saatSec(HazirlikDurumu durum) async {
    final secilen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: durum.hatirlatmaSaati, minute: 0),
      helpText: 'Hatırlatma saati',
      builder: (context, child) => MediaQuery(
        // 24 saat formati - Turkiye kullanimi
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (secilen == null) return;
    await widget.depo.hatirlatmaSaatiDegistir(secilen.hour);
  }

  Future<void> _testBildirimi() async {
    HapticFeedback.selectionClick();

    if (!_izinVar) {
      final verildi = await BildirimServisi.izinIste();
      if (!mounted) return;
      setState(() => _izinVar = verildi);
      if (!verildi) return;
    }

    final oldu = await BildirimServisi.hemenGoster(
      id: 9999,
      baslik: 'Bildirimler çalışıyor',
      govde: 'Hazırlık hatırlatmaların bu şekilde görünecek.',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          oldu
              ? 'Test bildirimi gönderildi'
              : 'Bildirim gönderilemedi. Telefon ayarlarını kontrol et.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
