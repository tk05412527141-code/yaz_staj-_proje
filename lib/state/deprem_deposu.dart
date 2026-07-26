import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/acil_kisi.dart';
import '../models/deprem.dart';
import '../models/haber.dart';
import '../models/hazirlik_maddesi.dart';
import '../models/kayitli_konum.dart';
import '../services/bulten_uretici.dart';
import '../services/deprem_servisi.dart';
import '../services/haber_servisi.dart';
import '../services/hatirlatma_planlayici.dart';
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
  DepremYanit? _yanit;
  bool yukleniyor = true;
  String? hata;
  DateTime? sonGuncelleme;

  /// Listeyi besleyen ham kayitlar.
  List<Deprem> get _ham => _yanit?.depremler ?? const [];

  /// Otomatik modda gercekte hangi kaynak kullanildi?
  VeriKaynagi? get kullanilanKaynak => _yanit?.kaynak;

  /// En yeni kaydin yasi. Kaynagin ne kadar guncel oldugunu gosterir.
  Duration? get veriTazeligi => _yanit?.tazelik;

  /// Kaynak belirgin sekilde gecikmeli mi? (en yeni kayit 3 saatten eski)
  bool get veriGecikmeli => _yanit?.gecikmeli ?? false;

  String get tazelikMetni {
    final t = veriTazeligi;
    if (t == null) return '—';
    if (t.inMinutes < 1) return 'az önce';
    if (t.inMinutes < 60) return '${t.inMinutes} dk önce';
    if (t.inHours < 24) return '${t.inHours} saat önce';
    return '${t.inDays} gün önce';
  }

  // ------------------------------------------------------------------
  // Otomatik periyodik yenileme
  // ------------------------------------------------------------------

  Timer? _periyodikZamanlayici;

  /// Uygulama on plandayken listeyi ne siklikta yenileyelim.
  ///
  /// Kandilli yaklasik 5 dakikalik gecikmeyle yayin yapiyor; 60 saniye
  /// bunun altinda kaldigi icin yeni kayit cikar cikmaz yakalaniyor.
  /// Daha sik yenilemek kaynagin sunucusuna gereksiz yuk olurdu.
  static const periyodikAralik = Duration(seconds: 60);

  /// Periyodik yenilemeyi baslatir (uygulama on plana geldiginde).
  void periyodikBaslat() {
    _periyodikZamanlayici?.cancel();
    _periyodikZamanlayici = Timer.periodic(periyodikAralik, (_) {
      // Zaten yukleniyorsa ustune istek atma
      if (!yukleniyor) yenile();
    });
  }

  /// Periyodik yenilemeyi durdurur (arka plana gecince).
  ///
  /// Arka planda istek atmak hem pil hem veri israfi; ustelik
  /// kullanici gormuyor.
  void periyodikDurdur() {
    _periyodikZamanlayici?.cancel();
    _periyodikZamanlayici = null;
  }

  @override
  void dispose() {
    _periyodikZamanlayici?.cancel();
    super.dispose();
  }

  // --- Duyuru bultenleri (AYRI sorgu) ---
  List<Bulten> _bultenler = const [];
  bool bultenYukleniyor = true;
  String? bultenHatasi;

  // --- Resmi haber kaynagindan deprem haberleri ---
  List<Haber> haberler = const [];
  bool haberYukleniyor = true;

  /// Duyurular (haber + bulten) en son ne zaman cekildi.
  DateTime? duyuruSonGuncelleme;

  /// Veri kac dakika sonra "bayat" sayilsin.
  ///
  /// Deprem haberi cok sik degismiyor; her sekme gecisinde istek atmak
  /// hem gereksiz hem de kaynagin sunucusuna yuk. 10 dakika, tazelikle
  /// istek sayisi arasinda makul bir denge.
  static const bayatlamaSuresi = Duration(minutes: 10);

  bool get duyurularBayatMi {
    final t = duyuruSonGuncelleme;
    if (t == null) return true;
    return DateTime.now().difference(t) > bayatlamaSuresi;
  }

  String get duyuruGuncellemeMetni {
    final t = duyuruSonGuncelleme;
    if (t == null) return 'Henüz güncellenmedi';
    final fark = DateTime.now().difference(t);
    if (fark.inMinutes < 1) return 'Az önce güncellendi';
    if (fark.inMinutes < 60) return '${fark.inMinutes} dk önce güncellendi';
    return '${fark.inHours} saat önce güncellendi';
  }

  /// Bayatsa duyurulari yeniler, tazeyse hicbir sey yapmaz.
  ///
  /// Duyurular sekmesine her girildiginde ve uygulama on plana her
  /// dondugunde cagriliyor. Gereksiz istek atmamak icin bayatlik
  /// kontrolu burada.
  Future<void> duyurulariTazele() async {
    if (!duyurularBayatMi) return;
    await Future.wait([bultenleriYenile(), haberleriYenile()]);
  }

  /// Kullanicinin acikca istedigi yenileme (asagi cekme).
  /// Bayatlik kontrolu YAPMAZ - kullanici istedi, yenile.
  Future<void> duyurulariYenile() async {
    await Future.wait([bultenleriYenile(), haberleriYenile()]);
  }

  // --- Sunucuya giden filtreler (degisince yeniden veri cekilir) ---
  VeriKaynagi kaynak = VeriKaynagi.otomatik;
  int gunSayisi = 7;
  double minBuyukluk = 0;

  // --- Cihazda uygulanan filtreler (aninda, istek atmadan) ---
  HizliFiltre hizliFiltre = HizliFiltre.tumu;
  Siralama siralama = Siralama.zaman;
  String arama = '';

  // --- Kullanicinin takip ettigi yerler ---
  List<KayitliKonum> konumlar = [];

  // --- Deprem oncesi hazirlik durumu ---
  HazirlikDurumu hazirlik = const HazirlikDurumu();

  // --- Acil durumda haber verilecek kisiler ---
  List<AcilKisi> acilKisiler = [];

  bool _tercihlerYuklendi = false;

  // ------------------------------------------------------------------
  // Baslangic
  // ------------------------------------------------------------------

  /// Uygulama acilirken bir kez cagrilir: tercihleri okur, veriyi ceker.
  Future<void> baslat() async {
    await _tercihleriYukle();
    await _konumlariYukle();
    await _hazirligiYukle();
    await _acilKisileriYukle();

    // Hatirlatmalari her acilista yeniden planliyoruz. Cihaz bildirimleri
    // uzun periyotlari kendi basina tekrarlayamadigi icin bir sonraki
    // tarihi her seferinde yeniden kurmak gerekiyor.
    unawaited(HatirlatmaPlanlayici.yenidenPlanla(hazirlik));

    await yenile();
  }

  // ------------------------------------------------------------------
  // Hazirlik ve hatirlatmalar
  // ------------------------------------------------------------------

  Future<void> _hazirligiYukle() async {
    hazirlik = HazirlikDurumu.coz(await TercihServisi.hazirligiOku());
  }

  Future<void> _hazirligiKaydet() async {
    await TercihServisi.hazirligiKaydet(hazirlik.kodla());
    await HatirlatmaPlanlayici.yenidenPlanla(hazirlik);
  }

  /// Bir hazirlik maddesini tamamlandi/tamamlanmadi olarak isaretler.
  Future<void> hazirlikMaddesiDegistir(String id, bool tamamlandi) async {
    final yeni = Map<String, DateTime>.from(hazirlik.tamamlanmaTarihleri);
    if (tamamlandi) {
      yeni[id] = DateTime.now();
    } else {
      yeni.remove(id);
    }
    hazirlik = hazirlik.kopyala(tamamlanmaTarihleri: yeni);
    notifyListeners();
    await _hazirligiKaydet();
  }

  Future<void> hatirlatmaDegistir(String id, bool acik) async {
    final yeni = Set<String>.from(hazirlik.acikHatirlatmalar);
    if (acik) {
      yeni.add(id);
    } else {
      yeni.remove(id);
    }
    hazirlik = hazirlik.kopyala(acikHatirlatmalar: yeni);
    notifyListeners();
    await _hazirligiKaydet();
  }

  Future<void> hatirlatmaSaatiDegistir(int saat) async {
    hazirlik = hazirlik.kopyala(hatirlatmaSaati: saat);
    notifyListeners();
    await _hazirligiKaydet();
  }

  Future<void> hatirlatmalariYenidenPlanla() async {
    await HatirlatmaPlanlayici.yenidenPlanla(hazirlik);
  }

  /// Acik hatirlatma sayisi - ayarlar ekraninda ozet gostermek icin.
  int get acikHatirlatmaSayisi => hazirlik.acikHatirlatmalar.length;

  // ------------------------------------------------------------------
  // Kaynak kapsam uyarisi
  // ------------------------------------------------------------------

  /// Secili kaynak, secili zaman araligini karsilayamiyorsa uyari metni.
  ///
  /// Kandilli API'si yalnizca son 24 saati veriyor. Kullanici "Son 7 gun"
  /// secip 24 saatlik veri gormesi ve bunu bilmemesi kotu; sessiz
  /// calismayan bir filtre, bozuk bir filtreden daha yanilticidir.
  String? get kapsamUyarisi {
    // 1. Kaynagin bilinen sabit siniri
    if (kaynak.kapsamiAsiyorMu(gunSayisi)) {
      return '${kaynak.ad} yalnızca son 24 saati veriyor. '
          'Daha geniş aralık için AFAD kaynağına geç.';
    }

    // 2. Gelen verinin GERCEKTEN araligi kapsayip kapsamadigi.
    //    Sabit sinir bilinmese bile kayit sayisi sinira dayandiysa
    //    elimizde eksik veri var demektir.
    final y = _yanit;
    if (y != null && y.kapsamEksik) {
      return 'Bu aralığın tamamı alınamadı; elimizdeki veri son '
          '${y.kapsananGun} günü kapsıyor.';
    }

    return null;
  }

  bool get kapsamUyarisiVar => kapsamUyarisi != null;

  // ------------------------------------------------------------------
  // Acil durum kisileri
  // ------------------------------------------------------------------

  Future<void> _acilKisileriYukle() async {
    acilKisiler = AcilKisi.listeyiCoz(await TercihServisi.acilKisileriOku());
  }

  Future<void> _acilKisileriKaydet() async {
    await TercihServisi.acilKisileriKaydet(
      AcilKisi.listeyiKodla(acilKisiler),
    );
  }

  Future<void> acilKisiEkle(AcilKisi kisi) async {
    acilKisiler = [...acilKisiler, kisi];
    notifyListeners();
    await _acilKisileriKaydet();
  }

  Future<void> acilKisiSil(String id) async {
    acilKisiler = acilKisiler.where((k) => k.id != id).toList();
    notifyListeners();
    await _acilKisileriKaydet();
  }

  Future<void> acilKisiGuncelle(AcilKisi yeni) async {
    acilKisiler =
        acilKisiler.map((k) => k.id == yeni.id ? yeni : k).toList();
    notifyListeners();
    await _acilKisileriKaydet();
  }

  bool get acilKisiVar => acilKisiler.isNotEmpty;

  // ------------------------------------------------------------------
  // Duyuru bultenleri
  // ------------------------------------------------------------------

  /// Bultenlerin kac gunluk pencereden uretildigi.
  static const bultenGunSayisi = 30;

  /// Onemli depremler icin uretilmis bultenler.
  List<Bulten> get bultenler => _bultenler;

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
    _bultenleriYenidenHesapla();
    notifyListeners();
    await _konumlariKaydet();
  }

  /// Konumlar degistiginde bultenlerdeki "yerlerinizde" bolumu de
  /// guncellenmeli. Ag istegi gerekmiyor, eldeki veriden hesapliyoruz.
  void _bultenleriYenidenHesapla() {
    if (_bultenler.isEmpty) return;
    _bultenler = BultenUretici.uret(
      depremler: _bultenler.map((b) => b.deprem).toList(),
      konumlar: konumlar,
    );
  }

  Future<void> konumSil(String id) async {
    konumlar = konumlar.where((k) => k.id != id).toList();
    _bultenleriYenidenHesapla();
    // Silinen konum son filtreyi anlamsiz birakmasin
    if (konumlar.isEmpty && hizliFiltre == HizliFiltre.yerlerim) {
      hizliFiltre = HizliFiltre.tumu;
    }
    notifyListeners();
    await _konumlariKaydet();
  }

  Future<void> konumGuncelle(KayitliKonum yeni) async {
    konumlar = konumlar.map((k) => k.id == yeni.id ? yeni : k).toList();
    _bultenleriYenidenHesapla();
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
      _yanit = await DepremServisi.getir(
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

    // Bultenler ve haberler ana listeyi bekletmesin
    unawaited(bultenleriYenile());
    unawaited(haberleriYenile());
  }

  /// Resmi haber kaynagindan deprem haberlerini ceker.
  ///
  /// Haber bulunamamasi HATA DEGILDIR: deprem haberi ancak kayda deger
  /// bir deprem oldugunda cikar. Bu yuzden ayri bir hata durumu
  /// tutmuyoruz; liste bos kalir ve arayuz bunu normal karsilar.
  Future<void> haberleriYenile() async {
    haberYukleniyor = true;
    notifyListeners();
    try {
      haberler = await HaberServisi.getir();
    } catch (_) {
      haberler = const [];
    } finally {
      haberYukleniyor = false;
      duyuruSonGuncelleme = DateTime.now();
      notifyListeners();
    }
  }

  /// Duyuru bultenlerini AYRI bir sorguyla yeniler.
  ///
  /// NEDEN AYRI?
  ///   Ana liste "son 7 gun, tum buyuklukler" istiyor; bultenler ise
  ///   "son 30 gunun onemli depremleri". Ayni veriden uretilemez:
  ///   30 gunluk tum depremler on binlerce kayit olurdu.
  ///
  /// NEDEN HER ZAMAN AFAD?
  ///   Kandilli endpoint'i tarih araligi kabul etmiyor ve yalnizca son
  ///   24 saati veriyor. Kullanici Kandilli secmis olsa bile 30 gunluk
  ///   bulten uretmenin baska yolu yok. AFAD ise sunucu tarafinda hem
  ///   tarih hem minmag filtresi destekliyor: 30 gun / 3.0+ sorgusu
  ///   yaklasik 85 kayit donuyor.
  Future<void> bultenleriYenile() async {
    bultenYukleniyor = true;
    bultenHatasi = null;
    notifyListeners();

    try {
      final yanit = await DepremServisi.bultenIcinGetir(
        kaynak: VeriKaynagi.afad,
        gunSayisi: bultenGunSayisi,
        minBuyukluk: BultenUretici.esikBuyukluk,
      );
      _bultenler = BultenUretici.uret(
        depremler: yanit.depremler,
        konumlar: konumlar,
      );
    } catch (e) {
      bultenHatasi = e.toString().replaceFirst('Exception: ', '');
      _bultenler = const [];
    } finally {
      bultenYukleniyor = false;
      duyuruSonGuncelleme = DateTime.now();
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
    kaynak = VeriKaynagi.otomatik;
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
