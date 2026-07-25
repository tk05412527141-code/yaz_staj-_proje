import 'package:flutter/foundation.dart';

import '../models/deprem.dart';
import '../models/kayitli_konum.dart';
import '../services/deprem_servisi.dart';
import '../services/tercih_servisi.dart';
import '../utils/siddet_hesabi.dart';

/// Tek dokunusla uygulanan hazir filtreler.
enum HizliFiltre {
  tumu('Tümü', null),
  yerlerim('Yerlerim', null),
  sonSaat('Son 1 saat', null),
  bugun('Bugün', null),
  hissedilen('Hissedilenler', 3.0),
  guclu('Güçlü', 4.5);

  final String etiket;

  /// Varsa bu filtrenin uyguladigi minimum buyukluk.
  final double? esik;

  const HizliFiltre(this.etiket, this.esik);
}

enum Siralama {
  zaman('En yeni'),
  buyukluk('En büyük');

  final String etiket;
  const Siralama(this.etiket);
}

/// Uygulamanin ortak veri ve filtre durumunu tutar.
///
/// Neden boyle bir sinif var?
///   Liste, harita ve ayarlar sekmeleri AYNI veriyi ve AYNI filtreleri
///   paylasiyor. Her sekme kendi verisini cekseydi hem gereksiz istek
///   atilir hem de sekmeler arasi tutarsizlik olurdu.
///
/// ChangeNotifier: durum degistiginde dinleyen widget'lari uyarir.
/// Ekranlar bunu ListenableBuilder ile dinliyor.
class DepremDeposu extends ChangeNotifier {
  // --- Ham veri ---
  List<Deprem> _ham = [];
  bool yukleniyor = true;
  String? hata;
  DateTime? sonGuncelleme;

  // --- Sunucuya giden filtreler (degisince yeniden veri cekilir) ---
  VeriKaynagi kaynak = VeriKaynagi.kandilli;
  int gunSayisi = 7;
  double minBuyukluk = 0;

  // --- Cihazda uygulanan filtreler (aninda, istek atmadan) ---
  HizliFiltre hizliFiltre = HizliFiltre.tumu;
  Siralama siralama = Siralama.zaman;
  String arama = '';

  // --- Kullanicinin takip ettigi yerler ---
  List<KayitliKonum> konumlar = [];

  bool _tercihlerYuklendi = false;

  // ------------------------------------------------------------------
  // Baslangic
  // ------------------------------------------------------------------

  /// Uygulama acilirken bir kez cagrilir: tercihleri okur, veriyi ceker.
  Future<void> baslat() async {
    await _tercihleriYukle();
    await _konumlariYukle();
    await yenile();
  }

  // ------------------------------------------------------------------
  // Kayitli konumlar
  // ------------------------------------------------------------------

  Future<void> _konumlariYukle() async {
    konumlar = KayitliKonum.listeyiCoz(await TercihServisi.konumlariOku());
  }

  Future<void> _konumlariKaydet() async {
    await TercihServisi.konumlariKaydet(KayitliKonum.listeyiKodla(konumlar));
  }

  Future<void> konumEkle(KayitliKonum konum) async {
    konumlar = [...konumlar, konum];
    notifyListeners();
    await _konumlariKaydet();
  }

  Future<void> konumSil(String id) async {
    konumlar = konumlar.where((k) => k.id != id).toList();
    // Silinen konum son filtreyi anlamsiz birakmasin
    if (konumlar.isEmpty && hizliFiltre == HizliFiltre.yerlerim) {
      hizliFiltre = HizliFiltre.tumu;
    }
    notifyListeners();
    await _konumlariKaydet();
  }

  Future<void> konumGuncelle(KayitliKonum yeni) async {
    konumlar = konumlar.map((k) => k.id == yeni.id ? yeni : k).toList();
    notifyListeners();
    await _konumlariKaydet();
  }

  bool get konumVar => konumlar.isNotEmpty;

  /// Bir depremin verilen konumda tahmini etkisi.
  SiddetSonucu siddet(Deprem d, KayitliKonum konum) {
    return SiddetHesabi.hesapla(
      depremEnlem: d.enlem,
      depremBoylam: d.boylam,
      derinlikKm: d.derinlik,
      buyukluk: d.buyukluk,
      noktaEnlem: konum.enlem,
      noktaBoylam: konum.boylam,
    );
  }

  /// Bir depremin, kayitli konumlar arasindaki EN GUCLU etkisi.
  ///
  /// Kartlarda tek bir satir gosterecegimiz icin "en cok etkilenen yer"
  /// mantiklo olan bilgi. Konum yoksa null doner.
  ({KayitliKonum konum, SiddetSonucu sonuc})? enYakinEtki(Deprem d) {
    if (konumlar.isEmpty) return null;

    KayitliKonum? enIyiKonum;
    SiddetSonucu? enIyiSonuc;

    for (final k in konumlar) {
      final s = siddet(d, k);
      if (enIyiSonuc == null || s.mmi > enIyiSonuc.mmi) {
        enIyiSonuc = s;
        enIyiKonum = k;
      }
    }

    if (enIyiKonum == null || enIyiSonuc == null) return null;
    return (konum: enIyiKonum, sonuc: enIyiSonuc);
  }

  Future<void> _tercihleriYukle() async {
    final kayit = await TercihServisi.oku();

    final kaynakAdi = kayit[TercihServisi.anahtarKaynak];
    if (kaynakAdi is String) {
      for (final k in VeriKaynagi.values) {
        if (k.name == kaynakAdi) kaynak = k;
      }
    }

    final gun = kayit[TercihServisi.anahtarGun];
    if (gun is int && gun > 0) gunSayisi = gun;

    final minB = kayit[TercihServisi.anahtarMinBuyukluk];
    if (minB is double && minB >= 0) minBuyukluk = minB;

    final sira = kayit[TercihServisi.anahtarSiralama];
    if (sira is String) {
      for (final s in Siralama.values) {
        if (s.name == sira) siralama = s;
      }
    }

    _tercihlerYuklendi = true;
  }

