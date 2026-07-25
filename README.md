# 📄 Belge Asistanı

Kendi belgelerine (PDF, TXT, MD) doğal dille soru sorabildiğin bir yapay zeka arama aracı. Cevaplar **sadece yüklediğin belgelerden** üretilir ve her cevabın hangi dosyanın hangi sayfasından geldiği gösterilir.

Kullanılan yöntem: **RAG (Retrieval-Augmented Generation)**.

---

## Ne İşe Yarar?

Normal bir yapay zeka sohbet aracına kendi ders notlarını, şirket dokümanlarını veya raporlarını soramazsın — çünkü onları bilmez. Bu araç şunu yapar:

1. Belgelerini küçük parçalara böler
2. Her parçayı, anlamını temsil eden bir sayı vektörüne çevirir (*embedding*)
3. Soru sorduğunda soruyu da vektöre çevirip **anlamca en yakın** parçaları bulur
4. Bulunan parçaları yapay zekaya verip cevabı yazdırır
5. Cevabın altında kaynakları listeler

Kelime araması (Ctrl+F) yerine **anlam araması** yapar: "maliyeti nasıl düşürürüz" diye sorduğunda, belgede "gider optimizasyonu" yazıyorsa yine de bulur.

---

## Ekran

```
┌─────────────────┬──────────────────────────────────────────┐
│  Belgeler       │  📄 Belge Asistanı                       │
│                 │                                          │
│  [Dosya yükle]  │  👤 Bütçe raporunda en büyük gider ne?  │
│                 │                                          │
│  • rapor.pdf    │  🤖 En büyük gider kalemi personel       │
│  • notlar.md    │     giderleri, toplam bütçenin %43'ü [1] │
│                 │                                          │
│  [İndeksle]     │     ▸ Kaynaklar                          │
│                 │       [1] rapor.pdf — sayfa 12           │
│  Parça: 248     │                                          │
└─────────────────┴──────────────────────────────────────────┘
```

---

## Kurulum

### 1. Gereksinimler

- Python 3.10 veya üzeri
- Bir OpenAI **veya** Anthropic API anahtarı

### 2. Adımlar

```bash
# Proje klasörüne gir
cd belge-asistani

# Sanal ortam oluştur ve etkinleştir
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# Kütüphaneleri kur
pip install -r requirements.txt

# Ayar dosyasını oluştur
cp .env.example .env              # Windows: copy .env.example .env
```

### 3. API anahtarını gir

`.env` dosyasını bir metin editörüyle aç ve anahtarını yaz:

```
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-...
EMBEDDING_MODE=openai
```

> **Anahtar nereden alınır?**
> OpenAI: platform.openai.com → API keys
> Anthropic: console.anthropic.com → API keys
>
> **Maliyet:** Birkaç yüz sayfalık belge ve normal kullanım için aylık birkaç sentten fazla tutmaz.

### 4. Çalıştır

```bash
streamlit run app.py
```

Tarayıcıda `http://localhost:8501` açılır.

---

## Kullanım

1. Sol taraftan PDF/TXT/MD dosyalarını yükle
2. **İndeksle** butonuna bas (ilk seferde biraz sürer)
3. Alttaki kutuya sorunu yaz

Yeni belge eklediğinde tekrar **İndeksle**'ye bas — sadece yeni parçalar işlenir, baştan başlamaz.

---

## API Anahtarı Olmadan Çalıştırma

İnternet ya da API anahtarı kullanmadan da embedding üretebilirsin (cevap üretmek için yine LLM gerekir):

```bash
pip install sentence-transformers
```

`.env` dosyasında:

```
EMBEDDING_MODE=local
```

İlk çalıştırmada model indirilir (~120 MB). Kullanılan model çok dillidir, Türkçe belgelerde İngilizce-only modellerden daha iyi sonuç verir.

---

## Proje Yapısı

```
belge-asistani/
├── rag.py            # Çekirdek: okuma, parçalama, embedding, arama, cevap üretme
├── app.py            # Streamlit web arayüzü
├── belgeler/         # Yüklediğin belgeler buraya kaydedilir
├── chroma_db/        # Vektör veritabanı (otomatik oluşur)
├── requirements.txt
├── .env.example
└── README.md
```

`rag.py` tek başına da çalışır — arayüz olmadan terminalden test etmek için:

```bash
python rag.py
```

---

## Nasıl Çalışıyor? (Teknik Özet)

| Adım | Ne oluyor | Kullanılan araç |
|---|---|---|
| 1. Okuma | PDF sayfa sayfa metne çevrilir | `pypdf` |
| 2. Parçalama | Metin ~350 kelimelik, 50 kelime örtüşen parçalara bölünür | Saf Python |
| 3. Embedding | Her parça 1536 boyutlu bir vektöre çevrilir | `text-embedding-3-small` |
| 4. Saklama | Vektörler metadata ile birlikte diske yazılır | ChromaDB |
| 5. Arama | Soru vektörüne kosinüs benzerliğiyle en yakın 5 parça bulunur | ChromaDB |
| 6. Cevap | Parçalar prompt'a konur, model kaynak göstererek cevaplar | `gpt-4o-mini` |

### Tasarım kararları

**Neden parçalara bölüyoruz?** Bir modele 500 sayfa gönderemezsin — hem sığmaz, hem pahalı, hem de alakasız bilgi doğruluğu düşürür. Sadece ilgili parçaları göndermek daha ucuz ve daha isabetli.

**Neden örtüşme (overlap) var?** Bir cümle tam parça sınırına denk gelirse ikiye bölünür ve anlamı kaybolur. Parçaları 50 kelime üst üste bindirerek bu riski azaltıyoruz.

**Neden kaynak gösteriyoruz?** RAG'i sıradan bir sohbet botundan ayıran temel özellik bu. Kullanıcı cevabı doğrulayabilmeli; model uydurma yaptığında fark edilebilmeli.

**Uydurmayı (halüsinasyon) nasıl engelliyoruz?** Sistem talimatında modele açıkça "sadece verilen parçaları kullan, bulamazsan bulamadım de" deniyor.

---

## Bilinen Sınırlar

- Taranmış (görüntü tabanlı) PDF'lerden metin çıkarılamaz — OCR gerekir
- Tablolar düz metne çevrilirken yapısını kaybedebilir
- Anlam araması özel isim ve kod parçalarında kelime aramasından zayıf olabilir (çözümü *hybrid search*)
- Sohbet geçmişi takip sorularında kullanılmıyor ("peki onun maliyeti?" gibi sorular çalışmaz)

## Geliştirilebilecek Yönler

- **Hybrid search:** Anlam araması + kelime araması (BM25) birleştirilerek isabet artırılabilir
- **Reranking:** 20 aday getirip bir reranker modelle en iyi 5'i seçmek genelde en büyük kalite sıçramasını verir
- **Değerlendirme seti:** 30-50 soru-cevap çiftiyle sistemin doğruluğunu ölçmek
- **Takip soruları:** Sohbet geçmişine bakarak soruyu yeniden yazmak
- Web sayfası, Notion, YouTube transkripti gibi ek kaynaklar
