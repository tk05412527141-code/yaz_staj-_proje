import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/kayitli_konum.dart';
import '../state/deprem_deposu.dart';
import '../utils/sehirler.dart';
import '../utils/siddet_hesabi.dart';
import '../utils/tema.dart';
import 'konum_ekle_ekrani.dart';

/// Kullanicinin takip ettigi yerlerin listesi.
///
/// Her yerin yaninda, mevcut listedeki depremler arasinda o yeri en cok
/// etkileyenin ozeti gosteriliyor — boylece liste sadece bir ayar sayfasi
/// degil, ise yarar bir ozet ekrani oluyor.
class YerlerimEkrani extends StatelessWidget {
  final DepremDeposu depo;

  const YerlerimEkrani({super.key, required this.depo});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: depo,
      builder: (context, _) {
        final konumlar = depo.konumlar;

        return Scaffold(
          appBar: AppBar(title: const Text('Yerlerim')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _konumEkle(context),
            icon: const Icon(Icons.add),
            label: const Text('Yer ekle'),
            backgroundColor: Renkler.vurgu,
            foregroundColor: Colors.white,
          ),
          body: konumlar.isEmpty
              ? _bosDurum(context)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14, left: 2),
                      child: Text(
                        'Eklediğin yerler için depremlerin tahmini etkisi '
                        'hesaplanır. Listede "Yerlerim" filtresiyle sadece '
                        'seni ilgilendirenleri görebilirsin.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Renkler.metinSolgun,
                        ),
                      ),
                    ),
                    for (final k in konumlar) ...[
                      _konumKarti(context, k),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        );
      },
    );
  }

  // ------------------------------------------------------------------

  Widget _bosDurum(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Renkler.vurgu.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_location_alt_outlined,
                  size: 38, color: Renkler.vurgu),
            ),
            const SizedBox(height: 20),
            const Text(
              'Henüz yer eklemedin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Renkler.metin,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ev, iş veya ailenin bulunduğu yeri ekle. Depremlerin bu '
              'noktalarda ne kadar hissedileceğini tahmin edelim — '
              'büyüklük tek başına bunu söylemez.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Renkler.metinSolgun,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _konumKarti(BuildContext context, KayitliKonum konum) {
    // Bu konumu en cok etkileyen depremi bul
    ({SiddetSonucu sonuc, String yer})? enGuclu;
    for (final d in depo.liste) {
      final s = depo.siddet(d, konum);
      if (enGuclu == null || s.mmi > enGuclu.sonuc.mmi) {
        enGuclu = (sonuc: s, yer: d.yer);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Renkler.yuzey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Renkler.kenarlik),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Renkler.yuzeyUst,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(KonumSimgesi.ikon(konum.simge),
                  size: 20, color: Renkler.metin),
            ),
            title: Text(
              konum.ad,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Renkler.metin,
              ),
            ),
            subtitle: Text(
              '${konum.enlem.toStringAsFixed(3)}, '
              '${konum.boylam.toStringAsFixed(3)}',
              style: const TextStyle(
                fontSize: 12,
                color: Renkler.metinSolgun,
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Renkler.metinSolgun),
              color: Renkler.yuzeyUst,
              onSelected: (secim) {
                if (secim == 'duzenle') {
                  _konumEkle(context, duzenlenen: konum);
                } else if (secim == 'sil') {
                  _silmeOnayi(context, konum);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'duzenle', child: Text('Düzenle')),
                PopupMenuItem(value: 'sil', child: Text('Sil')),
              ],
            ),
          ),

          if (enGuclu != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: enGuclu.sonuc.seviye.renk,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu aralıkta en çok etkileyen: '
                          '${enGuclu.sonuc.seviye.etiket.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: enGuclu.sonuc.seviye.renk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${enGuclu.yer} · ${enGuclu.sonuc.mesafeMetni}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Renkler.metinSolgun,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------

  Future<void> _konumEkle(BuildContext context,
      {KayitliKonum? duzenlenen}) async {
    final sonuc = await Navigator.of(context).push<KayitliKonum>(
      MaterialPageRoute(
        builder: (_) => KonumEkleEkrani(duzenlenen: duzenlenen),
      ),
    );

    if (sonuc == null) return;

    HapticFeedback.mediumImpact();
    if (duzenlenen == null) {
      await depo.konumEkle(sonuc);
    } else {
      await depo.konumGuncelle(sonuc);
    }
  }

  Future<void> _silmeOnayi(BuildContext context, KayitliKonum konum) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Renkler.yuzey,
        title: const Text('Yeri sil'),
        content: Text('"${konum.ad}" listeden kaldırılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil', style: TextStyle(color: Color(0xFFF85149))),
          ),
        ],
      ),
    );

    if (onay == true) {
      HapticFeedback.mediumImpact();
      await depo.konumSil(konum.id);
    }
  }
}
