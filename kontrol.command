#!/bin/bash
# Deprem Takip - derleme kontrolu
#
# Bu dosyaya cift tikla. Uc adimi sirayla calistirir ve tum ciktiyi
# kontrol-ciktisi.txt dosyasina yazar. O dosyayi bana yapistirman yeterli.
#
#   1. flutter pub get   -> paket surumleri cozuluyor mu
#   2. flutter analyze   -> tip ve API hatalari (cihaz gerekmez, en hizlisi)
#   3. flutter test      -> 75 birim testi

cd "$(dirname "$0")" || exit 1

CIKTI="kontrol-ciktisi.txt"

# Ciktiyi hem ekrana hem dosyaya yaz
exec > >(tee "$CIKTI") 2>&1

echo "=================================================="
echo "  Deprem Takip - derleme kontrolu"
echo "  $(date '+%d.%m.%Y %H:%M')"
echo "=================================================="
echo

if ! command -v flutter >/dev/null 2>&1; then
    echo "HATA: flutter bulunamadi."
    echo "Kurmak icin: brew install --cask flutter"
    echo
    read -r -p "Cikmak icin Enter'a bas..."
    exit 1
fi

echo "--- ORTAM ---"
flutter --version
echo
dart --version 2>/dev/null
echo

echo "=================================================="
echo "  1/3  flutter pub get"
echo "=================================================="
# En olasi ilk kirilma noktasi: paket surum cakismasi
flutter pub get
PUB=$?
echo
echo ">>> pub get cikis kodu: $PUB"
echo

if [ $PUB -ne 0 ]; then
    echo "=================================================="
    echo "  pub get BASARISIZ - sonraki adimlar atlaniyor"
    echo "=================================================="
    echo
    echo "Bu genelde paket surum cakismasidir."
    echo "Yukaridaki 'Because ...' satirlarini bana yapistir."
    echo
    echo "Cikti kaydedildi: $CIKTI"
    read -r -p "Cikmak icin Enter'a bas..."
    exit 1
fi

echo "=================================================="
echo "  2/3  flutter analyze"
echo "=================================================="
# Asil is bu: cihaz acmadan tum tip/API hatalarini bulur
flutter analyze
ANA=$?
echo
echo ">>> analyze cikis kodu: $ANA  (0 = hatasiz)"
echo

echo "=================================================="
echo "  3/3  flutter test"
echo "=================================================="
flutter test
TEST=$?
echo
echo ">>> test cikis kodu: $TEST  (0 = hepsi gecti)"
echo

echo "=================================================="
echo "  OZET"
echo "=================================================="
echo "  pub get : $([ $PUB -eq 0 ] && echo 'TAMAM' || echo "HATA ($PUB)")"
echo "  analyze : $([ $ANA -eq 0 ] && echo 'TAMAM' || echo "HATA ($ANA)")"
echo "  test    : $([ $TEST -eq 0 ] && echo 'TAMAM' || echo "HATA ($TEST)")"
echo
if [ $ANA -eq 0 ] && [ $TEST -eq 0 ]; then
    echo "  Her sey temiz. Simdi calistirabilirsin:"
    echo "      ./calistir-ios.command"
    echo "  veya"
    echo "      flutter run"
else
    echo "  Hatalar var. $CIKTI dosyasinin tamamini bana yapistir."
    echo "  Dosya proje klasorunde."
fi
echo
echo "Cikti kaydedildi: $CIKTI"
echo

read -r -p "Kapatmak icin Enter'a bas..."
