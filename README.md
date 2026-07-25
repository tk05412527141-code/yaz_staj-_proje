# 🌍 Deprem Takip

Türkiye ve çevresindeki son depremleri **AFAD** ve **Kandilli Rasathanesi** verileriyle gösteren Flutter mobil uygulaması.

Liste görünümü, harita üzerinde işaretçiler, büyüklük/tarih/konum filtreleri ve deprem detay ekranı içerir.

---

## Özellikler

- **Yerlerim ve hissedilirlik tahmini** — ev, iş, ailenin evi gibi yerleri kaydedersin; her deprem için o noktalarda ne kadar hissedileceği tahmin edilir. "4.1" yerine **"Evinizden 340 km — hissetmeyeceksiniz"**.
- **İlk açılış tanıtımı** — üç ekranda uygulamanın neden farklı olduğu anlatılır ve kullanıcı ilk yerini ekleyerek başlar
- **Kişisel durum kartı** — listenin en üstünde: *"Yerleriniz sakin — son 24 saatte hissedilmesi beklenen deprem yok"*
- **Günlere ayrılmış liste** — kaydırırken üste yapışan "Bugün / Dün / 20 Temmuz" başlıkları
- **Erişilebilirlik** — ekran okuyucu etiketleri, renge ek olarak sayıyla kodlama, büyük yazı tipine uyum, 48×48 dokunma hedefleri
- **Üç sekmeli yapı** — Liste, Harita ve Ayarlar. Alt sekme çubuğu ile tek elle erişilebilir.
- **İki veri kaynağı** — AFAD ve Kandilli arasında geçiş yapılabilir. Biri gecikirse veya erişilemezse diğerine geçerek uygulama çalışmaya devam eder.
- **Tek dokunuşluk hızlı filtreler** — Tümü / Yerlerim / Son 1 saat / Bugün / Hissedilenler 3.0+ / Güçlü 4.5+
- **Ayrıntılı filtre paneli** — alttan açılır: kaynak, zaman aralığı, minimum büyüklük, sıralama
- **Tercih hafızası** — seçilen kaynak ve filtreler telefonda saklanır, uygulama kapanınca unutulmaz
- **İskelet yükleme** — boş ekran yerine parıldayan kart taslakları; bekleme daha kısa hissettirir
- **Etkileşimli harita** — işaretçiye dokununca alttan özet kart çıkar, oradan detaya geçilir
- **Paylaş ve kopyala** — deprem bilgisi, koordinatlar veya harita bağlantısı panoya kopyalanabilir
- **Aşağı çekerek yenileme**, Hero geçişi, dokunsal geri bildirim ve yol gösteren hata/boş ekranlar

**API anahtarı gerekmez.** Hem deprem verileri hem de harita (OpenStreetMap) tamamen ücretsiz ve açık kaynaklıdır.

---

## Ekran Yapısı

