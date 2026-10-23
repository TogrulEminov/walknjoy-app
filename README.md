# WalkNJoy iOS

[![iOS CI](https://github.com/TogrulEminov/walknjoy-app/actions/workflows/ios-ci.yml/badge.svg?branch=develop)](https://github.com/TogrulEminov/walknjoy-app/actions/workflows/ios-ci.yml)

WalkNJoy Azərbaycanda qalmaq, tur, fəaliyyət və təcrübə xidmətlərini tapmaq, rezervasiya etmək üçün SwiftUI tətbiqidir. Layihə [TogrulEminov/walknjoy-app](https://github.com/TogrulEminov/walknjoy-app) şəxsi reposunda saxlanılır.

## Ekran görüntüləri

Təmiz iPhone 17 Pro simulator-unda çəkilmiş giriş ekranları. Screenshot-larda istifadəçi hesabı və şəxsi məlumat yoxdur.

<img src="docs/screenshots/login-light.png" alt="Giriş ekranı — açıq tema" width="270"> <img src="docs/screenshots/login-dark.png" alt="Giriş ekranı — qaranlıq tema" width="270">

## Funksionallıq

- Onboarding, dil seçimi, giriş, qeydiyyat, OTP və şifrə bərpası.
- Ana səhifə, şəhər və kateqoriyalar, axtarış, qiymət və tarix filtrləri, listing detalları.
- Stay və session booking, availability yoxlaması, booking detalları və PDF bilet.
- Rəylər, sevimlilər, bildirişlər və bildiriş seçimləri.
- Profil, avatar, təhlükəsizlik və görünüş parametrləri.
- CUSTOMER–PROVIDER mesajlaşması: söhbətlər siyahısı, cursor tarixçə, REST göndərmə, ortaq WebSocket, typing və görünən mesajların read qeydiyyatı. Listing və booking detalından söhbət açılır.
- Provider müraciəti, profil və listing idarəetməsi.
- Azərbaycan, ingilis və rus dilləri; açıq, qaranlıq və sistem teması.

Server məlumatları və autentifikasiya tələb edən funksiyalar üçün ayrıca WalkNJoy backend-i lazımdır. Backend bu repoya daxil deyil.

## Texnologiyalar və arxitektura

**SwiftUI**, **MVVM**, **Observation**, **Swift Concurrency (async/await)**, **URLSession**, **Codable**, **Decimal**, **Keychain**, **UserDefaults**, **NavigationStack**, **PhotosUI**, **MapKit** və **PDFKit** istifadə olunur.

Məlumat axını: `View → ViewModel → Service protocol → Service → NetworkingService → Endpoint`.

View-lar layout, binding və naviqasiya göstərir. ViewModel-lər sorğuları, input validation, loading/error/empty vəziyyətlərini və məlumat hazırlığını idarə edir. Service-lər protocol vasitəsilə inject edilir. Ortaq `LoadState`, `RequestState`, `PaginationController`, form validation və tema komponentləri təkrar istifadə olunur.

Adi mətn və şifrə sahələri native SwiftUI-dır. UIKit ekran arxitekturası kimi istifadə edilmir: xüsusi telefon maskası və OTP giriş koordinasiyası `UIViewRepresentable`, PDF görünüşü isə PDFKit/`UIViewRepresentable` adapteri ilə qoşulur. PDF paylaşımı native SwiftUI `ShareLink` və `Transferable` ilə edilir. `UIImage` avatar decode və cache qatında istifadə olunur.

Swift Package Manager asılılıqları: **SDWebImageSwiftUI/SDWebImage**, **SnapKit**, **InputMask** və **SwiftRichHTMLEditor**. Dəqiq versiyalar `Package.resolved` daxilində sabitlənib. SnapKit mövcud xüsusi UIKit giriş adapterləri üçündür.

```text
walknjoy/
  walknjoy.xcodeproj/          Xcode layihəsi, shared scheme və Package.resolved
  walknjoy/
    App/                      Başlanğıc, app state və navigation
    Core/
      Components/             Ortaq SwiftUI UI komponentləri
      Models/                 DTO və domain modelləri
      Networking/Endpoints/   HTTP request təsvirləri
      Services/               Protocol-lar və server inteqrasiyası
      State/                  Loading, request və pagination vəziyyətləri
      Storage/                Keychain və preferences
      UI/SwiftUIBridge/       Xüsusi native komponent adapterləri
    Features/
      Auth/ Home/ Search/ ListingDetail/ Bookings/ Reviews/
      Messages/ Notifications/ Profile/ Provider/
    Assets.xcassets/           Şəkillər və light/dark rənglər
    Localizable.xcstrings      AZ / EN / RU mətnləri
config/                       Təhlükəsiz APIConfig nümunəsi
docs/screenshots/             README ekran görüntüləri
.github/workflows/            GitHub Actions
```

## Quraşdırma və işə salma

1. **Xcode 26.4+**, **iOS 26.4+ simulator** və paketlərin ilk yüklənməsi üçün internet lazımdır.
2. Reponu klonlayın və konfiqurasiyanı hazırlayın:

```bash
git clone https://github.com/TogrulEminov/walknjoy-app.git
cd walknjoy-app
mkdir -p walknjoy/walknjoy/Core/Config
if [ ! -f walknjoy/walknjoy/Core/Config/APIConfig.swift ]; then
  cp config/APIConfig.swift.example walknjoy/walknjoy/Core/Config/APIConfig.swift
fi
open walknjoy/walknjoy.xcodeproj
```

3. `walknjoy/walknjoy/Core/Config/APIConfig.swift` daxilində `baseURL` və `imageUrl` dəyərlərini öz backend/media mühitinizə uyğunlaşdırın. Nümunədə `http://localhost:8000/api/v1` və şəkillər üçün placeholder URL var. `imageUrl` üçün real media base URL yazın.
4. Xcode-da `walknjoy` scheme-i və iOS simulator seçib Run edin. Fiziki cihaz üçün öz signing team-inizi seçin və `localhost` yerinə backend-in cihazdan əlçatan ünvanını yazın.

Yuxarıdakı əmrlər mövcud lokal konfiqurasiyanı əvəz etmir. `APIConfig.swift` Git-də izlənmir; nümunə faylı isə repoda saxlanılır. Konfiqurasiyaya server parolu, private key və ya digər server sirləri yerləşdirməyin. Yeni public konfiqurasiya sahəsi əlavə ediləndə nümunəni də yeniləyin.

## API mühiti və giriş hesabları

Layihə sahibinin təqdim etdiyi hazırkı backend və media ünvanları:

```swift
static let baseURL = "https://nqkydcwhxlbbxxgi9qexnsce.5.189.155.133.sslip.io/api/v1"
static let imageUrl = "https://pub-80a4d4523087412c8b769e1c4a3ae64c.r2.dev"
```

Bu mühitə qoşulmaq üçün həmin dəyərləri `walknjoy/walknjoy/Core/Config/APIConfig.swift` daxilində yazın. Repodakı `config/APIConfig.swift.example` lokal backend üçün nümunə olaraq qalır.

Əl ilə giriş və funksionallığın yoxlanması üçün təqdim olunmuş hesablar:

- **Customer (CUSTOMER)** — e-poçt: `cbgservices313@gmail.com`; şifrə: `Togrul12`.
- **Provider (PROVIDER)** — e-poçt: `togrul40@mail.ru`; şifrə: `Togrul12`.

Hesab məlumatlarını tətbiqin giriş ekranına daxil edin. Konfiqurasiyadakı hesab qeydləri avtomatik giriş etmir və backend-də istifadəçi yaratmır. Rol və provider təsdiq statusu backend tərəfindən müəyyən edilir; bu hesabların girişinin və təsdiq statusunun canlı yoxlanması aparılmayıb.

### Əl ilə yoxlama

1. Customer hesabı ilə daxil olun; axtarış, listing detalları, sevimlilər və rezervasiya axınını yoxlayın.
2. Hesabdan çıxın və Provider hesabı ilə daxil olun; provider profili və listing idarəetməsini yoxlayın. Müvafiq funksiyalar üçün backend-də provider təsdiqi tələb oluna bilər.
3. Mesajlaşmanı yoxlamaq üçün iki ayrı simulator və ya cihazda Customer və Provider hesablarını açın. Customer hesabından listing və ya booking detalındakı mesajlaşma keçidi ilə söhbət başladın; mesajın qarşı tərəfə çatmasını, typing və read vəziyyətlərini yoxlayın.

## Build və GitHub Actions

```bash
mkdir -p walknjoy/walknjoy/Core/Config
if [ ! -f walknjoy/walknjoy/Core/Config/APIConfig.swift ]; then
  cp config/APIConfig.swift.example walknjoy/walknjoy/Core/Config/APIConfig.swift
fi
xcodebuild build \
  -project walknjoy/walknjoy.xcodeproj \
  -scheme walknjoy \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGNING_ALLOWED=NO
```

`iOS CI` hər **push** və **pull request** zamanı avtomatik işləyir; `workflow_dispatch` ilə əl ilə də başladılır. `macos-26` üzərində Xcode 26.4.1 istifadə edərək iPhone 17 Pro simulator-unda unit testləri, həmçinin Debug və Release build-lərini yoxlayır. Test nəticələri Actions artifact-i kimi 7 gün saxlanılır. Paketlər resolved fayldakı versiyalarla yüklənir. CI nümunədən müvəqqəti API konfiqurasiyası yaradır; backend, signing sertifikatı və GitHub Secrets tələb olunmur. Runner-dəki Xcode versiyası [rəsmi runner siyahısı](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md) ilə yoxlanıla bilər.

REST və WebSocket eyni `APIConfig.baseURL` ünvanından istifadə edir (`http` → `ws`, `https` → `wss`). Lokal backend 3000 portunda işləyirsə config-də `http://localhost:3000/api/v1` yazın. Mesajlaşmanın canlı iki hesabla yoxlanması ayrıca CUSTOMER və approved PROVIDER hesabı tələb edir.

**Testlər:** shared scheme-də `walknjoyTests` unit test target-i var. Testlər mock service və network istifadə etdiyi üçün backend-ə qoşulmadan işləyir. Hazırda UI test target-i yoxdur.

## İnkişaf qaydası

Dəyişiklikləri funksional mövzuya görə kiçik, mənalı commit-lərlə saxlayın: feature, refaktor, CI düzəlişi və sənədləşmə. Mövcud commit tarixçəsi saxlanılır; tarixlər geriyə çəkilmir və saxta tarixçə yaradılmır. Feature və konfiqurasiya dəyişəndə README-nin əlaqəli bölməsini də yeniləyin.
