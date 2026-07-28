"""
app.py — Belge Asistanı'nın web arayüzü (Streamlit).

Çalıştırmak için:
    streamlit run app.py
"""

from pathlib import Path

import streamlit as st

import rag

st.set_page_config(page_title="Belge Asistanı", page_icon="📄", layout="wide")


# --------------------------------------------------------------------------
# Kenar çubuğu — belge yükleme ve indeksleme
# --------------------------------------------------------------------------

with st.sidebar:
    st.header("Belgeler")

    yuklenenler = st.file_uploader(
        "PDF, TXT veya MD yükle",
        type=["pdf", "txt", "md"],
        accept_multiple_files=True,
    )

    if yuklenenler:
        rag.BELGE_KLASORU.mkdir(parents=True, exist_ok=True)
        for dosya in yuklenenler:
            hedef = rag.BELGE_KLASORU / dosya.name
            hedef.write_bytes(dosya.getbuffer())
        st.success(f"{len(yuklenenler)} dosya kaydedildi.")

    # Klasördeki mevcut belgeleri listele
    mevcut = []
    if rag.BELGE_KLASORU.exists():
        mevcut = [
            p.name for p in sorted(rag.BELGE_KLASORU.iterdir())
            if p.is_file() and p.suffix.lower() in (".pdf", ".txt", ".md")
        ]

    if mevcut:
        st.caption(f"Klasörde {len(mevcut)} belge var:")
        for ad in mevcut:
            st.write(f"• {ad}")
    else:
        st.caption("Klasör boş. Yukarıdan belge yükle.")

    st.divider()

    if st.button("İndeksle", type="primary", use_container_width=True):
        cubuk = st.progress(0.0, text="Başlıyor...")

        def ilerleme(tamamlanan, toplam):
            cubuk.progress(tamamlanan / toplam, text=f"{tamamlanan}/{toplam} parça")

        try:
            sonuc = rag.indeksle(ilerleme=ilerleme)
            cubuk.empty()
            st.success(f"{sonuc['mesaj']} ({sonuc['eklenen']} yeni parça)")
        except Exception as e:
            cubuk.empty()
            st.error(f"Hata: {e}")
            st.caption("API anahtarını .env dosyasına doğru yazdığından emin ol.")

    if st.button("Veritabanını sıfırla", use_container_width=True):
        rag.veritabanini_sifirla()
        st.warning("Veritabanı silindi. Tekrar indekslemen gerekiyor.")

    st.divider()
    st.metric("İndekslenmiş parça", rag.istatistik())
    st.caption(f"Embedding: {rag.EMBEDDING_MODE} · LLM: {rag.LLM_PROVIDER}")


# --------------------------------------------------------------------------
# Ana ekran — soru sorma
# --------------------------------------------------------------------------

st.title("📄 Belge Asistanı")
st.caption(
    "Kendi belgelerine doğal dille soru sor. Cevaplar sadece belgelerinden üretilir "
    "ve hangi dosyanın hangi sayfasından geldiği gösterilir."
)

if rag.istatistik() == 0:
    st.info("Başlamak için soldan belge yükleyip **İndeksle**'ye bas.")

# Sohbet geçmişini oturumda sakla
if "gecmis" not in st.session_state:
    st.session_state.gecmis = []

# Önceki mesajları göster
for mesaj in st.session_state.gecmis:
    with st.chat_message(mesaj["rol"]):
        st.markdown(mesaj["icerik"])
        if mesaj.get("kaynaklar"):
            with st.expander("Kaynaklar"):
                for i, k in enumerate(mesaj["kaynaklar"], start=1):
                    st.markdown(
                        f"**[{i}] {k['kaynak']}** — sayfa {k['sayfa']} "
                        f"· benzerlik `{k['benzerlik']}`"
                    )
                    st.caption(k["metin"][:400] + ("..." if len(k["metin"]) > 400 else ""))

# Yeni soru
soru = st.chat_input("Belgelerine bir soru sor...")

if soru:
    st.session_state.gecmis.append({"rol": "user", "icerik": soru})
    with st.chat_message("user"):
        st.markdown(soru)

    with st.chat_message("assistant"):
        with st.spinner("Belgelerde aranıyor..."):
            try:
                sonuc = rag.cevapla(soru)
            except Exception as e:
                sonuc = {"cevap": f"Bir hata oluştu: {e}", "kaynaklar": []}

        st.markdown(sonuc["cevap"])

        if sonuc["kaynaklar"]:
            with st.expander("Kaynaklar"):
                for i, k in enumerate(sonuc["kaynaklar"], start=1):
                    st.markdown(
                        f"**[{i}] {k['kaynak']}** — sayfa {k['sayfa']} "
                        f"· benzerlik `{k['benzerlik']}`"
                    )
                    st.caption(k["metin"][:400] + ("..." if len(k["metin"]) > 400 else ""))

    st.session_state.gecmis.append({
        "rol": "assistant",
        "icerik": sonuc["cevap"],
        "kaynaklar": sonuc["kaynaklar"],
    })
