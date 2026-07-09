# Vın Vın → TestFlight (Mac YOK, Windows'tan)

Sen Windows'tasın ve Mac'in yok. iOS derlemesi Mac/Xcode ister, o yüzden
**bulut macOS CI = Codemagic** kullanacağız. GitHub'a push edeceksin, Codemagic
derleyip IPA'yı **otomatik TestFlight'a** yükleyecek. Tek makine gerekmez.

Depoda hazır: `codemagic.yaml` (CI tarifi), bundle id `com.omercoskun.vinvin`,
yatay mod, AdMob (şimdilik TEST reklamları).

---

## 0) Şart: Apple Developer Program ($99/yıl)
Bunsuz TestFlight olmaz. https://developer.apple.com/programs → **Enroll**.
Onay birkaç saat–gün sürebilir. (Bir Apple ID yeterli; Mac gerekmez.)

## 1) Projeyi GitHub'a at
GitHub'da boş bir repo aç (örn. `vinvin`), sonra `Desktop/vinvin` içinde:

```bash
git init
git add .
git commit -m "Vın Vın ilk sürüm"
git branch -M main
git remote add origin https://github.com/KULLANICI/vinvin.git
git push -u origin main
```

## 2) App Store Connect'te uygulama kaydı
1. https://developer.apple.com/account → **Certificates, IDs & Profiles** →
   **Identifiers** → **+** → App IDs → App → Bundle ID **Explicit**:
   `com.omercoskun.vinvin`. Kaydet.
2. https://appstoreconnect.apple.com → **Apps** → **+** → **New App**:
   - Platform: iOS
   - İsim: **Vın Vın** (App Store'da benzersiz olmalı; doluysa "Vın Vın Yarış" vb.)
   - Bundle ID: az önce oluşturduğun `com.omercoskun.vinvin`
   - SKU: `vinvin` (serbest metin)
   Oluştur. (Şimdilik App Store bilgilerini doldurman gerekmez, TestFlight için yeter.)

## 3) App Store Connect API anahtarı (imzalamayı otomatikleştirir)
App Store Connect → **Users and Access** → **Integrations** (veya "Keys") →
**App Store Connect API** → **+**:
- Ad: `Codemagic`
- Rol: **App Manager**
- **Generate** → `.p8` dosyasını indir (bir kez indirilir, sakla).
- Not al: **Issuer ID** (sayfanın üstünde) ve **Key ID**.

## 4) Codemagic kurulumu
1. https://codemagic.io → GitHub ile giriş yap (ücretsiz plan başlar).
2. **Add application** → GitHub → `vinvin` reposunu seç → Flutter App.
3. Sol menü **Teams / Integrations → App Store Connect → Add key**:
   - **Reference name:** `VinVinASCKey`  ← `codemagic.yaml`'daki isimle AYNI olmalı
   - Issuer ID, Key ID ve `.p8` dosyasını gir. Kaydet.
4. `codemagic.yaml` repoda olduğu için Codemagic onu otomatik kullanır.

## 5) Derle ve yolla
Codemagic'te uygulamada **Start new build** → workflow `Vın Vın iOS → TestFlight`
→ **Start**. ~10–15 dk sürer. Biterse IPA otomatik TestFlight'a yüklenir.
(İlk kez imzalama sertifikası/profili API anahtarıyla otomatik oluşturulur.)

Alternatif: her `git push`'ta otomatik derleme istersen Codemagic'te
**triggering → on push** açarsın.

## 6) TestFlight'ta test et
1. App Store Connect → uygulaman → **TestFlight** sekmesi.
2. İlk yüklemede Apple "Export Compliance" sorar → şifreleme kullanmıyorsan
   **No** de (hızlı geçer).
3. **Internal Testing** → grup oluştur → kendini (App Store Connect kullanıcısı)
   ekle. Dakikalar içinde işleme alınır.
4. iPhone'una **TestFlight** uygulamasını App Store'dan kur, aynı Apple ID ile
   gir, Vın Vın'i yükle. 🎉

---

## Notlar
- **Reklamlar şu an TEST modunda** (Google test kimlikleri) — TestFlight'ta
  "Test Ad" yazan reklamlar görürsün, bu normal. Gerçek gelir için:
  AdMob'da (https://admob.google.com) uygulama + reklam birimleri aç, sonra şu
  4 yerdeki kimlikleri değiştir:
  - `lib/ad_service_mobile.dart` (interstitial)
  - `lib/ad_banner_mobile.dart` (banner)
  - `ios/Runner/Info.plist` → `GADApplicationIdentifier`
  - `android/app/src/main/AndroidManifest.xml` → `APPLICATION_ID`
- **Uygulama ikonu** şu an varsayılan Flutter ikonu. İstersen `flutter_launcher_icons`
  ile özel ikon koyarız.
- **Sürüm:** `codemagic.yaml` build numarasını `date +%s` ile otomatik artırır;
  sürüm adını (`1.0.0`) yeni sürümde elle güncelle.
- **Android/Google Play** de istersen aynı Codemagic ile yapılır; söyle, workflow
  eklerim.
