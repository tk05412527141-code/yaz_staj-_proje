# LinkedIn Paylaşımı — Depremin Nabzı

> **Paylaşmadan önce:** uygulamanın en az bir kez derlenip çalıştığını gör.
> Adımlar bu belgenin sonunda. Birisi "demo var mı?" diye sorduğunda
> cevabın olmalı.

---

## 1. Paylaşım metni

LinkedIn markdown'ı desteklemez — kalın yazı, başlık ve `-` madde işareti
düz metne dönüşür. Aşağıdaki metin bu yüzden düz metin olarak yazıldı;
olduğu gibi kopyalayıp yapıştırabilirsin.

```text
Bir haftada bir mobil uygulama yazdım: Depremin Nabzı.

Türkiye'deki depremleri AFAD ve Kandilli verileriyle takip eden,
Flutter ile geliştirilmiş bir uygulama.

En çok uğraştığım şey özellik listesi değil, veri gecikmesi oldu.
Ölçtüm: AFAD kayıtları zaman zaman 11 saat geriden geliyor. Kandilli
yaklaşık 5 dakika taze, ama yalnızca son 24 saati veriyor. Tek kaynağa
güvenmek her iki durumda da kullanıcıyı yanıltıyordu — biri geçmişi
görmüyor, diğeri son yarım günü kaçırıyordu.

Çözüm iki kaynağı paralel çekip birleştirmek oldu. Aynı depremi tespit
için 120 saniye ve 50 km toleransı; çakışma olduğunda AFAD'ın resmî
parametreleri korunuyor. Sınırı iki taraftan da test ettim, çünkü çok
gevşek bir kural ayrı depremleri birleştirip kayıt gizler.

Uygulamanın yaptıkları:

• Liste ve harita üzerinde son depremler
• Kayıtlı yerlerin için tahmini hissedilirlik
  (Allen, Wald & Worden 2012 şiddet modeli)
• Deprem öncesi hazırlık listesi ve hatırlatmalar
• Konumunu yakınlarına ileten acil durum ekranı

Yapmadığı bir şey var: deprem tahmini. Uygulama bunu eksiklik olarak
değil, açıkça anlatılan bir sınır olarak ele alıyor.

Konum ve kişi bilgileri yalnızca cihazda saklanıyor, hiçbir sunucuya
gönderilmiyor. Rehber izni istemiyor.

46 Dart dosyası, ~12.400 satır, 143 test.

#Flutter #Dart #MobilGeliştirme #YazılımGeliştirme #Deprem
```

**Kelime sayısı:** ~200 · **Okuma süresi:** ~50 saniye

---

## 2. Görsel çekim listesi

LinkedIn tek gönderide en fazla 20 görsel alır ama **4–5 görsel** en iyi
sonucu verir; fazlası kaydırılmadan geçilir. Sıralama önemli: ilk görsel
akışta büyük görünür, onu en güçlü ekran olmalı.

| # | Ekran | Nasıl hazırlanmalı |
|---|-------|--------------------|
| 1 | **Liste** | Birkaç deprem kaydı görünür durumda, üstte durum kartı dolu. Boş listeyi çekme. |
| 2 | **Harita** | Türkiye'ye zoomlanmış, birden fazla işaret görünür. |
| 3 | **Yerlerim / hissedilirlik** | En az bir kayıtlı yer ekle ki tahmini şiddet değeri görünsün — bu uygulamanın en ayırt edici özelliği. |
| 4 | **Duyurular** | Hem bülten hem haber kartı görünsün. Üstteki "en yeni kayıt … önce" satırı da kadraja girsin. |
| 5 | **Acil durum** | Butonu basılı tutmadan, karşılama halinde çek. |

**Çekim ipuçları**

