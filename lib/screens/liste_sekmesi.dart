import 'package:flutter/material.dart';

import '../services/deprem_servisi.dart';
import '../state/deprem_deposu.dart';
import '../utils/buyukluk_stili.dart';
import '../utils/tema.dart';
import '../widgets/deprem_karti.dart';
import '../widgets/durum_gorunumu.dart';
import '../widgets/filtre_sayfasi.dart';
import '../widgets/iskelet_kart.dart';
import 'detay_ekrani.dart';

/// Ana sekme: arama, hizli filtreler ve deprem listesi.
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
              _ozetSatiri(depo),
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
                    // "Canli" gostergesi - veri tazeligini hissettirir
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
                    Text(
                      '${depo.kaynak.ad} · ${depo.sonGuncellemeMetni}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Renkler.metinSolgun,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: depo.yukleniyor ? null : depo.yenile,
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: aktif > 0 ? Renkler.vurgu : Renkler.yuzeyUst,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => FiltreSayfasi.ac(context, depo),
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
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
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
    );
  }

  // ------------------------------------------------------------------
  // Hizli filtre seridi
  // ------------------------------------------------------------------

  Widget _hizliFiltreler(DepremDeposu depo) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: HizliFiltre.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = HizliFiltre.values[i];
          final secili = depo.hizliFiltre == f;
          final esikRengi = f.esik == null ? null : BuyuklukStili.renk(f.esik!);

          return ChoiceChip(
            selected: secili,
            onSelected: (_) => depo.hizliFiltreDegistir(f),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // Ozet
  // ------------------------------------------------------------------

  Widget _ozetSatiri(DepremDeposu depo) {
    if (depo.yukleniyor || depo.hata != null) {
      return const SizedBox(height: 14);
    }

    final liste = depo.liste;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
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
            Text(
              'en büyük ',
              style: const TextStyle(
                  fontSize: 13, color: Renkler.metinSolgun),
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
  // Icerik
  // ------------------------------------------------------------------

  Widget _icerik(DepremDeposu depo) {
    // AnimatedSwitcher: durumlar arasi gecisi yumusatir,
    // ekran birden bire degismez.
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
        // Bir kaynak erisilemezse kullaniciyi cikmaza sokmadan
        // digerini denemesini oneriyoruz.
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
      onRefresh: depo.yenile,
      color: Renkler.vurgu,
      backgroundColor: Renkler.yuzey,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        itemCount: liste.length,
        itemBuilder: (context, i) {
          final deprem = liste[i];
          return DepremKarti(
            deprem: deprem,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DetayEkrani(deprem: deprem)),
            ),
          );
        },
      ),
    );
  }

  /// Su an secili olmayan diger veri kaynagini dondurur.
  VeriKaynagi _digerKaynak(VeriKaynagi mevcut) {
    return mevcut == VeriKaynagi.afad
        ? VeriKaynagi.kandilli
        : VeriKaynagi.afad;
  }
}
