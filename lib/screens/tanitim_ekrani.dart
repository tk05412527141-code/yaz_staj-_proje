import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/kayitli_konum.dart';
import '../state/deprem_deposu.dart';
import '../utils/sehirler.dart';
import '../utils/tema.dart';
import 'konum_ekle_ekrani.dart';

/// Ilk acilista gosterilen tanitim akisi.
///
/// NEDEN VAR?
///   Uygulamanin en degerli ozelligi "yerlerimdeki tahmini etki" idi ama
///   kullanici bunu kesfetmek icin ayarlara girmek zorundaydi. Gorunmeyen
///   ozellik, olmayan ozellikle aynidir.
///
///   Bu akis uc sey yapiyor:
///     1. Uygulamanin neden farkli oldugunu 10 saniyede anlatiyor
///     2. Kullaniciyi ilk konumunu eklemeye yonlendiriyor
///     3. Kullanici listeye bos degil, kurulmus bir sekilde giriyor
///
///   Atlanabilir tutuldu: zorunlu onboarding kullaniciyi kacirir.
class TanitimEkrani extends StatefulWidget {
  final DepremDeposu depo;
  final VoidCallback onTamamlandi;

  const TanitimEkrani({
    super.key,
    required this.depo,
    required this.onTamamlandi,
  });

  @override
  State<TanitimEkrani> createState() => _TanitimEkraniState();
}

class _TanitimEkraniState extends State<TanitimEkrani> {
  final _sayfaKontrolcu = PageController();
  int _sayfa = 0;

  static const _sonSayfa = 2;

  @override
  void dispose() {
    _sayfaKontrolcu.dispose();
    super.dispose();
  }

  void _ilerle() {
    HapticFeedback.selectionClick();
    if (_sayfa >= _sonSayfa) {
      widget.onTamamlandi();
      return;
    }
    _sayfaKontrolcu.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _konumEkle() async {
    HapticFeedback.selectionClick();
    final sonuc = await Navigator.of(context).push<KayitliKonum>(
      MaterialPageRoute(builder: (_) => const KonumEkleEkrani()),
    );
    if (sonuc == null) return;
    await widget.depo.konumEkle(sonuc);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Atla butonu
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: widget.onTamamlandi,
                  child: const Text(
                    'Atla',
                    style: TextStyle(color: Renkler.metinSolgun),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _sayfaKontrolcu,
                onPageChanged: (i) => setState(() => _sayfa = i),
                children: [
                  _sayfaBir(),
                  _sayfaIki(),
                  _sayfaUc(),
                ],
              ),
            ),

            _noktalar(),
            const SizedBox(height: 16),
            _altButonlar(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Sayfalar
  // ------------------------------------------------------------------

  /// 1. Problem: buyukluk tek basina bir sey ifade etmiyor
  Widget _sayfaBir() {
    return _sayfaKabugu(
      gorsel: _karsilastirmaGorseli(),
      baslik: '"4.1" ne demek?',
      metin: 'Deprem büyüklüğü tek başına bir şey söylemez. '
          '300 km uzaktaki 5.0 hiç hissedilmezken, 10 km yakındaki 4.0 '
          'sizi uykudan uyandırabilir.',
    );
  }

  /// 2. Cozum: yerlerini ekle
  Widget _sayfaIki() {
    final konumSayisi = widget.depo.konumlar.length;

    return _sayfaKabugu(
      gorsel: Icon(
        konumSayisi > 0 ? Icons.check_circle_outline : Icons.add_location_alt_outlined,
        size: 76,
        color: konumSayisi > 0 ? Renkler.canli : Renkler.vurgu,
      ),
      baslik: 'Yerlerinizi ekleyin',
      metin: konumSayisi > 0
          ? '${konumSayisi} yer eklendi. Artık her deprem için bu '
              'noktalarda ne kadar hissedileceğini göreceksiniz.'
          : 'Ev, iş veya ailenizin bulunduğu yeri ekleyin. Her deprem '
              'için oralarda ne kadar hissedileceğini tahmin edelim.',
      ek: Column(
        children: [
          const SizedBox(height: 22),
          if (konumSayisi > 0)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: widget.depo.konumlar.map((k) {
                return Chip(
                  avatar: Icon(KonumSimgesi.ikon(k.simge),
                      size: 16, color: Renkler.metin),
                  label: Text(k.ad),
                  backgroundColor: Renkler.yuzeyUst,
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _konumEkle,
            icon: const Icon(Icons.add, size: 18),
            label: Text(konumSayisi > 0 ? 'Bir yer daha ekle' : 'Yer ekle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Renkler.vurgu,
              side: const BorderSide(color: Renkler.vurgu),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Konumunuz yalnızca telefonda saklanır,\nhiçbir yere gönderilmez.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Renkler.metinSolgun,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Hazirsin
  Widget _sayfaUc() {
    return _sayfaKabugu(
      gorsel: const Icon(Icons.notifications_active_outlined,
          size: 76, color: Renkler.vurgu),
      baslik: 'Hazırsınız',
      metin: 'Veriler AFAD ve Kandilli Rasathanesi\'nden geliyor. '
          'İki kaynak arasında istediğiniz zaman geçiş yapabilirsiniz.\n\n'
          'Listede "Yerlerim" filtresiyle yalnızca sizi ilgilendiren '
          'depremleri görebilirsiniz.',
    );
  }

  // ------------------------------------------------------------------
  // Ortak parcalar
  // ------------------------------------------------------------------

  Widget _sayfaKabugu({
    required Widget gorsel,
    required String baslik,
    required String metin,
    Widget? ek,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          gorsel,
          const SizedBox(height: 30),
          Text(
            baslik,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Renkler.metin,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            metin,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: Renkler.metinSolgun,
            ),
          ),
          if (ek != null) ek,
        ],
      ),
    );
  }

  /// Birinci sayfadaki gorsel: ayni buyuklugun iki farkli sonucu.
  Widget _karsilastirmaGorseli() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ornekKutu('4.0', '10 km', 'Hissedilir', const Color(0xFFF0883E)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'vs',
            style: TextStyle(color: Renkler.metinSolgun, fontSize: 13),
          ),
        ),
        _ornekKutu('5.0', '300 km', 'Hissedilmez', const Color(0xFF5A6672)),
      ],
    );
  }

  Widget _ornekKutu(
      String buyukluk, String mesafe, String sonuc, Color renk) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Renkler.yuzey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            buyukluk,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: renk,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mesafe,
            style: const TextStyle(
              fontSize: 12,
              color: Renkler.metinSolgun,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sonuc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noktalar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_sonSayfa + 1, (i) {
        final aktif = i == _sayfa;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: aktif ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: aktif ? Renkler.vurgu : Renkler.kenarlik,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _altButonlar() {
    final sonSayfada = _sayfa == _sonSayfa;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _ilerle,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            sonSayfada ? 'Başla' : 'Devam',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