- Simulator'da `Cmd + S` ekran görüntüsünü masaüstüne kaydeder.
- iPhone 15 Pro simulatorü seç — LinkedIn'de en temiz oranı verir.
- Simulator saatini gerçekçi bırak; sahte 9:41 gerekmez.
- Durum çubuğunda pil %100 ve tam sinyal olsun (simulator varsayılanı böyle).
- Karanlık tema zaten koyu; görselleri LinkedIn'in beyaz arayüzünde
  kontrast yaratır, ayrıca çerçeve eklemene gerek yok.

**Alt metin (accessibility) — LinkedIn her görsel için sorar:**

1. "Depremin Nabzı uygulamasının deprem listesi ekranı, son depremler büyüklüklerine göre renklendirilmiş"
2. "Uygulamanın harita ekranı, Türkiye üzerinde deprem konumları işaretlenmiş"
3. "Kayıtlı bir konum için tahmini hissedilirlik şiddetini gösteren ekran"
4. "Resmî verilerden üretilen deprem bültenleri ve haber akışı ekranı"
5. "Acil durum ekranı, konumu yakınlara gönderme butonu"

---

## 3. İlk yorumda paylaşılacak not (isteğe bağlı)

LinkedIn gönderi metnine link koyunca erişimi düşürüyor. GitHub bağlantısını
gönderiye değil, kendi gönderine yaptığın **ilk yoruma** koy:

```text
Kaynak kod ve kurulum notları: github.com/<kullanıcı-adın>/<depo-adı>

Veri kaynakları: AFAD Deprem Servisi ve Boğaziçi Üniversitesi Kandilli
Rasathanesi. Harita OpenStreetMap.
```

---

## 4. Paylaşmadan önce: uygulamayı çalıştır

Proje henüz bir kez bile derlenmedi. Bu iki adımı sırayla yap.

### Adım 1 — Derleme kontrolü

Finder'da proje klasörünü aç, **`kontrol.command`** dosyasına çift tıkla.

Üç şeyi sırayla çalıştırır:

1. `flutter pub get` — 8 paketin sürümleri çakışıyor mu
2. `flutter analyze` — tip ve API hataları (cihaz gerekmez, en hızlısı)
3. `flutter test` — 143 birim testi

Çıktı hem ekrana hem `kontrol-ciktisi.txt` dosyasına yazılır.
**Hata varsa o dosyanın tamamını bana yapıştır**, düzeltelim.

> İlk kırılma noktası büyük olasılıkla `pub get`. Sekiz paket var ve
> hepsinin senin Flutter sürümünle uyumlu olması gerekiyor.

### Adım 2 — Simulator'da çalıştır

Kontrol temiz çıktıktan sonra **`calistir-ios.command`** dosyasına çift tıkla.
Xcode, CocoaPods ve simulator kontrollerini kendi yapar.

İlk derleme 5–10 dakika sürebilir; sonrakiler çok daha hızlı.

---

## 5. Doğrulanmış rakamlar

Paylaşımdaki her sayı koddan sayıldı:

| İddia | Kaynak |
|-------|--------|
| 46 Dart dosyası | `lib/` + `test/` altındaki `.dart` dosyaları |
| ~12.400 satır | 12.441 satır (yorumlar dahil) |
| 143 test | `test/` klasöründeki `test(` çağrıları |
| 120 sn / 50 km toleransı | `deprem_servisi.dart` → `ayniDepremZamanToleransi`, `ayniDepremMesafeKm` |
| Allen, Wald & Worden (2012) | `siddet_hesabi.dart` — katsayılar OpenQuake `AllenEtAl2012Rhypo`'dan |
| Cihazda saklama | `shared_preferences`; kodda hiçbir yere veri gönderen çağrı yok |

**Test sayısı hakkında bir uyarı:** 143 test yazıldı ama henüz hiçbiri
çalıştırılmadı. `flutter test` geçtikten sonra bu sayıyı gönül rahatlığıyla
paylaşabilirsin — o zamana kadar "143 test yazdım" demek teknik olarak
doğru ama "143 test geçiyor" demek değil.
