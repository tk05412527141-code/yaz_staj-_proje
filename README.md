# 🌍 Deprem Takip

Türkiye ve çevresindeki son depremleri **AFAD** ve **Kandilli Rasathanesi** verileriyle gösteren Flutter mobil uygulaması.

Liste görünümü, harita üzerinde işaretçiler, büyüklük/tarih/konum filtreleri ve deprem detay ekranı içerir.

---

## Özellikler

- **İki veri kaynağı** — AFAD ve Kandilli arasında geçiş yapılabilir. Biri gecikirse veya erişilemezse diğerine geçerek uygulama çalışmaya devam eder.
- **Liste görünümü** — büyüklüğe göre renk kodlu kartlar, "3 saat önce" gibi okunabilir zaman bilgisi
- **Harita görünümü** — tüm depremler tek haritada; işaretçi boyutu ve rengi büyüklüğe göre değişir
- **Filtreler** — zaman aralığı (24 saat / 3 / 7 / 30 gün), minimum büyüklük, konum arama
- **Detay ekranı** — konum haritası, derinlik, koordinatlar, tam tarih, kaynak bilgisi
- **Aşağı çekerek yenileme** ve anlaşılır hata ekranları
- **Koyu tema desteği** — telefonun sistem ayarını takip eder

**API anahtarı gerekmez.** Hem deprem verileri hem de harita (OpenStreetMap) tamamen ücretsiz ve açık kaynaklıdır.

---

## Ekran Yapısı

```
┌──────────────────────────┐     ┌──────────────────────────┐
│ Deprem Takip   🗺 ⚙ ↻    │     │  Deprem Detayı           │
├──────────────────────────┤     ├──────────────────────────┤
│ Veri kaynağı: AFAD |Kand.│     │         ███ 4.1 ███      │
│ Zaman: 24s |3g |7g |30g  │     │       Hissedilir         │
│ Min büyüklük: ──●───     │     │    Akçadağ (Malatya)     │
│ 🔍 Konum ara             │     ├──────────────────────────┤
├──────────────────────────┤     │                          │
│ 128 deprem · en büyük 5.2│     │      [  HARİTA  ]        │
├──────────────────────────┤     │                          │
│ ┌───┐ Akçadağ (Malatya)  │     ├──────────────────────────┤
│ │4.1│ Hissedilir·11.5 km │ ──▶ │ 🕐 23.07.2026 07:26      │
│ └───┘ 3 gün önce      ›  │     │ ⬇  11.46 km              │
│ ┌───┐ Ege Denizi         │     │ 📍 38.3507, 37.8618      │
│ │3.9│ Orta · 13.4 km     │     │ ✓  AFAD                  │
│ └───┘ 2 gün önce      ›  │     │                          │
└──────────────────────────┘     └──────────────────────────┘
```

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
├── main.dart                     Uygulama girişi, tema ayarları
├── models/
│   └── deprem.dart               Deprem veri modeli + iki farklı JSON çözümleyici
├── services/
│   └── deprem_servisi.dart       AFAD ve Kandilli API istekleri
├── screens/
│   ├── ana_ekran.dart            Liste + filtreler
│   ├── detay_ekrani.dart         Tek deprem detayı + harita
│   └── harita_ekrani.dart        Tüm depremler haritada
├── widgets/
│   └── deprem_karti.dart         Listedeki tek kart
└── utils/
    └── buyukluk_stili.dart       Büyüklüğe göre renk / etiket / boyut
```

Bu ayrım bilinçli: **veri (model)**, **veri çekme (service)**, **görüntüleme (screen/widget)** birbirinden ayrı. Bir API değişirse sadece `services/` düzenlenir, ekranlara dokunulmaz.

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

---

## Bilinen Sınırlar

- **Saat dilimi** — İki kurumun saatleri farklı dilimlerde olabilir (UTC / TSİ). Uygulama gelen değeri olduğu gibi gösteriyor; kaynaklar arası saat farkı doğrulanmadı.
- **Bildirim yok** — Yeni deprem olduğunda uygulama kendiliğinden haber vermiyor.
- **Çevrimdışı çalışmıyor** — Veriler önbelleğe alınmıyor, internet yoksa liste boş kalır.
- **Kandilli API'si resmi değil** — Üçüncü taraf bir servis üzerinden erişiliyor, kapanma ihtimali var. AFAD ise doğrudan resmi kaynaktan.
- **Harita kümeleme yok** — Çok sayıda deprem olduğunda işaretçiler üst üste biniyor.

## Geliştirilebilecek Yönler

- Belirli büyüklüğün üzerindeki depremler için bildirim gönderme
- Verileri yerel veritabanına kaydedip çevrimdışı erişim
- Yakındaki depremleri gösterme (konum izni ile)
- Harita işaretçilerini kümeleme (`flutter_map_marker_cluster`)
- Şehir bazlı deprem istatistikleri ve grafikler
- Saat dilimi normalizasyonu

---

## Lisans ve Kaynak Bilgisi

Deprem verileri AFAD ve Boğaziçi Üniversitesi Kandilli Rasathanesi'ne aittir.
Harita verileri © OpenStreetMap katkıda bulunanlar.
Bu uygulama eğitim amaçlı bir staj projesidir.
