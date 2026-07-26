# Kurulum Rehberi (macOS)

Bu dosya Flutter'ı sıfırdan kurup uygulamayı çalıştırmayı anlatıyor.

## Hızlı yol: iOS Simulator

Mac kullanıyorsan en kolay yol **iPhone simülatörü** — Android Studio ve emülatör kurmana gerek kalmaz.

Klasördeki **`calistir-ios.command`** dosyasına çift tıkla. Script Flutter, Xcode ve CocoaPods'u kontrol eder, eksik varsa ne yapman gerektiğini söyler, her şey hazırsa uygulamayı simülatörde açar.

> macOS ilk seferde "geliştirici doğrulanamadı" diyebilir. Dosyaya **sağ tık → Aç → Aç** de. Bir kez yeterli.

**Gerekenler:**

| Araç | Kurulum |
|---|---|
| Xcode | App Store'dan (~10 GB). Kurduktan sonra **bir kez aç** ve lisansı kabul et. |
| Flutter | `brew install --cask flutter` |
| CocoaPods | `brew install cocoapods` |

Xcode kurduktan sonra bir kez şunları çalıştır:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

**iOS'ta internet izni gerekmez** — o adım (aşağıdaki Adım 6) sadece Android için.

### Klasör adı hakkında

Bu klasörün adı `yaz_stajı_proje` ve içinde **ı** harfi var. Dart paket adları sadece `a-z`, `0-9` ve `_` içerebilir, bu yüzden düz `flutter create .` komutu hata verir. Script bunu şu şekilde aşıyor:

```bash
flutter create --project-name deprem_takip --org com.tunakilic --platforms=ios,android .
```

Elle çalıştıracaksan sen de bu komutu kullan, `flutter create .` değil.

---

## Ayrıntılı yol: Android emülatörü

Aşağısı Android üzerinden gitmek istersen geçerli.

> **Süre beklentisi:** İyi giderse 1.5-2 saat. İnternetin yavaşsa daha uzun. Toplam ~10 GB indirme var. Bu normal — Gün 1'in tamamı buna ayrılmış durumda, geride kalmış hissetme.

---

## Adım 1 — Flutter SDK

En kolay yol Homebrew ile:

```bash
# Homebrew yoksa önce onu kur:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutter'ı kur
brew install --cask flutter

# Kontrol et
flutter --version
```

`flutter --version` çıktısında **Flutter 3.27 veya üzeri** görmelisin. Daha eskiyse `flutter upgrade` çalıştır.

---

## Adım 2 — Android Studio