```
┌──────────────────────────┐   ┌──────────────────────────┐
│ Son Depremler        ↻   │   │ ◀            Paylaş ⇪    │
│ ● Kandilli · az önce     │   │                          │
│ ┌────────────────┐ ┌───┐ │   │          4.1             │
│ │🔍 Şehir ara    │ │ ⚙②│ │   │       HİSSEDİLİR         │
│ └────────────────┘ └───┘ │   ├──────────────────────────┤
│ [Tümü][📍Yerlerim][Bugün]│   │ ┌─────────┐ ┌──────────┐ │
├──────────────────────────┤   │ │BÜYÜKLÜK │ │ DERİNLİK │ │
│ ┌──────────────────────┐ │   │ │  4.1    │ │  11.5    │ │
│ │ ✓ Yerleriniz sakin   │ │   │ └─────────┘ └──────────┘ │
│ │   Son 24 saatte yok  │ │   ├──────────────────────────┤
│ └──────────────────────┘ │   │ YERLERİNİZDE             │
│ 128 deprem · en büyük 5.2│   │ 🏠 Evim  340km hissedilmez│
├─ Bugün  12 ──────────────┤   │ 💼 Ofis  355km hissedilmez│
│ ▌┌───┐ Akçadağ (Malatya) │──▶├──────────────────────────┤
│ ▌│4.1│ 🕐3sa ⬇11.5km   › │   │ ┌──────────────────────┐ │
│ ▌│ M │ 🏠 Evim·340km    │   │ │      HARİTA          │ │
│ ▌└───┘    Hissedilmez    │   │ └──────────────────────┘ │
├─ Dün  8 ─────────────────┤   │ 📍 Konum · 🕐 Tarih      │
│ ▌┌───┐ Ege Denizi        │   │ [Bilgileri] [Koordinat]  │
│ ▌│3.9│ 🕐2 gün ⬇13.4km › │   │ [ kopyala ] [ kopyala  ] │
├──────────────────────────┤   └──────────────────────────┘
│  ▣ Liste  🗺 Harita  ⚙   │
└──────────────────────────┘
```

---

## Hissedilirlik Tahmini — Nasıl Hesaplanıyor?

Bu uygulamanın diğer deprem uygulamalarından ayrıldığı yer burası.

**Problem:** Büyüklük tek başına kimseye bir şey ifade etmiyor. 300 km uzaktaki 5.0 hiç hissedilmezken 10 km yakındaki 4.0 insanı uykudan uyandırabilir. Kullanıcının asıl merak ettiği soru "kaç şiddetinde?" değil, **"beni etkiler mi?"**

**Çözüm:** Kullanıcı takip ettiği yerleri kaydediyor, uygulama her deprem için o noktalardaki tahmini Mercalli şiddetini hesaplıyor.

### Kullanılan model

> Allen, T. I., Wald, D. J. & Worden, C. B. (2012).
> *Intensity attenuation in active crustal regions.*
> Journal of Seismology, 16: 409–433.