  Future<void> _tercihleriKaydet() async {
    if (!_tercihlerYuklendi) return;
    await TercihServisi.kaydet(
      kaynak: kaynak.name,
      gunSayisi: gunSayisi,
      minBuyukluk: minBuyukluk,
      siralama: siralama.name,
    );
  }

  // ------------------------------------------------------------------
  // Veri cekme
  // ------------------------------------------------------------------

  Future<void> yenile() async {
    yukleniyor = true;
    hata = null;
    notifyListeners();

    try {
      _ham = await DepremServisi.getir(
        kaynak: kaynak,
        gunSayisi: gunSayisi,
        minBuyukluk: minBuyukluk,
      );
      sonGuncelleme = DateTime.now();
    } catch (e) {
      hata = e.toString().replaceFirst('Exception: ', '');
    } finally {
      yukleniyor = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // Filtre degistiriciler
  // ------------------------------------------------------------------

  Future<void> kaynakDegistir(VeriKaynagi yeni) async {
    if (kaynak == yeni) return;
    kaynak = yeni;
    notifyListeners();
    await _tercihleriKaydet();
    await yenile();
  }

  Future<void> gunDegistir(int yeni) async {
    if (gunSayisi == yeni) return;
    gunSayisi = yeni;
    notifyListeners();
    await _tercihleriKaydet();
    await yenile();
  }

  Future<void> minBuyuklukDegistir(double yeni) async {
    if (minBuyukluk == yeni) return;
    minBuyukluk = yeni;
    notifyListeners();
    await _tercihleriKaydet();
    await yenile();
  }

  /// Kaydirici surukleneken sadece etiketi guncelle, istek atma.
  void minBuyuklukOnizle(double yeni) {
    minBuyukluk = yeni;
    notifyListeners();
  }

  void hizliFiltreDegistir(HizliFiltre yeni) {
    hizliFiltre = yeni;
    notifyListeners();
  }

  Future<void> siralamaDegistir(Siralama yeni) async {
    siralama = yeni;
    notifyListeners();
    await _tercihleriKaydet();
  }

  void aramaDegistir(String yeni) {
    arama = yeni;
    notifyListeners();
  }

  Future<void> filtreleriSifirla() async {
    kaynak = VeriKaynagi.kandilli;
    gunSayisi = 7;
    minBuyukluk = 0;
    hizliFiltre = HizliFiltre.tumu;
    siralama = Siralama.zaman;
    arama = '';
    notifyListeners();
    await _tercihleriKaydet();
    await yenile();
  }

  // ------------------------------------------------------------------
  // Turetilmis veriler
  // ------------------------------------------------------------------

  /// Tum cihaz-ici filtreler uygulanmis, siralanmis liste.
  List<Deprem> get liste {
    final simdi = DateTime.now();
    final aranan = arama.toLowerCase().trim();

    final sonuc = _ham.where((d) {
      // 1) Hizli filtre
      if (hizliFiltre == HizliFiltre.yerlerim) {
        // Kayitli yerlerinden en az birinde hissedilmesi beklenenler
        final etki = enYakinEtki(d);
        if (etki == null || !etki.sonuc.seviye.hissedilir) return false;
      } else if (hizliFiltre == HizliFiltre.sonSaat) {
        if (simdi.difference(d.tarih).inMinutes > 60) return false;
      } else if (hizliFiltre == HizliFiltre.bugun) {
        final ayniGun = d.tarih.year == simdi.year &&
            d.tarih.month == simdi.month &&
            d.tarih.day == simdi.day;
        if (!ayniGun) return false;
      } else {
        // hissedilen / guclu gibi esik tabanli filtreler
        final esik = hizliFiltre.esik;
        if (esik != null && d.buyukluk < esik) return false;
      }

      // 2) Konum aramasi
      if (aranan.isNotEmpty && !d.yer.toLowerCase().contains(aranan)) {
        return false;
      }

      return true;
    }).toList();

    // 3) Siralama
    if (siralama == Siralama.buyukluk) {
      sonuc.sort((a, b) => b.buyukluk.compareTo(a.buyukluk));
    } else {
      sonuc.sort((a, b) => b.tarih.compareTo(a.tarih));
    }
    return sonuc;
  }

  int get toplamKayit => _ham.length;

  double get enBuyuk {
    final l = liste;
    if (l.isEmpty) return 0;
    return l.map((d) => d.buyukluk).reduce((a, b) => a > b ? a : b);
  }

  /// Kullanicinin varsayilandan farkli bir filtre secip secmedigi.
  /// Arayuzde "filtre aktif" rozetini gostermek icin kullaniliyor.
  int get aktifFiltreSayisi {
    var sayi = 0;
    if (gunSayisi != 7) sayi++;
    if (minBuyukluk > 0) sayi++;
    if (hizliFiltre != HizliFiltre.tumu) sayi++;
    if (siralama != Siralama.zaman) sayi++;
    if (arama.trim().isNotEmpty) sayi++;
    return sayi;
  }

  String get sonGuncellemeMetni {
    if (sonGuncelleme == null) return 'Henüz güncellenmedi';
    final fark = DateTime.now().difference(sonGuncelleme!);
    if (fark.inMinutes < 1) return 'Az önce güncellendi';
    if (fark.inMinutes < 60) return '${fark.inMinutes} dk önce güncellendi';
    return '${fark.inHours} saat önce güncellendi';
  }
}
