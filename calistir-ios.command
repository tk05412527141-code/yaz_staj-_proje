#!/bin/bash
# Deprem Takip - iOS Simulator'de calistirma (macOS)
# Bu dosyaya cift tiklayarak uygulamayi baslatabilirsin.
#
# Script gerekli kontrolleri yapar, eksikleri soyler ve
# her sey hazirsa uygulamayi iOS simulatorunde acar.

cd "$(dirname "$0")" || exit 1

echo "=================================================="
echo "   Deprem Takip - iOS Simulator"
echo "=================================================="
echo

hata_ile_cik() {
    echo
    echo "!!! $1"
    echo
    read -r -p "Cikmak icin Enter'a bas..."
    exit 1
}

# --------------------------------------------------------------
# 1) Flutter kurulu mu?
# --------------------------------------------------------------
echo "[1/6] Flutter kontrol ediliyor..."
if ! command -v flutter >/dev/null 2>&1; then
    echo
    echo "Flutter bulunamadi. Kurmak icin:"
    echo "    brew install --cask flutter"
    echo
    echo "Homebrew de yoksa once:"
    echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    hata_ile_cik "Flutter kurulumundan sonra bu dosyaya tekrar cift tikla."
fi
echo "      $(flutter --version 2>/dev/null | head -1)"

# --------------------------------------------------------------
# 2) Xcode kurulu mu?
# --------------------------------------------------------------
echo "[2/6] Xcode kontrol ediliyor..."
if ! xcode-select -p >/dev/null 2>&1; then
    echo
    echo "Xcode komut satiri araclari bulunamadi. Kurmak icin:"
    echo "    xcode-select --install"
    hata_ile_cik "Xcode'u App Store'dan kurup en az bir kez actigindan emin ol."
fi

# Xcode'un tam surumu mu, yoksa sadece komut satiri araclari mi?
if [[ "$(xcode-select -p)" == *"CommandLineTools"* ]]; then
    echo
    echo "Sadece komut satiri araclari kurulu; iOS simulatoru icin"
    echo "Xcode'un tamami gerekiyor."
    echo
    echo "  1. App Store'dan Xcode'u kur (buyuk indirme, ~10 GB)"
    echo "  2. Xcode'u bir kez ac ve lisansi kabul et"
    echo "  3. Sonra su komutlari calistir:"
    echo "       sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo "       sudo xcodebuild -runFirstLaunch"
    hata_ile_cik "Xcode kurulumundan sonra tekrar dene."
fi
echo "      $(xcodebuild -version 2>/dev/null | head -1)"

# --------------------------------------------------------------
# 3) CocoaPods kurulu mu? (iOS paketleri icin gerekli)
# --------------------------------------------------------------
echo "[3/6] CocoaPods kontrol ediliyor..."
if ! command -v pod >/dev/null 2>&1; then
    echo
    echo "CocoaPods bulunamadi. Kurmak icin:"
    echo "    brew install cocoapods"
    hata_ile_cik "CocoaPods kurulumundan sonra tekrar dene."
fi
echo "      CocoaPods $(pod --version 2>/dev/null)"

# --------------------------------------------------------------
# 4) Platform klasorlerini olustur
# --------------------------------------------------------------
echo "[4/6] Proje dosyalari hazirlaniyor..."
if [ ! -d "ios" ]; then
    echo "      ios/ klasoru yok, olusturuluyor..."
    # ONEMLI: klasor adinda Turkce karakter var (yaz_stajı_proje).
    # Dart paket adlari sadece a-z, 0-9 ve _ icerebilir, bu yuzden
    # proje adini acikca veriyoruz. Aksi halde flutter create hata verir.
    flutter create --project-name deprem_takip --org com.tunakilic \
        --platforms=ios,android . || hata_ile_cik "flutter create basarisiz oldu."
else
    echo "      ios/ klasoru zaten var, atlaniyor."
fi

echo "      Paketler indiriliyor..."
flutter pub get || hata_ile_cik "flutter pub get basarisiz oldu."

# --------------------------------------------------------------
# 5) Simulatoru baslat
# --------------------------------------------------------------
echo "[5/6] iOS Simulator aciliyor..."
open -a Simulator 2>/dev/null

# Simulatorun acilmasini bekle (en fazla 60 saniye)
echo -n "      Cihazin hazir olmasi bekleniyor"
for _ in $(seq 1 30); do
    if xcrun simctl list devices 2>/dev/null | grep -q "(Booted)"; then
        echo " - hazir."
        break
    fi
    echo -n "."
    sleep 2
done
echo

if ! xcrun simctl list devices 2>/dev/null | grep -q "(Booted)"; then
    echo "Simulator acilmadi gibi gorunuyor."
    echo "Simulator uygulamasindan File > Open Simulator ile bir iPhone sec,"
    echo "sonra bu dosyaya tekrar cift tikla."
    hata_ile_cik "Calisan bir simulator bulunamadi."
fi

# --------------------------------------------------------------
# 6) Uygulamayi calistir
# --------------------------------------------------------------
echo "[6/6] Uygulama derleniyor ve baslatiliyor..."
echo
echo "      NOT: Ilk derleme 5-10 dakika surebilir, bu normaldir."
echo "      Sonraki calistirmalar cok daha hizli olacak."
echo
echo "      Calisirken kullanabilecegin kisayollar:"
echo "        r  ->  hot reload (degisikligi aninda uygular)"
echo "        R  ->  hot restart"
echo "        q  ->  cikis"
echo

flutter run -d iphone

echo
read -r -p "Kapatmak icin Enter'a bas..."