Hiposantr mesafeli sürüm kullanıldı. Katsayılar [OpenQuake Engine](https://github.com/gem/oq-engine)'in açık kaynak uygulamasından alındı (`AllenEtAl2012Rhypo`).

```
Rm  = m₁ + m₂ · e^(M−5)
MMI = c₀ + c₁·M + c₂·ln(√(R² + Rm²))        R ≤ 50 km
MMI = ... + c₄·ln(R/50)                      R > 50 km
```

`R` hiposantr mesafesi — yani yüzey mesafesi ve derinliğin hipotenüsü. Yüzey mesafesi haversine formülüyle hesaplanıyor.

### Geçerlilik ve dürüstlük

Yayının belirttiği geçerlilik aralığı **M 5.0–7.9** ve **300 km**. Uygulamada gösterilen depremlerin çoğu M5'in altında, yani model ekstrapolasyon yapıyor. Bu durum gizlenmiyor:

- Sonuç ondalıklı bir sayı olarak değil, **kaba kategori** olarak gösteriliyor (Hissedilmez / Zor / Hafif / Belirgin / Güçlü / Çok güçlü / Şiddetli)
- Geçerlilik aralığı dışındaki tahminler **"(tahmini)"** etiketiyle işaretleniyor
- Her ekranda gerçek sarsıntının zemin yapısı, bina türü ve kat yüksekliğine göre değişeceği belirtiliyor

MMI değeri 1–12 aralığına kırpılıyor; sıfır mesafe, negatif derinlik ve bozuk veri durumları test edilmiş durumda.

### Gizlilik

Kayıtlı konumlar **yalnızca telefonda** saklanıyor. Hiçbir sunucuya gönderilmiyor, konum izni istenmiyor — kullanıcı yerini şehir listesinden veya haritadan kendisi seçiyor.

---

## Tasarım Kararları

**Koyu tema, tek seçenek.** Deprem/afet uygulamalarının yaygın görsel dili koyu zemin. Büyüklük renkleri koyu üzerinde çok daha okunaklı çıkıyor ve gece bakıldığında göz yormuyor.

**Bilgi hiyerarşisi.** Kartta göz önce sol taraftaki renkli büyüklük rozetine takılıyor, sonra konuma, en son derinlik/zaman gibi ayrıntılara. Sol kenardaki renk şeridi listeyi hızlı taramayı sağlıyor.

**Sık kullanılan üstte, nadir kullanılan panelde.** Hızlı filtreler ana ekranda; kaynak seçimi, sıralama gibi daha seyrek değiştirilenler alttan açılan panelde. Ana ekran böylece sade kalıyor.

**İskelet yükleme.** Dönen çark yerine kart taslakları gösteriliyor. Kullanıcı ne geleceğini gördüğü için bekleme daha kısa hissediliyor, ekran dolduğunda sıçrama olmuyor.

**Filtre rozeti.** Kaç filtre aktifse filtre butonunda sayı olarak görünüyor — kullanıcı "neden az sonuç var?" sorusunun cevabını arayüzde görüyor.

**Değer ilk 30 saniyede görünüyor.** Uygulamanın en iyi özelliği (hissedilirlik tahmini) eskiden ayarların içinde saklıydı. Görünmeyen özellik, olmayan özellikle aynı şeydir. Artık ilk açılışta üç ekranlık bir tanıtım problemi anlatıyor ve kullanıcıyı ilk yerini eklemeye yönlendiriyor — atlanabilir tutuldu, zorunlu onboarding kullanıcı kaçırır.

**Cevap en üstte.** İnsanın bu uygulamayı açma sebebi tek bir soru: "son 24 saatte benim yerlerimde bir şey oldu mu?" Durum kartı bu cevabı listenin en üstüne koyuyor; kullanıcı 200 kart taramak zorunda kalmıyor. Üç hâli var: yer yok (ekleme çağrısı), sakin (yeşil onay), sarsıntı var (en güçlüsünün özeti).

**Gün başlıkları.** Düz bir liste zaman algısını kaybettiriyordu. Yapışkan "Bugün / Dün / 20 Temmuz" başlıkları listeyi taranabilir kılıyor. Büyüklüğe göre sıralamada gruplama anlamsızlaştığı için otomatik olarak düz listeye dönülüyor.

**Erişilebilirlik baştan.** Büyüklük yalnızca renkle değil sayıyla da kodlanıyor (harita işaretçileri dahil) — renk körlüğü olan kullanıcı bilgi kaybetmiyor. Kartlar tek bir Semantics düğümü olarak anlamlı bir cümle okunuyor, parça parça değil. Rozetlerdeki sayılar FittedBox içinde, büyük yazı tipi ayarında taşmıyor. Dokunma hedefleri en az 48×48.

**Dokunsal geri bildirim.** Filtre seçimi, sekme değişimi, yenileme ve konum kaydetme anlarında farklı şiddetlerde titreşim. Bilinçli fark edilmiyor ama "pahalı uygulama" hissinin kaynaklarından.

**Boş ekranlar yol gösteriyor.** Her boş/hata ekranı üç soruya cevap veriyor: ne oldu, neden oldu, şimdi ne yapabilirim. Bu yüzden hepsinde bir eylem butonu var — hata durumunda "diğer kaynağı dene" gibi.

---

## Kurulum

### 1. Gereksinimler

| Araç | Not |
|---|---|
| Flutter SDK 3.27+ | Dart 3.6+ içerir |
| Android Studio | Emülatör ve Android araçları için |
| Yaklaşık 10 GB disk | SDK + emülatör imajı |

Kurulumun tamamı için **KURULUM.md** dosyasına bak — adım adım anlatılıyor.

### 2. Projeyi hazırla

Bu depo sadece `lib/` klasörünü ve `pubspec.yaml`'ı içeriyor. Platform klasörlerini (`android/`, `ios/`) Flutter'ın kendisi üretir:

```bash
cd yaz_stajı_proje

# Platform klasörlerini oluştur (lib/ ve pubspec.yaml'a dokunmaz)
flutter create --project-name deprem_takip --org com.tunakilic --platforms=ios,android .

# Paketleri indir
flutter pub get
```

### 3. İnternet iznini ekle

Android'de uygulamanın internete çıkabilmesi için izin gerekiyor.
`android/app/src/main/AndroidManifest.xml` dosyasını aç ve `<application` satırının **üstüne** şunu ekle:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

> Bu adımı atlarsan uygulama açılır ama veri çekemez ve "sunucu yanıt vermedi" hatası alırsın. En sık yapılan hatalardan biri.

### 4. Çalıştır

```bash
# Bağlı cihazları listele
flutter devices

# Uygulamayı başlat
flutter run
```

---

## Proje Yapısı

```
lib/
├── main.dart                     Uygulama girişi, tema kaydı
├── models/
│   ├── deprem.dart               Veri modeli + iki farklı JSON çözümleyici
│   └── kayitli_konum.dart        Kullanıcının takip ettiği yerler
├── services/
│   ├── deprem_servisi.dart       AFAD ve Kandilli API istekleri
│   └── tercih_servisi.dart       Filtreleri ve konumları telefonda saklama
├── state/
│   └── deprem_deposu.dart        Ortak durum: veri + filtreler (ChangeNotifier)
├── screens/
│   ├── ana_kabuk.dart            Alt sekme çubuğu, sekme yönetimi
│   ├── liste_sekmesi.dart        Arama, hızlı filtreler, liste
│   ├── harita_sekmesi.dart       Tüm depremler haritada + seçim kartı
│   ├── ayarlar_sekmesi.dart      Kaynak seçimi, tercihler, hakkında
│   ├── tanitim_ekrani.dart       İlk açılış tanıtımı (3 ekran)
│   ├── yerlerim_ekrani.dart      Kayıtlı yerlerin listesi
│   ├── konum_ekle_ekrani.dart    Şehirden veya haritadan yer seçme
│   └── detay_ekrani.dart         Detay + yerlerdeki etki + paylaşım
├── widgets/
│   ├── deprem_karti.dart         Listedeki tek kart
│   ├── durum_karti.dart          Listenin üstündeki kişisel özet
│   ├── iskelet_kart.dart         Yükleme sırasındaki parıldayan taslaklar
│   ├── filtre_sayfasi.dart       Alttan açılan filtre paneli
│   └── durum_gorunumu.dart       Boş / hata ekranları
└── utils/
    ├── tema.dart                 Renk paleti ve bileşen stilleri
    ├── buyukluk_stili.dart       Büyüklüğe göre renk / etiket / boyut
    ├── siddet_hesabi.dart        Mesafe + tahmini sarsıntı şiddeti
    ├── gun_gruplama.dart         Listeyi günlere ayırma, başlık metinleri
    └── sehirler.dart             81 il koordinatı, konum simgeleri
```

Bu ayrım bilinçli: **veri (model)**, **veri çekme (service)**, **durum (state)**, **görüntüleme (screen/widget)** birbirinden ayrı. Bir API değişirse sadece `services/` düzenlenir, ekranlara dokunulmaz.

### Durum yönetimi neden ayrı bir katmanda?

Üç sekme de aynı veriyi ve aynı filtreleri kullanıyor. Her sekme kendi verisini çekseydi hem gereksiz istek atılır hem de listede uygulanan filtre haritaya yansımaz, sekmeler arasında tutarsızlık olurdu.

Çözüm: `DepremDeposu` adında bir `ChangeNotifier`. Tek örneği `AnaKabuk` içinde oluşturulup üç sekmeye de veriliyor. Durum değişince `notifyListeners()` çağrılıyor, ekranlar `ListenableBuilder` ile dinleyip kendini yeniliyor. Provider/Riverpod gibi bir paket kullanılmadı — Flutter'ın kendi araçları bu ölçek için yeterli.

Filtreler ikiye ayrılmış durumda:

- **Sunucuya giden filtreler** (kaynak, zaman aralığı, minimum büyüklük) — değişince yeniden istek atılır
- **Cihazda uygulanan filtreler** (hızlı filtre, arama, sıralama) — anında sonuç verir, istek atmaz

Bu ayrım sayesinde arama kutusuna her harf yazıldığında API'ye gidilmiyor.

---

## Kullanılan Veri Kaynakları

### AFAD (resmi)

```
GET https://deprem.afad.gov.tr/apiv2/event/filter
    ?start=2026-07-19T00:00:00
    &end=2026-07-26T23:59:59
    &orderby=timedesc
    &limit=1000
    &minmag=3.5
```

Düz bir JSON dizisi döner. **Dikkat edilmesi gereken:** tüm sayısal alanlar metin olarak gelir (`"magnitude": "3.7"`), bu yüzden `double.tryParse` ile çevrilir.

### Kandilli (açık API üzerinden)

```
GET https://api.orhanaydogdu.com.tr/deprem/kandilli/live?limit=500
```

`{"status": true, "result": [...]}` şeklinde sarmalanmış döner. **Dikkat edilmesi gereken:** koordinatlar GeoJSON standardındadır, yani sıra `[boylam, enlem]` — alışılmış `[enlem, boylam]` sırasının tersi. Harita uygulamalarında en sık yapılan hatalardan biri budur.

### Harita

OpenStreetMap döşemeleri, `flutter_map` paketi üzerinden. Google Maps'ten farklı olarak API anahtarı ve faturalandırma hesabı gerektirmez.

---

## Karşılaşılan Teknik Sorunlar ve Çözümleri

Demoda "nerede zorlandın?" sorusuna verilebilecek gerçek cevaplar:

**1. AFAD sayıları metin olarak gönderiyor**
`json['magnitude']` doğrudan `double`'a atanamıyor. `double.tryParse` ile çevrilip başarısızlık durumunda `0` kullanılıyor.

**2. İki API'nin koordinat sırası farklı**
AFAD ayrı `latitude`/`longitude` alanları veriyor, Kandilli ise GeoJSON dizisi `[boylam, enlem]`. Karıştırılırsa işaretçiler haritada tamamen yanlış yere düşer.

**3. Türkçe karakterler bozuk görünüyordu**
`response.body` yerine `utf8.decode(response.bodyBytes)` kullanılarak çözüldü. Aksi halde "Çanakkale" gibi isimler bozuk çıkıyor.

**4. AFAD verisi zaman zaman gecikmeli**
Test sırasında AFAD'ın yaklaşık 22 saat gecikmeli veri yayınladığı görüldü (son kayıt 25 Temmuz 01:47 iken Kandilli'de 25 Temmuz 23:49 vardı). Bu yüzden varsayılan kaynak Kandilli, varsayılan zaman aralığı ise 7 gün seçildi — "son 24 saat" filtresinin boş liste döndürme riski var.

