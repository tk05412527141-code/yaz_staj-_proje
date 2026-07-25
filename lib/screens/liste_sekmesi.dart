import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/deprem.dart';
import '../services/deprem_servisi.dart';
import '../state/deprem_deposu.dart';
import '../utils/buyukluk_stili.dart';
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
                            '${depo.kaynak.ad} · ${depo.sonGuncellemeMetni}',
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
          IconButton(
            tooltip: 'Yenile',
            // Dokunma hedefi en az 48x48 - erisilebilirlik gerekliligi
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: depo.yukleniyor
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    depo.yenile();
                  },
            icon: const Icon(Icons.refresh),
            color: Renkler.metinSolgun,
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
          Expanded(
            child: TextField(
              controller: _aramaKontrolcu,
              onChanged: depo.aramaDegistir,
              style: const TextStyle(fontSize: 15, color: Renkler.metin),
              decoration: InputDecoration(
                hintText: 'Şehir veya bölge ara',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: depo.arama.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        icon: const Icon(Icons.close, size: 18),
                        color: Renkler.metinSolgun,
                        onPressed: () {
                          _aramaKontrolcu.clear();
                          depo.aramaDegistir('');
                        },
                      ),
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
      label: aktif > 0
          ? 'Filtreler, $aktif filtre aktif'
          : 'Filtreler',
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: aktif > 0 ? Renkler.vurgu : Renkler.yuzeyUst,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticFeedback.selectionClick();
                  FiltreSayfasi.ac(context, depo);
                },
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: aktif > 0 ? Renkler.vurgu : Renkler.kenarlik,
                    ),
                  ),
                  child: Icon(
                    Icons.tune,
                    size: 21,
                    color: aktif > 0 ? Colors.white : Renkler.metinSolgun,
                  ),
                ),
              ),
            ),
            if (aktif > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 19, minHeight: 19),
                  decoration: BoxDecoration(
                    color: Renkler.metin,
                    shape: BoxShape.circle,
                    border: Border.all(color: Renkler.zemin, width: 2),
                  ),
                  child: Text(
                    '$aktif',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Renkler.zemin,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
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

          return Semantics(
            button: true,
            selected: secili,
            label: '${f.etiket} filtresi',
            child: ExcludeSemantics(
              child: ChoiceChip(
                selected: secili,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  // "Yerlerim" ancak kayitli bir yer varsa anlamli
                  if (yerFiltresi && !depo.konumVar) {
                    _yerlerimAc(depo);
                    return;
                  }
                  depo.hizliFiltreDegistir(f);
                },
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (yerFiltresi) ...[
                      Icon(
                        depo.konumVar
                            ? Icons.place
                            : Icons.add_location_alt_outlined,
                        size: 14,
                        color: secili ? Colors.white : Renkler.metinSolgun,
                      ),
                      const SizedBox(width: 5),
                    ],
                    if (esikRengi != null && !secili) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: esikRengi,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      f.esik == null
                          ? f.etiket
                          : '${f.etiket} ${f.esik!.toStringAsFixed(1)}+',
                    ),
                  ],
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                  color: secili ? Colors.white : Renkler.metin,
                ),
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
        ikinciEylemYazisi: '${_digerKaynak(depo.kaynak).ad} kaynağını dene',
        onIkinciEylem: () => depo.kaynakDegistir(_digerKaynak(depo.kaynak)),
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

    sliverlar.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));
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

  /// Su an secili olmayan diger veri kaynagini dondurur.
  VeriKaynagi _digerKaynak(VeriKaynagi mevcut) {
    return mevcut == VeriKaynagi.afad
        ? VeriKaynagi.kandilli
        : VeriKaynagi.afad;
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
    return Container(
      height: _yukseklik,
      // Opak zemin: altindan gecen kartlar basligin icinden gorunmemeli
      color: Renkler.zemin,
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
            const Expanded(child: Divider(color: Renkler.kenarlik)),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_GunBasligiDelegate eski) =>
      eski.baslik != baslik || eski.adet != adet;
}
