"""
rag.py — Belge Asistanı'nın çekirdeği.

Buradaki akış RAG (Retrieval-Augmented Generation) denen yöntemdir:

    1. OKU      Belgeleri (PDF/TXT/MD) metne çevir
    2. PARÇALA  Metni küçük parçalara (chunk) böl
    3. GÖM      Her parçayı sayı vektörüne (embedding) çevir
    4. SAKLA    Vektörleri bir veritabanına (ChromaDB) yaz
    5. ARA      Soruyu da vektöre çevirip en yakın parçaları bul
    6. ÜRET     Bulunan parçaları LLM'e verip cevap yazdır

Neden doğrudan LLM'e sormuyoruz? Çünkü LLM senin belgelerini bilmiyor.
Bu yöntemle ona sadece ilgili parçaları veriyoruz — hem ucuz, hem doğru,
hem de cevabın hangi belgeden geldiğini gösterebiliyoruz.
"""

import os
import hashlib
from pathlib import Path

import chromadb
from dotenv import load_dotenv

load_dotenv()

# --------------------------------------------------------------------------
# Ayarlar
# --------------------------------------------------------------------------

BELGE_KLASORU = Path("belgeler")      # Belgelerin duracağı klasör
VERITABANI_YOLU = "chroma_db"          # ChromaDB'nin diske yazacağı klasör
KOLEKSIYON_ADI = "belgelerim"

CHUNK_KELIME = 350      # Her parçada kaç kelime olsun (~500 token)
CHUNK_ORTUSME = 50      # Parçalar birbirinin üzerine kaç kelime binsin

LLM_PROVIDER = os.getenv("LLM_PROVIDER", "openai").lower()
EMBEDDING_MODE = os.getenv("EMBEDDING_MODE", "openai").lower()


# --------------------------------------------------------------------------
# 1. ADIM — Belgeleri oku
# --------------------------------------------------------------------------

def pdf_oku(yol: Path) -> list[tuple[int, str]]:
    """PDF'i sayfa sayfa okur. [(sayfa_no, metin), ...] döner."""
    from pypdf import PdfReader

    okuyucu = PdfReader(str(yol))
    sayfalar = []
    for i, sayfa in enumerate(okuyucu.pages, start=1):
        metin = sayfa.extract_text() or ""
        if metin.strip():
            sayfalar.append((i, metin))
    return sayfalar


def duz_metin_oku(yol: Path) -> list[tuple[int, str]]:
    """TXT ve MD dosyalarını okur. Sayfa kavramı yok, hepsi 1. sayfa sayılır."""
    metin = yol.read_text(encoding="utf-8", errors="ignore")
    return [(1, metin)] if metin.strip() else []


def belgeleri_oku(klasor: Path = BELGE_KLASORU) -> list[dict]:
    """
    Klasördeki tüm desteklenen dosyaları okur.
    Her eleman: {"kaynak": dosya adı, "sayfa": no, "metin": ...}
    """
    if not klasor.exists():
        klasor.mkdir(parents=True, exist_ok=True)
        return []

    sonuc = []
    for yol in sorted(klasor.rglob("*")):
        if not yol.is_file():
            continue

        uzanti = yol.suffix.lower()
        try:
            if uzanti == ".pdf":
                sayfalar = pdf_oku(yol)
            elif uzanti in (".txt", ".md"):
                sayfalar = duz_metin_oku(yol)
            else:
                continue  # Desteklenmeyen dosya türü, atla
        except Exception as e:
            print(f"[UYARI] {yol.name} okunamadı: {e}")
            continue

        for sayfa_no, metin in sayfalar:
            sonuc.append({"kaynak": yol.name, "sayfa": sayfa_no, "metin": metin})

    return sonuc


# --------------------------------------------------------------------------
# 2. ADIM — Metni parçalara böl (chunking)
# --------------------------------------------------------------------------

def parcala(metin: str, boyut: int = CHUNK_KELIME, ortusme: int = CHUNK_ORTUSME) -> list[str]:
    """
    Metni kelime sayısına göre parçalara böler.

    Neden örtüşme (overlap) var?
        Bir cümle tam parça sınırına denk gelirse ikiye bölünür ve anlamı
        kaybolur. Parçaları birkaç düzine kelime üst üste bindirerek bu
        riski azaltıyoruz.

    Neden 350 kelime?
        Çok küçük olursa bağlam kaybolur, çok büyük olursa alakasız bilgi
        cevabı bulandırır. 300-500 arası çoğu belge için iyi bir başlangıç.
    """
    kelimeler = metin.split()
    if not kelimeler:
        return []

    adim = max(1, boyut - ortusme)
    parcalar = []
    for i in range(0, len(kelimeler), adim):
        parca = " ".join(kelimeler[i:i + boyut])
        if len(parca.strip()) > 40:      # Çok kısa artıkları atla
            parcalar.append(parca)
        if i + boyut >= len(kelimeler):
            break
    return parcalar


