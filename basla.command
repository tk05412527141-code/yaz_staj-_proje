#!/bin/bash
# Belge Asistani - tek tikla baslatma (macOS)
# Bu dosyaya cift tiklayarak uygulamayi calistirabilirsin.

cd "$(dirname "$0")" || exit 1

echo "=============================================="
echo "  Belge Asistani baslatiliyor..."
echo "=============================================="
echo

# 1) Python var mi?
if ! command -v python3 >/dev/null 2>&1; then
    echo "HATA: Python bulunamadi."
    echo "python.org/downloads adresinden Python 3.10+ kur, sonra tekrar dene."
    read -r -p "Cikmak icin Enter'a bas..."
    exit 1
fi

# 2) Sanal ortam yoksa olustur
if [ ! -d "venv" ]; then
    echo "[1/3] Sanal ortam olusturuluyor (ilk calistirmada bir kez)..."
    python3 -m venv venv || { echo "HATA: sanal ortam olusturulamadi."; read -r; exit 1; }
else
    echo "[1/3] Sanal ortam zaten var, atlaniyor."
fi

source venv/bin/activate

# 3) Kutuphaneler kurulu mu?
if ! python -c "import streamlit" >/dev/null 2>&1; then
    echo "[2/3] Kutuphaneler kuruluyor (birkac dakika surebilir)..."
    pip install --quiet --upgrade pip
    pip install --quiet -r requirements.txt || { echo "HATA: kurulum basarisiz."; read -r; exit 1; }
else
    echo "[2/3] Kutuphaneler zaten kurulu, atlaniyor."
fi

# 4) .env dosyasi var mi?
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo
    echo "=============================================="
    echo "  .env dosyasi olusturuldu."
    echo
    echo "  Simdi .env dosyasini bir metin editoruyle ac"
    echo "  ve OPENAI_API_KEY satirina anahtarini yaz."
    echo "  Sonra bu dosyaya tekrar cift tikla."
    echo "=============================================="
    open -e .env 2>/dev/null
    read -r -p "Cikmak icin Enter'a bas..."
    exit 0
fi

# 5) Anahtar doldurulmus mu?
if grep -q "buraya-anahtarini-yaz" .env; then
    echo
    echo "UYARI: .env dosyasinda API anahtari hala doldurulmamis."
    echo "Dosyayi acip anahtarini yaz, sonra tekrar dene."
    open -e .env 2>/dev/null
    read -r -p "Cikmak icin Enter'a bas..."
    exit 1
fi

echo "[3/3] Uygulama aciliyor: http://localhost:8501"
echo
echo "Durdurmak icin bu pencerede Ctrl+C'ye bas."
echo

streamlit run app.py