**5. Tarih formatları farklı**
AFAD `2026-07-25T07:40:15`, Kandilli `2026-07-25 23:49:05` gönderiyor. `DateTime.tryParse` boşluklu formatı kabul etmediği için boşluk `T` ile değiştiriliyor.

**6. Kaydırıcı her harekette API'ye istek atıyordu**
Minimum büyüklük kaydırıcısı `onChanged` ile bağlıyken parmak her kıpırdadığında yeni istek gidiyordu. Çözüm: `onChanged` sadece etiketi güncelliyor (`minBuyuklukOnizle`), asıl istek parmak kalkınca `onChangeEnd` ile atılıyor.

**7. Sekme değiştirince harita sıfırlanıyordu**
Normal bir `Navigator` yapısında sekme değişince widget yeniden oluşuyor, haritanın konumu ve listenin kaydırma yeri kayboluyordu. `IndexedStack` kullanılarak üç sekme de bellekte tutuluyor.

**8. `share_plus` paketi kullanılamadı**
Paketin güncel sürümü Flutter 3.38+ istiyor, projenin hedefinden çok yeni. Ayrıca iPad'de `sharePositionOrigin` verilmezse çökme sorunu var. Paylaşım bunun yerine `Clipboard` ile çözüldü — ek paket gerekmiyor, her platformda aynı çalışıyor.

