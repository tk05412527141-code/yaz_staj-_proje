import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/deprem.dart';
import '../services/deprem_servisi.dart';
import '../state/deprem_deposu.dart';
import '../utils/buyukluk_stili.dart';
import '../utils/cam_tema.dart';
import '../utils/gun_gruplama.dart';
import '../utils/tema.dart';
import '../widgets/deprem_karti.dart';
import '../widgets/durum_karti.dart';
import '../widgets/durum_gorunumu.dart';
import '../widgets/filtre_sayfasi.dart';
import '../widgets/iskelet_kart.dart';
import 'detay_ekrani.dart';
import 'yerlerim_ekrani.dart';

/// Ana sekme: kisisel ozet, arama, hizli filtreler ve deprem listesi.
class ListeSekmesi extends StatefulWidget {
  final DepremDeposu depo;

  const ListeSekmesi({super.key, required this.depo});

  @override
  State<ListeSekmesi> createState() => _ListeSekmesiState();
}

class _ListeSekmesiState extends State<ListeSekmesi> {
  final _aramaKontrolcu = TextEditingController();

  @override
  void dispose() {
    _aramaKontrolcu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depo = widget.depo;

    return ListenableBuilder(
      listenable: depo,
      builder: (context, _) {
        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              _baslikBolumu(depo),
              _aramaVeFiltre(depo),
              _hizliFiltreler(depo),
              Expanded(child: _icerik(depo)),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // Baslik
  // ------------------------------------------------------------------

  Widget _baslikBolumu(DepremDeposu depo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              label: 'Son Depremler. Kaynak ${depo.kaynak.ad}. '
                  '${depo.sonGuncellemeMetni}',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Son Depremler',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Renkler.metin,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: depo.hata == null
                                ? Renkler.canli
                                : Renkler.metinSolgun,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            // Otomatik modda hangi kaynagin secildigini
                            // gostermek onemli: kullanici verinin nereden
                            // geldigini bilmeli
                            '${depo.kullanilanKaynak?.ad ?? depo.kaynak.ad}'
                            ' · son kayıt ${depo.tazelikMetni}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Renkler.metinSolgun,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Yenile: yuvarlak cam buton. Dokununca cam esniyor (jelly)
          // ve parliyor - dokunusun kaydedildigi anlasiliyor.
          Semantics(
            button: true,
            label: 'Yenile',
            child: ExcludeSemantics(
              child: GlassIconButton(
                icon: Icon(
                  Icons.refresh,
                  size: 20,
                  color: depo.yukleniyor ? Renkler.kenarlik : Renkler.metin,
                ),
                // Dokunma hedefi en az 48x48 - erisilebilirlik gerekliligi
                size: 48,
                settings: CamAyar.kontrol,
                useOwnLayer: true,
                glowColor: Renkler.vurgu,
                onPressed: depo.yukleniyor
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        depo.yenile();
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Arama + filtre butonu
  // ------------------------------------------------------------------

  Widget _aramaVeFiltre(DepremDeposu depo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          // GlassSearchBar temizleme butonunu kendi yonetiyor; ayri bir
          // suffixIcon kurmaya gerek kalmadi.
          Expanded(
            child: GlassSearchBar(
              controller: _aramaKontrolcu,
              placeholder: 'Şehir veya bölge ara',
              onChanged: depo.aramaDegistir,
              height: 52,
              settings: CamAyar.kontrol,
              useOwnLayer: true,
              searchIconColor: Renkler.metinSolgun,
              clearIconColor: Renkler.metinSolgun,
              textStyle: const TextStyle(fontSize: 15, color: Renkler.metin),
              placeholderStyle: const TextStyle(
                fontSize: 15,
                color: Renkler.metinSolgun,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _filtreButonu(depo),
        ],
      ),
    );
  }

  Widget _filtreButonu(DepremDeposu depo) {
    final aktif = depo.aktifFiltreSayisi;

    return Semantics(
      button: true,
      label: aktif > 0 ? 'Filtreler, $aktif filtre aktif' : 'Filtreler',
      // Aktif filtre sayisi GlassBadge ile gosteriliyor: elle konumlanan
      // Stack yerine widget'in kendi rozet mekanizmasi.
      child: ExcludeSemantics(
        child: GlassBadge(
          count: aktif,
          backgroundColor: Renkler.vurgu,
          textColor: Colors.white,
          child: GlassIconButton(
            icon: Icon(
              Icons.tune,
              size: 21,
              color: aktif > 0 ? Renkler.vurgu : Renkler.metinSolgun,
            ),
            size: 52,
            shape: GlassIconButtonShape.roundedSquare,
            borderRadius: 18,
            settings: aktif > 0
                ? CamAyar.tonlu(Renkler.vurgu, yogunluk: 0.20)
                : CamAyar.kontrol,
            useOwnLayer: true,
            glowColor: Renkler.vurgu,
            onPressed: () {
              HapticFeedback.selectionClick();
              FiltreSayfasi.ac(context, depo);
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Hizli filtre seridi
  // ------------------------------------------------------------------

  Widget _hizliFiltreler(DepremDeposu depo) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        itemCount: HizliFiltre.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = HizliFiltre.values[i];
          final secili = depo.hizliFiltre == f;
          final esikRengi = f.esik == null ? null : BuyuklukStili.renk(f.esik!);
          final yerFiltresi = f == HizliFiltre.yerlerim;

          // Esik rengi olan filtreler (3.0+, 4.5+) camin kendisini o
          // renge boyuyor: hangi siddet sinifini sectigin cipin
          // renginden anlasiliyor, ayrica yazida sayi da duruyor.
          final camRengi = secili ? (esikRengi ?? Renkler.vurgu) : null;

          return Semantics(
            button: true,
            selected: secili,
            label: '${f.etiket} filtresi',
            child: ExcludeSemantics(
              child: GlassChip(
                selected: secili,
                label: f.esik == null
                    ? f.etiket
                    : '${f.etiket} ${f.esik!.toStringAsFixed(1)}+',
                icon: yerFiltresi
                    ? Icon(
                        depo.konumVar
                            ? Icons.place
                            : Icons.add_location_alt_outlined,
                        size: 14,
                      )
                    : (esikRengi != null
                        ? Icon(Icons.circle, size: 8, color: esikRengi)
                        : null),
                iconColor: secili ? Renkler.metin : Renkler.metinSolgun,
                selectedColor: camRengi?.withValues(alpha: 0.35),
                settings: camRengi == null
                    ? CamAyar.kontrol
                    : CamAyar.tonlu(camRengi, yogunluk: 0.18),
                useOwnLayer: true,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                  color: secili ? Renkler.metin : Renkler.metinSolgun,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  // "Yerlerim" ancak kayitli bir yer varsa anlamli
                  if (yerFiltresi && !depo.konumVar) {
                    _yerlerimAc(depo);
                    return;
                  }
                  depo.hizliFiltreDegistir(f);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // Icerik
  // ------------------------------------------------------------------

  Widget _icerik(DepremDeposu depo) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: _icerikSecimi(depo),
    );
  }

  Widget _icerikSecimi(DepremDeposu depo) {
    if (depo.yukleniyor) {
      return const IskeletListe(key: ValueKey('iskelet'));
    }

    if (depo.hata != null) {
      return DurumGorunumu(
        key: const ValueKey('hata'),
        ikon: Icons.cloud_off_rounded,
        ikonRengi: const Color(0xFFF85149),
        baslik: 'Veriye ulaşılamadı',
        aciklama: depo.hata!,
        eylemYazisi: 'Tekrar dene',
        onEylem: depo.yenile,
        ikinciEylemYazisi:
            depo.kaynak == VeriKaynagi.otomatik ? null : 'Otomatik kaynağa geç',
        onIkinciEylem: depo.kaynak == VeriKaynagi.otomatik
            ? null
            : () => depo.kaynakDegistir(VeriKaynagi.otomatik),
      );
    }

    final liste = depo.liste;

    if (liste.isEmpty) {
      final filtreVar = depo.aktifFiltreSayisi > 0;
      return DurumGorunumu(
        key: const ValueKey('bos'),
        ikon: filtreVar ? Icons.filter_alt_off_outlined : Icons.inbox_outlined,
        baslik: 'Sonuç bulunamadı',
        aciklama: filtreVar
            ? 'Seçtiğin filtrelere uyan deprem yok. Zaman aralığını '
                'genişletmeyi veya minimum büyüklüğü düşürmeyi dene.'
            : 'Bu aralıkta kayıt bulunamadı. Veri kaynağı gecikmeli '
                'olabilir; diğer kaynağı deneyebilirsin.',
        eylemYazisi: 'Yenile',
        onEylem: depo.yenile,
        ikinciEylemYazisi: filtreVar ? 'Filtreleri sıfırla' : null,
        onIkinciEylem: filtreVar ? depo.filtreleriSifirla : null,
      );
    }

    return RefreshIndicator(
      key: const ValueKey('liste'),
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await depo.yenile();
      },
      color: Renkler.vurgu,
      backgroundColor: Renkler.yuzey,
      child: CustomScrollView(
        slivers: _sliverlar(depo, liste),
      ),
    );
  }

  /// Listeyi gunlere ayirip yapiskan basliklarla birlikte olusturur.
  ///
  /// Buyukluge gore siralamada gun gruplamasi anlamsizlasir (ayni gunun
  /// depremleri dagilir), o yuzden bu durumda duz liste kullaniyoruz.
  List<Widget> _sliverlar(DepremDeposu depo, List<Deprem> liste) {
    final sliverlar = <Widget>[
      // Secili kaynak zaman araligini karsilayamiyorsa uyar.
      // Sessizce calismayan bir filtre, bozuk bir filtreden daha
      // yanilticidir: kullanici 30 gun sanip 24 saat gorur.
      if (depo.veriGecikmeli) SliverToBoxAdapter(child: _gecikmeUyarisi(depo)),
      if (depo.kapsamUyarisiVar)
        SliverToBoxAdapter(child: _kapsamUyarisi(depo)),
      SliverToBoxAdapter(
        child: DurumKarti(
          depo: depo,
          onYerEkle: () => _yerlerimAc(depo),
          onDetay: () => _yerlerimAc(depo),
        ),
      ),
      SliverToBoxAdapter(child: _ozetSatiri(depo, liste)),
    ];

    if (depo.siralama == Siralama.buyukluk) {
      sliverlar.add(_kartListesi(depo, liste));
    } else {
      final gruplar = GunGruplama.grupla(liste);
      for (final grup in gruplar) {
        sliverlar.add(
          SliverPersistentHeader(
            pinned: true,
            delegate: _GunBasligiDelegate(
              baslik: grup.baslik,
              adet: grup.depremler.length,
            ),
          ),
        );
        sliverlar.add(_kartListesi(depo, grup.depremler));
      }
    }

    // Alt sekme cubugu artik listenin UZERINDE yuzuyor. Son kartin
    // cubugun altinda kalmamasi icin cubuk yuksekligi kadar bosluk.
    sliverlar.add(
      SliverToBoxAdapter(
        child: SizedBox(height: CamOlculer.altBosluk(context) + 8),
      ),
    );
    return sliverlar;
  }

  Widget _kartListesi(DepremDeposu depo, List<Deprem> depremler) {
    return SliverList.builder(
      itemCount: depremler.length,
      itemBuilder: (context, i) {
        final deprem = depremler[i];
        return DepremKarti(
          deprem: deprem,
          etki: depo.enYakinEtki(deprem),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetayEkrani(deprem: deprem, depo: depo),
              ),
            );
          },
        );
      },
    );
  }

  /// Kaynak belirgin sekilde gecikmeliyse uyar.
  ///
  /// Olcum sirasinda AFAD'in 11.5 saat geriden geldigi goruldu.
  /// Kullanicinin "son deprem 12 saat once" diye dusunup yanilmamasi
  /// icin bunu acikca soylemek gerekiyor.
  Widget _gecikmeUyarisi(DepremDeposu depo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GlassCard(
        quality: GlassQuality.minimal,
        settings: CamAyar.tonlu(const Color(0xFFF85149), yogunluk: 0.16),
        useOwnLayer: true,
        padding: const EdgeInsets.all(12),
        shape: const LiquidRoundedSuperellipse(
          borderRadius: 14,
          side: BorderSide(color: Color(0x59F85149)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 17, color: Color(0xFFF85149)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${depo.kullanilanKaynak?.ad ?? "Kaynak"} gecikmeli: '
                'en yeni kayıt ${depo.tazelikMetni}. '
                'Bu süre içinde olan depremler henüz görünmüyor olabilir.',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Renkler.metin,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kapsamUyarisi(DepremDeposu depo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GlassCard(
        quality: GlassQuality.minimal,
        settings: CamAyar.tonlu(const Color(0xFFE3B341), yogunluk: 0.16),
        useOwnLayer: true,
        padding: const EdgeInsets.all(12),
        shape: const LiquidRoundedSuperellipse(
          borderRadius: 14,
          side: BorderSide(color: Color(0x59E3B341)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 17, color: Color(0xFFE3B341)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                depo.kapsamUyarisi!,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Renkler.metin,
                ),
              ),
            ),
            if (depo.kaynak == VeriKaynagi.kandilli) ...[
              const SizedBox(width: 6),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  depo.kaynakDegistir(VeriKaynagi.afad);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('AFAD\'a geç'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ozetSatiri(DepremDeposu depo, List<Deprem> liste) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Row(
        children: [
          Text(
            '${liste.length} deprem',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Renkler.metin,
            ),
          ),
          if (liste.isNotEmpty) ...[
            const Text(' · ',
                style: TextStyle(color: Renkler.metinSolgun, fontSize: 13)),
            const Text(
              'en büyük ',
              style: TextStyle(fontSize: 13, color: Renkler.metinSolgun),
            ),
            Text(
              depo.enBuyuk.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: BuyuklukStili.renk(depo.enBuyuk),
              ),
            ),
          ],
          const Spacer(),
          Text(
            depo.siralama.etiket,
            style: const TextStyle(fontSize: 12, color: Renkler.metinSolgun),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------

  void _yerlerimAc(DepremDeposu depo) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => YerlerimEkrani(depo: depo)),
    );
  }
}

/// Kaydirirken ekranin ustune yapisan gun basligi.
class _GunBasligiDelegate extends SliverPersistentHeaderDelegate {
  final String baslik;
  final int adet;

  const _GunBasligiDelegate({required this.baslik, required this.adet});

  static const _yukseklik = 38.0;

  @override
  double get minExtent => _yukseklik;

  @override
  double get maxExtent => _yukseklik;

  @override
  Widget build(BuildContext context, double kayma, bool araliktaMi) {
    // Yapiskan gun basligi da cam: altindan gecen kartlar bulaniklasarak
    // goruluyor ama baslik yazisi okunur kaliyor. Opak seritler cam
    // tasarimda "delik" gibi duruyordu.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: _yukseklik,
          color: Renkler.zemin.withValues(alpha: 0.55),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          alignment: Alignment.centerLeft,
          child: Semantics(
            header: true,
            child: Row(
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Renkler.metin,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$adet',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Renkler.metinSolgun,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Divider(color: Renkler.camKenar)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_GunBasligiDelegate eski) =>
      eski.baslik != baslik || eski.adet != adet;
}
