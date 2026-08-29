import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/kayitli_konum.dart';
import '../utils/cam_tema.dart';
import '../utils/sehirler.dart';
import '../utils/tema.dart';

/// Yeni bir takip konumu ekleme ekrani.
///
/// Iki yol sunuluyor:
///   1. Sehir listesinden sec  - hizli, cogu kullaniciya yeter
///   2. Haritadan sec          - mahalle hassasiyeti isteyenler icin
///
/// GPS ile "mevcut konumum" bilerek eklenmedi: konum izni istemek
/// kullanicinin ilk deneyimini zorlastiriyor ve ek bir paket gerektiriyor.
class KonumEkleEkrani extends StatefulWidget {
  /// Duzenleme modunda mevcut konum; yeni ekleme icin null.
  final KayitliKonum? duzenlenen;

  const KonumEkleEkrani({super.key, this.duzenlenen});

  @override
  State<KonumEkleEkrani> createState() => _KonumEkleEkraniState();
}

class _KonumEkleEkraniState extends State<KonumEkleEkrani> {
  final _adKontrolcu = TextEditingController();
  final _aramaKontrolcu = TextEditingController();
  final _haritaKontrolcu = MapController();

  String _simge = 'ev';
  double? _enlem;
  double? _boylam;
  String _aramaMetni = '';
  bool _haritaModu = false;

  bool get _duzenlemeModu => widget.duzenlenen != null;

  @override
  void initState() {
    super.initState();
    final mevcut = widget.duzenlenen;
    if (mevcut != null) {
      _adKontrolcu.text = mevcut.ad;
      _simge = mevcut.simge;
      _enlem = mevcut.enlem;
      _boylam = mevcut.boylam;
      _haritaModu = true;
    }
  }

  @override
  void dispose() {
    _adKontrolcu.dispose();
    _aramaKontrolcu.dispose();
    _haritaKontrolcu.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------

  void _sehirSec(Sehir sehir) {
    setState(() {
      _enlem = sehir.enlem;
      _boylam = sehir.boylam;
      if (_adKontrolcu.text.trim().isEmpty) {
        _adKontrolcu.text = sehir.ad;
      }
      _haritaModu = true;
    });
  }

  void _kaydet() {
    final ad = _adKontrolcu.text.trim();
    final enlem = _enlem;
    final boylam = _boylam;

    if (ad.isEmpty || enlem == null || boylam == null) return;

    final konum = KayitliKonum(
      id: widget.duzenlenen?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      ad: ad,
      enlem: enlem,
      boylam: boylam,
      simge: _simge,
    );

    Navigator.of(context).pop(konum);
  }

  bool get _kaydedilebilir =>
      _adKontrolcu.text.trim().isNotEmpty && _enlem != null;

  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CamSayfa(
      baslik: _duzenlemeModu ? 'Konumu düzenle' : 'Yer ekle',
      govde: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  CamOlculer.ustBosluk(context) + 12,
                  16,
                  16,
                ),
                children: [
                  _bolumBasligi('AD'),
                  TextField(
                    controller: _adKontrolcu,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: Renkler.metin),
                    decoration: const InputDecoration(
                      hintText: 'Örn. Evim, Annemler, Ofis',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _bolumBasligi('SİMGE'),
                  Wrap(
                    spacing: 8,
                    children: KonumSimgesi.tumu.keys.map((anahtar) {
                      final secili = _simge == anahtar;
                      return GlassChip(
                        selected: secili,
                        onTap: () => setState(() => _simge = anahtar),
                        icon: Icon(KonumSimgesi.ikon(anahtar), size: 16),
                        iconColor: secili ? Renkler.vurgu : Renkler.metinSolgun,
                        label: KonumSimgesi.adlar[anahtar] ?? anahtar,
                        selectedColor: Renkler.vurgu.withValues(alpha: 0.35),
                        settings: CamAyar.kontrol,
                        useOwnLayer: true,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              secili ? FontWeight.w700 : FontWeight.w500,
                          color: secili ? Renkler.metin : Renkler.metinSolgun,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _bolumBasligi('KONUM'),
                  if (!_haritaModu) ...[
                    TextField(
                      controller: _aramaKontrolcu,
                      onChanged: (d) => setState(() => _aramaMetni = d),
                      style: const TextStyle(color: Renkler.metin),
                      decoration: const InputDecoration(
                        hintText: 'Şehir ara',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _sehirListesi(),
                  ] else
                    _haritaSecici(),
                ],
              ),
            ),

            // Kaydet butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: GlassButton.custom(
                  onTap: _kaydedilebilir ? _kaydet : () {},
                  enabled: _kaydedilebilir,
                  label: _duzenlemeModu ? 'Değişiklikleri kaydet' : 'Kaydet',
                  height: 52,
                  style: GlassButtonStyle.prominent,
                  settings: _kaydedilebilir
                      ? CamAyar.tonlu(Renkler.vurgu, yogunluk: 0.20)
                      : CamAyar.panel,
                  useOwnLayer: true,
                  shape: const LiquidRoundedSuperellipse(borderRadius: 18),
                  child: Text(
                    _duzenlemeModu ? 'Değişiklikleri kaydet' : 'Kaydet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          _kaydedilebilir ? Renkler.metin : Renkler.metinSolgun,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bolumBasligi(String yazi) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
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

  Widget _sehirListesi() {
    final sonuclar = Sehirler.ara(_aramaMetni);

    if (sonuclar.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Şehir bulunamadı',
            style: TextStyle(color: Renkler.metinSolgun),
          ),
        ),
      );
    }

    return GlassCard(
      quality: GlassQuality.minimal,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const LiquidRoundedSuperellipse(borderRadius: 18),
      child: Column(
        children: [
          for (var i = 0; i < sonuclar.length && i < 40; i++) ...[
            if (i > 0) const GlassDivider(),
            ListTile(
              dense: true,
              leading: Text(
                sonuclar[i].plaka.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Renkler.metinSolgun,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              title: Text(sonuclar[i].ad),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _sehirSec(sonuclar[i]),
            ),
          ],
          if (sonuclar.length > 40)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Aramayı daraltın…',
                style: TextStyle(color: Renkler.metinSolgun, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _haritaSecici() {
    final merkez = LatLng(_enlem ?? 39.0, _boylam ?? 35.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haritayı kaydırarak konumu hassaslaştırabilirsiniz. '
          'Ortadaki işaret seçili noktayı gösterir.',
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: Renkler.metinSolgun,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _haritaKontrolcu,
                  options: MapOptions(
                    initialCenter: merkez,
                    initialZoom: 10,
                    // Harita her hareket ettiginde merkez = secili nokta
                    onPositionChanged: (kamera, _) {
                      _enlem = kamera.center.latitude;
                      _boylam = kamera.center.longitude;
                    },
                    onMapEvent: (_) => setState(() {}),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tunakilic.deprem_takip',
                    ),
                  ],
                ),

                // Sabit orta nisangah
                IgnorePointer(
                  child: Icon(
                    Icons.add,
                    size: 34,
                    color: Renkler.vurgu.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.my_location, size: 15, color: Renkler.metinSolgun),
            const SizedBox(width: 6),
            Text(
              _enlem == null
                  ? '—'
                  : '${_enlem!.toStringAsFixed(4)}, '
                      '${_boylam!.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 13,
                color: Renkler.metinSolgun,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _haritaModu = false),
              icon: const Icon(Icons.list, size: 17),
              label: const Text('Şehir listesi'),
            ),
          ],
        ),
      ],
    );
  }
}