---

## Bilinen Sınırlar

- **Saat dilimi** — İki kurumun saatleri farklı dilimlerde olabilir (UTC / TSİ). Uygulama gelen değeri olduğu gibi gösteriyor; kaynaklar arası saat farkı doğrulanmadı.
- **Bildirim yok** — Yeni deprem olduğunda uygulama kendiliğinden haber vermiyor.
- **Çevrimdışı çalışmıyor** — Veriler önbelleğe alınmıyor, internet yoksa liste boş kalır.
- **Sadece koyu tema** — Açık tema seçeneği yok; uygulama koyu zemin üzerine tasarlandı.
- **Şiddet tahmini yaklaşıktır** — Zemin sınıfı (Vs30), bina türü ve kat yüksekliği hesaba katılmıyor. Model M5.0 altındaki depremler için ekstrapolasyon yapıyor.
- **Sistem paylaşım menüsü yok** — Paylaşım panoya kopyalama ile yapılıyor (gerekçesi yukarıda).
- **Kandilli API'si resmi değil** — Üçüncü taraf bir servis üzerinden erişiliyor, kapanma ihtimali var. AFAD ise doğrudan resmi kaynaktan.
- **Harita kümeleme yok** — Çok sayıda deprem olduğunda işaretçiler üst üste biniyor.

