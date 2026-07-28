# 7 Günlük Plan — Staj Demosu

Kod hazır ve test edildi. Bu bir hafta, **kodu çalıştırmak, anlamak ve gösterilebilir hale getirmek** için.

> **Neden hazır kod verdim?** Bir haftada sıfırdan yazıp hem çalıştırıp hem anlamak zor. Bunun yerine çalışan bir temelden başlayıp üstüne kendi eklemelerini yapman daha gerçekçi — ve demoda "şunu ben ekledim" diyebileceğin somut şeyler çıkar.

---

## Gün 1 — Kurulum ve İlk Çalıştırma (2-3 saat)

**Hedef: Ekranında çalışan bir şey görmek.**

1. Python 3.10+ kurulu mu kontrol et: `python --version`
2. README'deki kurulum adımlarını uygula
3. API anahtarı al ve `.env` dosyasına yaz
4. `belgeler/` klasöründe `ornek-butce-raporu.md` var — onunla test et
5. `streamlit run app.py` → İndeksle → şunu sor: *"En büyük gider kalemi nedir?"*

**Beklenen sonuç:** Personel giderleri %43 cevabı + kaynak gösterimi.

**Sık karşılaşılan hatalar**

| Hata | Sebep |
|---|---|
| `ModuleNotFoundError` | Sanal ortam etkin değil. `source venv/bin/activate` |
| `AuthenticationError` | `.env` içindeki anahtar yanlış veya boş |
| `insufficient_quota` | OpenAI hesabına bakiye yüklemen gerekiyor |
| `streamlit: command not found` | Sanal ortam etkin değil ya da kurulum eksik |

**Bugün bitmezse panik yok** — kurulum en can sıkıcı gün, sonrası rahat.

---

## Gün 2 — Kendi Belgelerinle Doldur (2 saat)

**Hedef: Demoda gerçek görünmesi.**

1. Örnek dosyayı sil, yerine **kendi belgelerini** koy — ders notların, staj yaptığın kurumun kamuya açık dokümanları, bir yönetmelik PDF'i, ne olursa
2. 5-15 belge iyi bir sayı. Az olursa demo zayıf durur, çok olursa indeksleme uzar
3. İndeksle ve 10 farklı soru sor
4. **Not tut:** Hangi sorularda iyi cevap verdi, hangilerinde kötü? Bu liste Gün 6'da lazım olacak

> ⚠️ Kurumun gizli belgelerini kullanma — veriler API'ye gidiyor. Kamuya açık dokümanları ya da kendi notlarını tercih et.

---

## Gün 3 — Kodu Anla (3-4 saat)

**Hedef: Demoda "burada ne oluyor?" sorusuna cevap verebilmek. En önemli gün bu.**

`rag.py`'yi yukarıdan aşağı oku. Her fonksiyonun başında Türkçe açıklama var. Sırasıyla:

1. `belgeleri_oku()` — PDF nasıl metne çevriliyor
2. `parcala()` — neden bölüyoruz, örtüşme (overlap) ne işe yarıyor
3. `embedding_uret()` — metin nasıl sayıya dönüyor
4. `indeksle()` — ChromaDB'ye ne yazılıyor
5. `ara()` — soru nasıl eşleştiriliyor
6. `cevapla()` — prompt nasıl kuruluyor

**Anlamayı test et:** Şu 4 soruya kendi cümlelerinle cevap yazabiliyor musun?

- Belgeyi neden parçalara bölüyoruz, tamamını modele göndersek ne olur?
- Embedding nedir, kelime aramasından farkı ne?
- Sistem uydurma (halüsinasyon) yapmasın diye ne yaptık?
- Kaynak gösterimi neden önemli?

Yazamadığın varsa bana sor — bu sorular demoda büyük ihtimalle sorulacak.

**Deneyerek öğren:** `rag.py` içindeki `CHUNK_KELIME` değerini 150 yap, veritabanını sıfırla, yeniden indeksle, aynı soruları sor. Cevaplar nasıl değişti? Sonra 800 yap, tekrar dene. Bu deney demoda anlatılacak güzel bir gözlem üretir.

---

## Gün 4 — Kendi Eklemeni Yap (3-4 saat)

**Hedef: "Bunu ben ekledim" diyebileceğin bir şey.**

Bir tane seç, hepsini yapma:

**Kolay (1-2 saat)**

- Arayüze **kaç kaynak getirileceğini** ayarlayan bir kaydırıcı (slider) ekle
- Cevabı **.txt olarak indirme** butonu
- Belgeyi **arayüzden silme** özelliği
- Renk/logo/başlık ile arayüzü kişiselleştir

**Orta (3-4 saat)**

- **Kaynak filtresi:** sadece seçilen belgede arama yap (ChromaDB `where` parametresi)
- **Sadece arama modu:** LLM'i atla, ham parçaları göster (API maliyeti sıfır, hızlı)
- **Kelime araması ekle:** basit bir metin eşleşmesi yapıp anlam aramasıyla sonuçları birleştir

