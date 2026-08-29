import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/acil_kisi.dart';
import '../utils/cam_tema.dart';
import '../utils/tema.dart';

/// Acil durum kisisi ekleme/duzenleme ekrani.
///
/// Rehber erisim izni ISTENMIYOR — kullanici numarayi elle giriyor.
/// Rehber izni, uygulamanin tum kisilerini gormesi demek; acil durum
/// ozelligi icin gereksiz genis bir yetki ve mağaza incelemesinde de
/// gerekcelendirme istiyor.
class AcilKisiEkleEkrani extends StatefulWidget {
  final AcilKisi? duzenlenen;

  const AcilKisiEkleEkrani({super.key, this.duzenlenen});

  @override
  State<AcilKisiEkleEkrani> createState() => _AcilKisiEkleEkraniState();
}

class _AcilKisiEkleEkraniState extends State<AcilKisiEkleEkrani> {
  final _adKontrolcu = TextEditingController();
  final _telefonKontrolcu = TextEditingController();
  final _iliskiKontrolcu = TextEditingController();

  String? _telefonHatasi;

  bool get _duzenlemeModu => widget.duzenlenen != null;

  /// Hazir iliski etiketleri - yazmak yerine dokunmak hizli
  static const _iliskiler = [
    'Anne',
    'Baba',
    'Eş',
    'Kardeş',
    'Çocuk',
    'Arkadaş',
    'Komşu'
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.duzenlenen;
    if (m != null) {
      _adKontrolcu.text = m.ad;
      _telefonKontrolcu.text = m.telefon;
      _iliskiKontrolcu.text = m.iliski;
    }
  }

  @override
  void dispose() {
    _adKontrolcu.dispose();
    _telefonKontrolcu.dispose();
    _iliskiKontrolcu.dispose();
    super.dispose();
  }

  bool get _kaydedilebilir =>
      _adKontrolcu.text.trim().isNotEmpty &&
      AcilKisi.telefonGecerliMi(_telefonKontrolcu.text);

  void _kaydet() {
    final ad = _adKontrolcu.text.trim();
    final telefon = _telefonKontrolcu.text.trim();

    if (!AcilKisi.telefonGecerliMi(telefon)) {
      setState(() => _telefonHatasi = 'Numara geçerli görünmüyor');
      return;
    }
    if (ad.isEmpty) return;

    HapticFeedback.selectionClick();

    Navigator.of(context).pop(
      AcilKisi(
        id: widget.duzenlenen?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        ad: ad,
        telefon: telefon,
        iliski: _iliskiKontrolcu.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CamSayfa(
      baslik: _duzenlemeModu ? 'Kişiyi düzenle' : 'Acil kişi ekle',
      vurguRengi: const Color(0xFFF85149),
      govde: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  CamOlculer.ustBosluk(context) + 14,
                  20,
                  16,
                ),
                children: [
                  _bolumBasligi('AD'),
                  TextField(
                    controller: _adKontrolcu,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Renkler.metin),
                    decoration: const InputDecoration(
                      hintText: 'Örn. Ayşe Kılıç',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _bolumBasligi('TELEFON'),
                  TextField(
                    controller: _telefonKontrolcu,
                    onChanged: (_) => setState(() => _telefonHatasi = null),
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Renkler.metin),
                    decoration: InputDecoration(
                      hintText: '0555 111 22 33',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      errorText: _telefonHatasi,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Ülke kodu yazmasan da olur, Türkiye numarası varsayılır. '
                    'Yabancı numara için +90 gibi kod ekle.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Renkler.metinSolgun,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _bolumBasligi('YAKINLIK (isteğe bağlı)'),
                  TextField(
                    controller: _iliskiKontrolcu,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Renkler.metin),
                    decoration: const InputDecoration(
                      hintText: 'Örn. Anne',
                      prefixIcon: Icon(Icons.favorite_border),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _iliskiler.map((i) {
                      final secili = _iliskiKontrolcu.text.trim() == i;
                      return GlassChip(
                        label: i,
                        selected: secili,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _iliskiKontrolcu.text = secili ? '' : i;
                          });
                        },
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
                  const SizedBox(height: 24),
                  GlassCard(
                    quality: GlassQuality.minimal,
                    padding: const EdgeInsets.all(13),
                    shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 17, color: Renkler.metinSolgun),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bu bilgiler yalnızca telefonunda saklanır. '
                            'Hiçbir sunucuya gönderilmez ve rehberine '
                            'erişim izni istenmez.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: Renkler.metinSolgun,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
}