## Geliştirilebilecek Yönler

- **Bildirim altyapısı** — kayıtlı yerlerde belirli bir şiddetin üzerinde tahmin edildiğinde bildirim (Firebase + sunucu gerektirir)
- Zemin sınıfı verisiyle şiddet tahminini iyileştirme
- Belirli büyüklüğün üzerindeki depremler için bildirim gönderme
- Verileri yerel veritabanına kaydedip çevrimdışı erişim
- Yakındaki depremleri gösterme (konum izni ile)
- Harita işaretçilerini kümeleme (`flutter_map_marker_cluster`)
- Şehir bazlı deprem istatistikleri ve grafikler
- Saat dilimi normalizasyonu

---

## Testler

```bash
flutter test
```

49 birim testi çalışıyor:

| Dosya | Kapsam |
|---|---|
| `test/widget_test.dart` | JSON çözümleme: AFAD'ın metin sayıları, Kandilli'nin GeoJSON koordinat sırası, bozuk/eksik veri dayanıklılığı |
| `test/siddet_hesabi_test.dart` | Haversine mesafesi, bilinen deprem senaryoları, monotonluk (mesafe ↑ → şiddet ↓), sınır durumları, geçerlilik bayrağı |
| `test/gun_gruplama_test.dart` | Gün gruplama: gece yarısı sınırı, yıl geçişi, boş liste, başlık metinleri, kayıt kaybolmaması |

Arayüz yerine bu iki katman test ediliyor çünkü projenin hataya en açık ve en kritik kısmı burası — üstelik internet gerektirmeden çalışıyorlar.

---

## Lisans ve Kaynak Bilgisi

Deprem verileri AFAD ve Boğaziçi Üniversitesi Kandilli Rasathanesi'ne aittir.
Harita verileri © OpenStreetMap katkıda bulunanlar.
Bu uygulama eğitim amaçlı bir staj projesidir.