def chunklari_hazirla(klasor: Path = BELGE_KLASORU) -> list[dict]:
    """Belgeleri okur ve hepsini parçalara böler."""
    chunklar = []
    for belge in belgeleri_oku(klasor):
        for sira, parca in enumerate(parcala(belge["metin"])):
            # Aynı içeriğin iki kez eklenmemesi için içerikten kimlik üretiyoruz
            kimlik = hashlib.md5(
                f"{belge['kaynak']}|{belge['sayfa']}|{sira}|{parca[:100]}".encode()
            ).hexdigest()

            chunklar.append({
                "id": kimlik,
                "metin": parca,
                "kaynak": belge["kaynak"],
                "sayfa": belge["sayfa"],
                "sira": sira,
            })
    return chunklar


# --------------------------------------------------------------------------
# 3. ADIM — Embedding (metni vektöre çevirme)
# --------------------------------------------------------------------------
# Embedding, bir metni anlamını temsil eden sayı listesine çevirir.
# Anlamca benzer metinler, bu sayı uzayında birbirine YAKIN olur.
# Bu yüzden "maliyet nasıl düşer" sorusu, "gider optimizasyonu" yazan bir
# paragrafı bulabilir — kelimeler farklı olsa bile.

_yerel_model = None


def embedding_uret(metinler: list[str]) -> list[list[float]]:
    """Metin listesini vektör listesine çevirir."""
    if EMBEDDING_MODE == "local":
        global _yerel_model
        from sentence_transformers import SentenceTransformer

        if _yerel_model is None:
            # Çok dilli model — Türkçe belgelerde İngilizce-only modellerden iyi
            _yerel_model = SentenceTransformer(
                "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
            )
        return _yerel_model.encode(metinler, show_progress_bar=False).tolist()

    # Varsayılan: OpenAI
    from openai import OpenAI

    istemci = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    cevap = istemci.embeddings.create(
        model="text-embedding-3-small",
        input=metinler,
    )
    return [d.embedding for d in cevap.data]


# --------------------------------------------------------------------------
# 4. ADIM — Vektör veritabanı (ChromaDB)
# --------------------------------------------------------------------------

def koleksiyon_al():
    """ChromaDB koleksiyonunu açar (yoksa oluşturur). Veriler diske yazılır."""
    istemci = chromadb.PersistentClient(path=VERITABANI_YOLU)
    return istemci.get_or_create_collection(
        name=KOLEKSIYON_ADI,
        metadata={"hnsw:space": "cosine"},   # Benzerlik ölçüsü: kosinüs
    )


def indeksle(ilerleme=None) -> dict:
    """
    Belgeleri okur, parçalar, vektöre çevirir ve veritabanına yazar.

    ilerleme: isteğe bağlı fonksiyon — arayüzde durum göstermek için
              ilerleme(tamamlanan, toplam) şeklinde çağrılır.
    """
    chunklar = chunklari_hazirla()
    if not chunklar:
        return {"eklenen": 0, "toplam": 0, "mesaj": "Klasörde okunabilir belge bulunamadı."}

    koleksiyon = koleksiyon_al()

    # Zaten indekslenmiş parçaları atla (aynı dosyayı iki kez işlememek için)
    mevcut = set(koleksiyon.get(include=[])["ids"])
    yeni = [c for c in chunklar if c["id"] not in mevcut]

    if not yeni:
        return {"eklenen": 0, "toplam": len(chunklar), "mesaj": "Her şey zaten güncel."}

    # Embedding API'sini tek tek değil, gruplar halinde çağırıyoruz — çok daha hızlı
    GRUP = 64
    for i in range(0, len(yeni), GRUP):
        grup = yeni[i:i + GRUP]
        vektorler = embedding_uret([c["metin"] for c in grup])

        koleksiyon.add(
            ids=[c["id"] for c in grup],
            embeddings=vektorler,
            documents=[c["metin"] for c in grup],
            metadatas=[
                {"kaynak": c["kaynak"], "sayfa": c["sayfa"], "sira": c["sira"]}
                for c in grup
            ],
        )
        if ilerleme:
            ilerleme(min(i + GRUP, len(yeni)), len(yeni))

    return {"eklenen": len(yeni), "toplam": len(chunklar), "mesaj": "İndeksleme tamamlandı."}