**Yapılacak eklemeyi seçtiğinde bana söyle, birlikte yazalım.**

---

## Gün 5 — Test Et ve Kır (2 saat)

**Hedef: Demoda sürpriz yaşamamak.**

Bilerek zorla:

- [ ] Hiç belge yokken soru sor → düzgün mesaj veriyor mu?
- [ ] Belgede olmayan bir şey sor → "bulamadım" diyor mu, uyduruyor mu?
- [ ] Çok uzun bir PDF yükle → çöküyor mu?
- [ ] Boş soru gönder
- [ ] İnterneti kapatıp dene → hata mesajı anlaşılır mı?
- [ ] Türkçe karakterli dosya adı kullan

Bulduğun her hatayı not et. **Düzeltemediklerini README'nin "Bilinen Sınırlar" bölümüne yaz** — bu zayıflık değil, olgunluk göstergesidir. Kendi projesinin sınırlarını bilen kişi iyi izlenim bırakır.

---

## Gün 6 — Demoyu Hazırla (2-3 saat)

**Hedef: 5 dakikada anlatabilmek.**

1. **Sunum sırasını belirle:**
   - 30 sn — Problem: "Kendi belgelerime yapay zekaya soramıyorum"
   - 1 dk — Canlı demo: belge yükle, indeksle, soru sor, kaynağı göster
   - 2 dk — Nasıl çalışıyor: 6 adımlı akışı anlat (README'deki tablo)
   - 1 dk — Ne ekledim, nerede zorlandım
   - 30 sn — Sınırlar ve geliştirilebilecek yönler

2. **3-4 tane garanti çalışan soru seç** ve ezberle. Demoda doğaçlama soru sorma.

3. **Ekran görüntüsü al** — internet çökerse yedeğin olsun. README'ye de ekle.

4. **Bir kez baştan sona prova yap.** Süreyi tut.

> **Demoda en etkili an:** Kaynakları açıp "bakın, bu cevap tam olarak şu dosyanın 12. sayfasından geldi" demek. Çünkü sistemin uydurmadığını kanıtlar. Bunu mutlaka göster.

---

## Gün 7 — Toparla ve Teslim Et (2 saat)

1. **README'yi güncelle:** kendi ekran görüntün, kendi eklediğin özellik, bulduğun sınırlar
2. **Kodu temizle:** kullanılmayan satırları sil, `.env`'in `.gitignore`'da olduğunu **iki kez kontrol et**
3. **GitHub'a yükle:**
   ```bash
   git init
   git add .
   git commit -m "Belge Asistani - RAG tabanli belge arama araci"
   ```
   GitHub'da yeni repo aç ve gösterdiği komutlarla gönder
4. **Son kontrol:** Projeyi başka bir klasöre kopyalayıp README'deki adımlarla sıfırdan kurmayı dene. Çalışıyorsa hazırsın.

---

## Zaman Sıkışırsa

| Durum | Ne yap |
|---|---|
| 3 günüm kaldı | Gün 1 → Gün 3 → Gün 6. Ekleme yapma, anlamaya odaklan. |
| 1 günüm kaldı | Gün 1'i yap, örnek belgeyle demo göster, README'yi oku. |
| Kurulum hiç olmuyor | Bana hata mesajını olduğu gibi yapıştır, çözelim. |

---

## Demoda Gelebilecek Sorular

**"Bu ChatGPT'den farkı ne?"**
ChatGPT benim belgelerimi bilmiyor. Bu sistem belgelerimi arayıp modele sadece ilgili kısımları veriyor — ve cevabın kaynağını gösteriyor, böylece doğrulanabiliyor.

**"Model uydurma yaparsa?"**
Sistem talimatında "sadece verilen parçaları kullan, yoksa bulamadım de" diyoruz. Ayrıca kaynak gösterdiği için kullanıcı kontrol edebiliyor. Tamamen engellenmiş değil ama iki katmanlı koruma var.

**"Neden 350 kelimelik parçalar?"**
Çok küçük olursa bağlam kayboluyor, çok büyük olursa alakasız bilgi cevabı bulandırıyor. Farklı değerler denedim *(Gün 3'teki deneyi anlat)*.

**"Kaç belgeye kadar ölçeklenir?"**
ChromaDB bu ölçekte rahat çalışıyor. Milyonlarca parçaya çıkılırsa Qdrant veya LanceDB gibi disk tabanlı bir çözüme geçmek gerekir.

**"Ne kadar sürdü / ne kadar zorlandı?"**
Dürüst ol. "Hazır bir RAG örneğinden başladım, çalıştırdım, anladım ve şunları ekledim" demek tamamen meşru — asıl değerlendirilen ne kadar anladığın.