1. [developer.android.com/studio](https://developer.android.com/studio) adresinden indir ve kur
2. İlk açılışta çıkan sihirbazı **Standard** seçeneğiyle tamamla (Android SDK'yı indirir)
3. Açılınca: **Settings → Languages & Frameworks → Android SDK → SDK Tools** sekmesi
4. Şunların işaretli olduğundan emin ol:
   - Android SDK Command-line Tools
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - Android Emulator

---

## Adım 3 — Lisansları Onayla

```bash
flutter doctor --android-licenses
```

Çıkan tüm sorulara `y` yaz. Sonra:

```bash
flutter doctor
```

**Android toolchain** satırında yeşil tik ✓ görmelisin. Xcode ve CocoaPods satırlarında hata olması sorun değil — sadece iOS için gerekli, Android'de çalışacaksan görmezden gel.

---

## Adım 4 — Emülatör Oluştur

Android Studio'da:

1. Sağ üstteki **Device Manager** (telefon ikonu) → **Create Device**
2. **Pixel 7** seç → İleri
3. Sistem imajı olarak **API 34 (Android 14)** indir ve seç
4. **Finish**, sonra ▶ ile emülatörü başlat

Emülatörün açılması ilk seferde 1-2 dakika sürebilir.

**Makinen zorlanıyorsa:** Emülatör ayarlarında RAM'i 2048 MB'a düşür, çözünürlüğü küçült. Yine de ağırsa alternatif olarak `flutter run -d macos` ile uygulamayı masaüstünde çalıştırabilirsin — mobil demo kadar etkileyici değil ama geliştirirken çok daha hızlı.

---

## Adım 5 — Projeyi Hazırla

```bash
cd ~/Documents/GitHub/yaz_stajı_proje

# Platform klasörlerini üret (lib/ ve pubspec.yaml'a DOKUNMAZ)
# --project-name ZORUNLU: klasör adındaki "ı" harfi geçerli bir
# Dart paket adı olmadığı için düz "flutter create ." hata verir.
flutter create --project-name deprem_takip --org com.tunakilic --platforms=ios,android .

# Paketleri indir
flutter pub get
```

---

## Adım 6 — İnternet İzni (ATLAMA!)

`android/app/src/main/AndroidManifest.xml` dosyasını aç. `<application` satırının **üstüne** şu satırı ekle:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Dosya şuna benzemeli:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="deprem_takip"
        ...
```

> Bu adımı atlarsan uygulama açılır, ekran gelir, ama veri çekemez ve "sunucu yanıt vermedi" hatası alırsın. Bu hatayı aldığında ilk buraya bak.

---

## Adım 7 — Çalıştır

Emülatör açıkken:

```bash
flutter devices    # emülatör listede görünmeli
flutter run
```

Uygulama açılınca deprem listesi gelmeli.

**Faydalı kısayollar** (`flutter run` çalışırken terminalde):

| Tuş | İşlev |
|---|---|
| `r` | Hot reload — değişikliği anında uygular |
| `R` | Hot restart — uygulamayı baştan başlatır |
| `q` | Çıkış |

Hot reload Flutter'ın en güzel özelliği: bir rengi değiştirip `r`'ye bastığında değişikliği anında görürsün.

---

## Sık Karşılaşılan Hatalar

| Hata | Sebep ve çözüm |
|---|---|
| `No devices found` | Emülatör açık değil. Android Studio → Device Manager → ▶ |
| `SocketException` / "sunucu yanıt vermedi" | AndroidManifest.xml'e INTERNET izni eklenmemiş (Adım 6) |
| `Could not resolve dependencies` | `flutter pub get` çalıştır. Olmazsa `flutter clean && flutter pub get` |
| `Android license status unknown` | `flutter doctor --android-licenses` çalıştır, hepsine `y` |
| Harita boş / gri görünüyor | İnternet yok ya da INTERNET izni eksik. Döşemeler internetten indiriliyor. |
| Gradle çok yavaş | İlk derleme 5-10 dakika sürer, normaldir. Sonrakiler hızlı. |
| `Xcode not installed` uyarısı | Android'de çalışacaksan görmezden gel |

---

## 7 Günlük Plan

### Gün 1 — Kurulum
Bu dosyadaki adımları tamamla. Uygulamayı emülatörde çalışır halde gör. Başka bir şey yapma; bu gün zaten dolu.

### Gün 2 — Kurcala ve Tanı
Uygulamayı kullan. Kaynakları değiştir, filtrelerle oyna, haritayı aç.
Sonra küçük değişiklikler yapıp hot reload ile sonucu gör:

- `main.dart` içindeki `seedColor` değerini değiştir → tema rengi değişsin
- `utils/buyukluk_stili.dart` içindeki renkleri değiştir
- `widgets/deprem_karti.dart` içindeki rozet boyutunu (`width: 56`) değiştir

Amaç kod okumak değil, dosya-ekran eşleşmesini kafanda kurmak.

### Gün 3 — Kodu Anla
Şu sırayla oku (hepsi Türkçe yorumlu):

1. `models/deprem.dart` — iki farklı JSON tek modele nasıl dönüşüyor
2. `services/deprem_servisi.dart` — HTTP isteği nasıl atılıyor, hatalar nasıl yakalanıyor
3. `screens/ana_ekran.dart` — `setState` ne yapıyor, `initState` ne zaman çalışıyor
4. `screens/harita_ekrani.dart` — işaretçiler nasıl üretiliyor

**Anlamayı test et.** Şu sorulara kendi cümlelerinle cevap yazabiliyor musun?

- `setState` çağırmazsan ne olur?
- Neden iki farklı `factory` metodu var (`afaddan`, `kandilliden`)?
- GeoJSON koordinat sırası neden önemli?
- `async`/`await` ne işe yarıyor, olmasa ne olurdu?

Yazamadığın varsa bana sor.

### Gün 4 — Kendi Eklemeni Yap
Bir tane seç:

**Kolay (1-2 saat)**
- Uygulama ikonu ve adını değiştir
- Listeye "en büyükten küçüğe sırala" seçeneği ekle
- Detay ekranına "koordinatları kopyala" butonu
- Boş liste ekranındaki metni ve görseli iyileştir

**Orta (3-4 saat)**
- Son aramayı hatırlama (`shared_preferences` paketi)
- Favorilere ekleme / kaydedilen depremler listesi
- Basit bir istatistik ekranı: şehre göre deprem sayısı
- Harita ekranına "büyüklüğe göre filtrele" kaydırıcısı

Seçtiğini söyle, birlikte yazalım.

### Gün 5 — Test Et ve Kır
Bilerek zorla:

- [ ] Emülatörde interneti kapat (Ayarlar → Uçak modu) → hata ekranı düzgün mü?
- [ ] Minimum büyüklüğü 6'ya çek → boş liste ekranı düzgün mü?
- [ ] Çok hızlı defalarca yenile → çöküyor mu?
- [ ] Ekranı yan çevir → düzen bozuluyor mu?
- [ ] Aramaya anlamsız bir şey yaz → düzgün mesaj var mı?
- [ ] Koyu temaya geç (emülatör ayarlarından) → okunuyor mu?

Bulduğun her şeyi not et. Düzeltemediklerini README'nin "Bilinen Sınırlar" bölümüne ekle — bu zayıflık değil, olgunluk göstergesidir.

### Gün 6 — Demoyu Hazırla

**Sunum sırası (5 dakika):**

1. **30 sn** — Problem: "Deprem bilgisine hızlı ve tek yerden ulaşmak"
2. **1.5 dk** — Canlı demo: liste → filtre → harita → detay
3. **1.5 dk** — Nasıl çalışıyor: API'den veri → model → ekran akışını anlat
4. **1 dk** — Karşılaştığın teknik sorunlar (README'deki 5 madde) ve ne eklediğin
5. **30 sn** — Sınırlar ve geliştirilebilecek yönler

**Mutlaka yap:**
- Emülatörün ekran kaydını al (macOS: `Cmd+Shift+5`) — internet çökerse yedeğin olur
- Ekran görüntülerini README'ye ekle
- Bir kez baştan sona prova yap, süreyi tut

> **Demoda en etkili an:** Veri kaynağını AFAD'dan Kandilli'ye değiştirip listenin yenilenmesi. "İki farklı kurumun API'sini tek modele bağladım, biri çökerse diğerine geçiyor" demek, mühendislik düşüncesi gösterir.

### Gün 7 — Toparla ve Teslim Et

1. README'yi güncelle: kendi ekran görüntülerin, eklediğin özellik, bulduğun sınırlar
2. `flutter analyze` çalıştır, uyarıları temizle
3. GitHub'a gönder:
   ```bash
   git add .
   git commit -m "Depremin Nabzı uygulamasi"
   git push
   ```
4. Son kontrol: Projeyi başka bir klasöre kopyalayıp bu dosyadaki adımlarla sıfırdan kurmayı dene

---

## Zaman Sıkışırsa

| Durum | Ne yap |
|---|---|
| 3 günüm kaldı | Gün 1 → Gün 3 → Gün 6. Ekleme yapma, anlamaya odaklan. |
| 1 günüm kaldı | Sadece kurulumu bitir, çalışır halde göster, README'yi oku. |
| Kurulum hiç olmuyor | Hata mesajını olduğu gibi bana yapıştır. |

---

## Demoda Gelebilecek Sorular

**"Verileri nereden alıyorsun?"**
AFAD'ın resmi API'sinden ve Kandilli Rasathanesi verisinden. İkisi arasında uygulama içinden geçiş yapılabiliyor.

**"Neden iki kaynak?"**
Test ederken AFAD'ın zaman zaman gecikmeli veri yayınladığını gördüm. Tek kaynağa bağlı kalırsam uygulama boş liste gösterebilirdi. İki kaynak desteklemek hem yedeklilik sağlıyor hem de verileri karşılaştırma imkânı veriyor.

**"Google Maps neden kullanmadın?"**
Google Maps API anahtarı ve faturalandırma hesabı istiyor. OpenStreetMap ücretsiz ve açık kaynak; `flutter_map` paketiyle sorunsuz çalışıyor.

**"En çok nerede zorlandın?"**
İki API'nin koordinat sırasının farklı olması. Kandilli GeoJSON standardında `[boylam, enlem]` gönderiyor, AFAD ise ayrı alanlar veriyor. Karıştırınca işaretçiler haritada tamamen yanlış yere düşüyordu.

**"Ne kadar sürdü?"**
Dürüst ol. Hazır bir temelden başlayıp anladığını ve üstüne eklediğini söylemek tamamen meşru — asıl değerlendirilen ne kadar kavradığın.