def veritabanini_sifirla():
    """Koleksiyonu siler. Baştan indekslemek istersen kullan."""
    istemci = chromadb.PersistentClient(path=VERITABANI_YOLU)
    try:
        istemci.delete_collection(KOLEKSIYON_ADI)
    except Exception:
        pass


def istatistik() -> int:
    """Veritabanında kaç parça var?"""
    try:
        return koleksiyon_al().count()
    except Exception:
        return 0


# --------------------------------------------------------------------------
# 5. ADIM — Arama
# --------------------------------------------------------------------------

def ara(soru: str, adet: int = 5) -> list[dict]:
    """Soruya en yakın parçaları getirir."""
    koleksiyon = koleksiyon_al()
    if koleksiyon.count() == 0:
        return []

    soru_vektoru = embedding_uret([soru])[0]
    sonuc = koleksiyon.query(
        query_embeddings=[soru_vektoru],
        n_results=min(adet, koleksiyon.count()),
    )

    bulunanlar = []
    for metin, meta, mesafe in zip(
        sonuc["documents"][0], sonuc["metadatas"][0], sonuc["distances"][0]
    ):
        bulunanlar.append({
            "metin": metin,
            "kaynak": meta["kaynak"],
            "sayfa": meta["sayfa"],
            # Kosinüs mesafesi 0 = birebir aynı. Benzerliğe çevirip okunur yapıyoruz.
            "benzerlik": round(1 - mesafe, 3),
        })
    return bulunanlar


# --------------------------------------------------------------------------
# 6. ADIM — Cevap üretme
# --------------------------------------------------------------------------

SISTEM_TALIMATI = """Sen bir belge asistanısın.

Kurallar:
- SADECE sana verilen belge parçalarını kullanarak cevap ver.
- Cevap parçalarda yoksa "Belgelerde bu bilgiyi bulamadım." de. Tahmin yürütme.
- Cevabını Türkçe ve kısa tut.
- Kullandığın her bilginin sonuna kaynağını [1], [2] şeklinde ekle.
"""


def _baglam_olustur(parcalar: list[dict]) -> str:
    """Bulunan parçaları LLM'e verilecek düzenli bir metne çevirir."""
    satirlar = []
    for i, p in enumerate(parcalar, start=1):
        satirlar.append(f"[{i}] ({p['kaynak']}, sayfa {p['sayfa']})\n{p['metin']}")
    return "\n\n---\n\n".join(satirlar)


def cevapla(soru: str, adet: int = 5) -> dict:
    """
    Tam RAG akışı: ara → bağlamı hazırla → LLM'e sor → cevabı ve kaynakları dön.
    """
    parcalar = ara(soru, adet)
    if not parcalar:
        return {
            "cevap": "Henüz indekslenmiş belge yok. Önce belge ekleyip indeksle.",
            "kaynaklar": [],
        }

    kullanici_mesaji = (
        f"Belge parçaları:\n\n{_baglam_olustur(parcalar)}\n\n"
        f"Soru: {soru}"
    )

    if LLM_PROVIDER == "anthropic":
        import anthropic

        istemci = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
        yanit = istemci.messages.create(
            model="claude-sonnet-4-5",
            max_tokens=1000,
            system=SISTEM_TALIMATI,
            messages=[{"role": "user", "content": kullanici_mesaji}],
        )
        cevap_metni = yanit.content[0].text
    else:
        from openai import OpenAI

        istemci = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        yanit = istemci.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": SISTEM_TALIMATI},
                {"role": "user", "content": kullanici_mesaji},
            ],
        )
        cevap_metni = yanit.choices[0].message.content

    return {"cevap": cevap_metni, "kaynaklar": parcalar}


# --------------------------------------------------------------------------
# Terminalden test etmek için: python rag.py
# --------------------------------------------------------------------------

if __name__ == "__main__":
    print("Belgeler indeksleniyor...")
    print(indeksle(ilerleme=lambda a, t: print(f"  {a}/{t}")))
    print(f"Veritabanındaki parça sayısı: {istatistik()}\n")

    while True:
        soru = input("Soru (çıkmak için boş bırak): ").strip()
        if not soru:
            break
        sonuc = cevapla(soru)
        print("\n" + sonuc["cevap"] + "\n")
        for i, k in enumerate(sonuc["kaynaklar"], start=1):
            print(f"  [{i}] {k['kaynak']} — sayfa {k['sayfa']} (benzerlik {k['benzerlik']})")
        print()
