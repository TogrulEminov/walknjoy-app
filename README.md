# WalknJoy iOS

WalknJoy tətbiqinin SwiftUI və UIKit ilə hazırlanan iOS layihəsi.

## Hazırkı vəziyyət

- Splash, dil seçimi və onboarding ekranları.
- Giriş, qeydiyyat, OTP və şifrə bərpası ekranları.
- Azərbaycan və ingilis dili üçün lokalizasiya strukturu.
- Ortaq tema, UI komponentləri və lokal yaddaş qatı.

Layihə inkişaf mərhələsindədir. Autentifikasiya ekranlarının mövcudluğu backend inteqrasiyasının tamamlandığı anlamına gəlmir. Hazırda avtomatlaşdırılmış test target-i yoxdur.

## Tələblər

- Xcode 26.4 və ya daha yeni uyğun versiya.
- iOS 26.4+ simulator və ya cihaz.
- Swift Package Manager asılılıqlarını yükləmək üçün internet.

Asılılıqlar: **SDWebImageSwiftUI**, **SnapKit**. Dəqiq versiyalar Xcode workspace daxilindəki `xcshareddata/swiftpm/Package.resolved` faylında saxlanılır; bu faylı Git-ə əlavə edin.

## Lokal quraşdırma

Repo qovluğunda:

```bash
mkdir -p walknjoy/walknjoy/Core/Config
cp -n config/APIConfig.swift.example walknjoy/walknjoy/Core/Config/APIConfig.swift
open walknjoy/walknjoy.xcodeproj
```

`APIConfig.swift` daxilində lokal dəyərləri yazın. `cp -n` mövcud konfiqurasiyanı əvəz etmir. Xcode-da paketlərin yüklənməsini gözləyin, `walknjoy` scheme və iOS simulator seçib Run edin. Fiziki cihaz üçün öz signing team-inizi seçin.

`APIConfig.swift` Git-ə göndərilmir. Yeni konfiqurasiya sahəsi əlavə ediləndə `config/APIConfig.swift.example` faylını da təhlükəsiz nümunə dəyərlərlə yeniləyin. Server sirlərini mobil tətbiqə yerləşdirməyin.

### APIConfig.swift strukturu

Fayl yolu: `walknjoy/walknjoy/Core/Config/APIConfig.swift`.
Hazırkı struktur aşağıdadır; lokal dəyər `REDACTED` ilə gizlədilib:

```swift
import Foundation
enum APIConfig {
    static let imageUrl = "REDACTED"
}
```

`imageUrl` — şəkillər üçün URL dəyəri. Lokal faylda `REDACTED` yerinə mühitinizə uyğun URL yazın; `REDACTED` işlək URL deyil.

`APIConfig` daxilində sahə əlavə ediləndə, dəyişdiriləndə və ya silinəndə bu nümunəni və `config/APIConfig.swift.example` faylını da eyni strukturla yeniləyin. README-də real konfiqurasiya dəyərlərini həmişə `REDACTED` ilə əvəz edin.

## Struktur

```text
walknjoy/
  walknjoy.xcodeproj/   Xcode layihəsi və shared scheme
  walknjoy/
    App/               Tətbiqin başlanğıcı, vəziyyəti və naviqasiya
    Core/              Konfiqurasiya, tema, yaddaş və ortaq komponentlər
    Features/          Splash, dil seçimi, onboarding və auth ekranları
    Assets.xcassets/   Rənglər və şəkillər
    Localizable.xcstrings
config/                Git üçün təhlükəsiz konfiqurasiya nümunəsi
.github/workflows/     GitHub Actions
```

## Build və CI

```bash
xcodebuild build \
  -project walknjoy/walknjoy.xcodeproj \
  -scheme walknjoy \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGNING_ALLOWED=NO
```

`iOS CI` hər push və pull request zamanı, həmçinin Actions bölməsindən əl ilə başladılır. `macos-26` üzərində Xcode 26.4.1 ilə Debug və Release simulator build-lərini yoxlayır. Runner versiyaları [GitHub-un rəsmi siyahısına](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md) əsaslanır.

CI əvvəlcə `APIConfig.swift` faylının Git-də izlənmədiyini yoxlayır, sonra nümunədən müvəqqəti konfiqurasiya yaradır. GitHub Secrets və signing sertifikatı tələb olunmur. Test target-i əlavə ediləndə workflow-a `xcodebuild test` mərhələsi də əlavə edilməlidir. Bu workflow App Store-a yayımlama etmir.

## README-nin yenilənməsi

Hər funksional dəyişiklikdə bu README-nin uyğun bölməsini də yeniləyirik: yeni ekranlar, quraşdırma addımları, konfiqurasiya sahələri, asılılıqlar və CI dəyişiklikləri. README dəyişiklikləri əlaqəli kodla eyni commit/PR daxilində saxlanılmalıdır.

## Dəyişiklik qeydləri

### 2026-09-19

- Debug və Release build yoxlamaları üçün GitHub Actions əlavə edildi.
- Lokal API konfiqurasiyası və Xcode istifadəçi faylları üçün `.gitignore` yaradıldı.
- Təhlükəsiz API konfiqurasiya nümunəsi və shared scheme əlavə edildi.
- Quraşdırma və inkişaf qaydaları sənədləşdirildi.
