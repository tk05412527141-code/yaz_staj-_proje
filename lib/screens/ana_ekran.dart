import 'package:flutter/material.dart';

import '../models/deprem.dart';
import '../services/deprem_servisi.dart';
import '../widgets/deprem_karti.dart';
import 'detay_ekrani.dart';
import 'harita_ekrani.dart';

/// Uygulamanin ana ekrani: filtreler + deprem listesi.
class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  // --- Durum (state) degiskenleri ---
  List<Deprem> _depremler = [];
  bool _yukleniyor = true;
  String? _hata;

  // --- Filtreler ---
  VeriKaynagi _kaynak = VeriKaynagi.kandilli;
  int _gunSayisi = 7;
  double _minBuyukluk = 0;
  String _arama = '';

  bool _filtrelerAcik = false;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  /// API'den veriyi ceker ve ekrani gunceller.
  Future<void> _verileriYukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final sonuc = await DepremServisi.getir(
        kaynak: _kaynak,
        gunSayisi: _gunSayisi,
        minBuyukluk: _minBuyukluk,
      );

      // Ekran kapatildiysa setState cagirma - yoksa hata verir
      if (!mounted) return;
      setState(() {
        _depremler = sonuc;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.toString().replaceFirst('Exception: ', '');
        _yukleniyor = false;
      });
    }
  }

  /// Arama kutusuna gore listeyi suzer (API'ye tekrar gitmez).
  List<Deprem> get _gosterilecekler {
    if (_arama.trim().isEmpty) return _depremler;
    final aranan = _arama.toLowerCase().trim();
    return _depremler
        .where((d) => d.yer.toLowerCase().contains(aranan))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final liste = _gosterilecekler;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deprem Takip'),
        actions: [
          IconButton(
            tooltip: 'Haritada goster',
            icon: const Icon(Icons.map_outlined),
            onPressed: liste.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HaritaEkrani(depremler: liste),
                      ),
                    );
                  },
          ),
          IconButton(
            tooltip: 'Filtreler',
            icon: Icon(_filtrelerAcik ? Icons.expand_less : Icons.tune),
            onPressed: () =>
                setState(() => _filtrelerAcik = !_filtrelerAcik),
          ),
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _yukleniyor ? null : _verileriYukle,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filtrelerAcik) _filtrePaneli(),
          _ozetSatiri(liste),
          Expanded(child: _icerik(liste)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Filtre paneli
  // ------------------------------------------------------------------

  Widget _filtrePaneli() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Veri kaynagi
            const Text('Veri kaynagi',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: VeriKaynagi.values.map((k) {
                return ChoiceChip(
                  label: Text(k.ad),
                  selected: _kaynak == k,
                  onSelected: (secildi) {
                    if (!secildi) return;
                    setState(() => _kaynak = k);
                    _verileriYukle();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Zaman araligi
            const Text('Zaman araligi',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: const [1, 3, 7, 30].map((gun) {
                return ChoiceChip(
                  label: Text(gun == 1 ? 'Son 24 saat' : 'Son $gun gun'),
                  selected: _gunSayisi == gun,
                  onSelected: (secildi) {
                    if (!secildi) return;
                    setState(() => _gunSayisi = gun);
                    _verileriYukle();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Minimum buyukluk
            Text(
              'Minimum buyukluk: ${_minBuyukluk.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _minBuyukluk,
              min: 0,
              max: 6,
              divisions: 12,
              label: _minBuyukluk.toStringAsFixed(1),
              onChanged: (deger) => setState(() => _minBuyukluk = deger),
              onChangeEnd: (_) => _verileriYukle(),
            ),

            // Konum arama
            TextField(
              decoration: const InputDecoration(
                labelText: 'Konum ara',
                hintText: 'orn. Izmir',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (deger) => setState(() => _arama = deger),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Ozet satiri
  // ------------------------------------------------------------------

  Widget _ozetSatiri(List<Deprem> liste) {
    if (_yukleniyor || _hata != null) return const SizedBox.shrink();

    final enBuyuk = liste.isEmpty
        ? 0.0
        : liste.map((d) => d.buyukluk).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${liste.length} deprem · en buyuk ${enBuyuk.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '${_kaynak.ad} verisi',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Ana icerik: yukleniyor / hata / bos / liste
  // ------------------------------------------------------------------

  Widget _icerik(List<Deprem> liste) {
    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hata != null) {
      return _mesajEkrani(
        ikon: Icons.cloud_off,
        baslik: 'Veri alinamadi',
        aciklama: _hata!,
        butonYazisi: 'Tekrar dene',
      );
    }

    if (liste.isEmpty) {
      return _mesajEkrani(
        ikon: Icons.search_off,
        baslik: 'Sonuc bulunamadi',
        aciklama: _arama.isNotEmpty
            ? '"$_arama" icin kayit yok. Aramayi degistirmeyi deneyin.'
            : 'Bu filtrelerle kayit bulunamadi. Zaman araligini genisletin '
                'veya minimum buyuklugu dusurun.',
        butonYazisi: 'Yenile',
      );
    }

    return RefreshIndicator(
      onRefresh: _verileriYukle,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: liste.length,
        itemBuilder: (context, i) {
          final deprem = liste[i];
          return DepremKarti(
            deprem: deprem,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetayEkrani(deprem: deprem),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _mesajEkrani({
    required IconData ikon,
    required String baslik,
    required String aciklama,
    required String butonYazisi,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(baslik,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              aciklama,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _verileriYukle,
              icon: const Icon(Icons.refresh),
              label: Text(butonYazisi),
            ),
          ],
        ),
      ),
    );
  }
}
