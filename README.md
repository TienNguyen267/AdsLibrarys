# AdmobLibrary

SwiftUI ad helpers for AdMob (banner, native, interstitial, rewarded, app open), Firebase Remote Config, mediation adapters, and an in-app rating dialog.

This repository is **private** and holds the Swift source. Apps install a **binary** build from the public repo [AdmobLibraryBinary](https://github.com/TienNguyen267/AdmobLibraryBinary). They do not receive source files.

## Requirements

- iOS 15.0+
- Swift 6.0
- CocoaPods

## Install (app projects)

```ruby
pod 'AdmobLibrary', '1.0.7'
```

Then:

```bash
pod install
```

Use CocoaPods trunk. From `1.0.6` onward, the pod downloads only the xcframework and resources from the public binary repo.

Do not pin versions `1.0.0`–`1.0.5`. Those specs still point at the private source repo and will fail for other developers.

Import trong code:

```swift
import AdmobLibrary
```

## Cách dùng

### 1. Khởi tạo khi mở app (Splash)

Luồng khuyến nghị: Remote Config → Tenjin / SolarEngine → Debug flag → UMP consent → Google Mobile Ads → hiện splash ads.

```swift
import SwiftUI
import AdmobLibrary

struct SplashView: View {
    @State private var goNext = false
    @State private var consentReady = false
    private let consentManager = GoogleMobileAdsConsentManager.shared

    var body: some View {
        if goNext {
            ContentView()
        } else {
            VStack {
                Spacer()
                if consentReady {
                    adsSplashView {
                        goNext = true
                    }
                }
            }
            .onAppear { bootstrap() }
        }
    }

    private func bootstrap() {
        let defaults: [String: NSObject] = [
            "isDebug": "0" as NSObject,
            "checkTestAds": "0" as NSObject,
            "autoCheckDebug": "1" as NSObject,
            "ADS_HOME": "1" as NSObject,
            "INTER_HOME": "1" as NSObject,
        ]

        RemoteConfigManager.shared.initRemoteConfig(defaults: defaults) {
            Common.checkTestAds =
                RemoteConfigManager.shared.getValue(forKey: "checkTestAds") == "1"

            let isDebugFirebase =
                RemoteConfigManager.shared.getValue(forKey: "isDebug") == "1"
            let autoCheckDebug =
                RemoteConfigManager.shared.getValue(forKey: "autoCheckDebug") == "1"

            TenjinManager.shared.initialize(sdkKey: "YOUR_TENJIN_KEY")
            SolarEngineManager.shared.setupSolarEngine(key: "YOUR_SOLAR_ENGINE_KEY")

            DebugModeManager.shared.configureDebugFlag(rcValue: isDebugFirebase) { isDebug in
                Common.isDebug = autoCheckDebug ? isDebug : isDebugFirebase
                requestConsent()
            }
        }
    }

    private func requestConsent() {
        Task { @MainActor in
            consentManager.gatherConsent { error in
                if consentManager.canRequestAds {
                    consentManager.startGoogleMobileAdsSDK()
                    consentReady = true
                } else {
                    // User từ chối consent: bỏ qua ads hoặc vẫn đi tiếp màn hình.
                    goNext = true
                }
                _ = error
            }
        }
    }
}
```

`adsSplashView` đọc Remote Config key `ADS_SPLASH` (JSON `SplashConfig`). Sau khi đóng splash ads, callback `onAdDismiss` chạy.

### 2. Cờ dùng chung (`Common`)

| Flag | Ý nghĩa |
| --- | --- |
| `Common.isPurchase` | `true` → mọi ads helper trả về empty / gọi dismiss ngay |
| `Common.isOrganic` | `true` + config `organic: true` → bỏ qua ads đó |
| `Common.checkTestAds` | Dùng test ad unit khi bật |
| `Common.isDebug` | Debug mode nội bộ |
| `AdsManager.shared.isShowingAd` | Đang hiện full-screen ad |

Sau IAP:

```swift
Common.isPurchase = true
```

### 3. Banner / Native theo Remote Config

#### Banner hoặc native chân màn hình

```swift
adsBannerNativeView(
    configKey: "ADS_HOME",
    isClose: false,
    onAdLoaded: { print("loaded") },
    onAdFailedToLoad: { error in print(error) }
)
```

JSON Remote Config mẫu (`BannerNativeConfig`):

```json
{
  "ads_type": "1",
  "native_type": "1",
  "organic": false,
  "units": {
    "banner": "ca-app-pub-xxx/banner",
    "banner_collap": "ca-app-pub-xxx/banner-collap",
    "native": "ca-app-pub-xxx/native",
    "banner_reload": "ca-app-pub-xxx/banner"
  }
}
```

`ads_type`:

| Giá trị | Loại |
| --- | --- |
| `"1"` | Banner thường |
| `"2"` | Banner collapsible |
| `"3"` | Native (xem `native_type`) |

`native_type` khi `ads_type = "3"`:

| Giá trị | Loại |
| --- | --- |
| `"1"` | Native medium |
| `"2"` | Native small play |
| `"3"` | Native small banner |
| `"4"` | Native collapsible (`isClose: true` → có nút đóng) |

#### Native theo config riêng

```swift
nativeView(
    configKey: "NATIVE_HOME",
    onAdLoaded: { },
    onAdFailedToLoad: { _ in }
)
```

JSON (`NativePreloadConfig`):

```json
{
  "type": "1",
  "organic": false,
  "units": {
    "native": "ca-app-pub-xxx/native"
  }
}
```

`type` dùng cùng bảng `native_type` ở trên.

### 4. Interstitial theo Remote Config

```swift
loadAndShowInter(configKey: "INTER_HOME") {
    // User đã đóng ad, hoặc ad bị skip (purchase / organic / frequency)
    navigateNext()
}
```

JSON (`InterConfig`):

```json
{
  "type": "1",
  "count": "0",
  "organic": false,
  "units": {
    "inter": "ca-app-pub-xxx/inter",
    "native": "ca-app-pub-xxx/native-fullscreen"
  }
}
```

`count` là frequency cap trong bộ nhớ: lần đầu hiện ngay, sau đó cách `count` lần mới hiện lại. Kill app thì reset.

### 5. Gọi ad trực tiếp bằng ad unit (không qua Remote Config)

Google test units dùng được khi phát triển.

#### Banner

```swift
BannerAdViewWithShimmer(
    adUnitID: "ca-app-pub-3940256099942544/8388050270",
    onAdLoaded: { },
    onAdFailedToLoad: { _ in }
)

BannerCollapsibleAdView(
    adUnitID: "ca-app-pub-3940256099942544/8388050270",
    onAdLoaded: { },
    onAdFailedToLoad: { _ in }
)
```

#### Native

```swift
NativeAdContainer(adUnitID: unit, onAdLoaded: { _ in }, onAdFailedToLoad: { _ in })
NativeSmallPlayAdContainer(adUnitID: unit, onAdLoaded: { _ in }, onAdFailedToLoad: { _ in })
NativeSmallBannerAdContainer(adUnitID: unit, onAdLoaded: { _ in }, onAdFailedToLoad: { _ in })
NativeCollapAdContainer(adUnitID: unit, onAdLoaded: { _ in }, onAdFailedToLoad: { _ in })
NativeCollapCloseAdContainer(
    adUnitID: unit,
    onAdLoaded: { _ in },
    onAdFailedToLoad: { _ in },
    onAdClose: { /* user đóng */ }
)
```

Native fullscreen:

```swift
@StateObject private var holder = NativeHolderAdmob(adUnitID: unit)

NativeAdFullScreenContainer(
    nativeHolder: holder,
    onAdLoaded: { _ in },
    onAdFailedToLoad: { _ in }
)
```

Hoặc presenter:

```swift
NativeFullScreenAdPresenter.shared.show(
    nativeAdManager: manager,
    onClose: { }
)
```

#### Interstitial / Rewarded / Rewarded Interstitial

```swift
@State private var interstitial = InterstitialAdManager()
@State private var reward = RewardAdManager()
@State private var rewardedInter = RewardedInterstitialAdManager()

interstitial.loadInterstitialAd(
    adUnitID: "ca-app-pub-3940256099942544/4411468910",
    onAdLoaded: { },
    onAdFailedToLoad: { _ in },
    onAdDismissed: { }
)

reward.loadRewardedAdAd(
    adUnitID: "ca-app-pub-3940256099942544/1712485313",
    onAdLoaded: { },
    onAdFailedToLoad: { _ in },
    onAdDismissed: { granted in
        // granted == true khi user xem xong và nhận reward
    }
)

rewardedInter.loadRewardedAdAd(
    adUnitID: "ca-app-pub-3940256099942544/6978759866",
    onAdLoaded: { },
    onAdFailedToLoad: { _ in },
    onAdDismissed: { granted in }
)
```

#### App Open

```swift
Task { @MainActor in
    await AppOpenAdManager.shared.loadAOA(
        adUnitID: "ca-app-pub-3940256099942544/5575463023"
    ) {
        // dismissed
    }
}
```

#### App Open khi resume (background → foreground)

```swift
// Preload sớm (ví dụ trên splash)
OnResumeManager.shared.loadAd(adUnitID: "ca-app-pub-xxx/app-open")

// Khi app active lại
OnResumeManager.shared.showAdIfAvailable()
```

Thường gắn vào `scenePhase == .active`, và bỏ qua nếu `AdsManager.shared.isShowingAd == true`.

#### Picture-in-Picture

```swift
@State private var pip = PictureInPictureAdManager()

pip.loadPictureInPictureAd(adUnitID: "ca-app-pub-xxx/pip")
// load xong sẽ tự show; hoặc gọi pip.showPictureInPictureAd()
pip.hidePictureInPictureAd()
```

### 6. Rating dialog

1–3 sao mở form feedback / mail. 4–5 sao xin in-app review (lần đầu), sau đó mở trang viết review trên App Store.

```swift
RatingDialog.Builder()
    .session(1)                 // hiện từ lần show() thứ N
    .date(1)                    // số ngày sau lần mở app đầu
    .isShowButtonLater(true)
    .isClickLaterDismiss(true)
    .setNameApp("My App")
    .setEmail("support@myapp.com")
    .setAppStoreID("1234567890")
    .setOnClickRate { stars in
        print("rated \(stars)")
    }
    .setOnClickMaybeLater {
        print("later")
    }
    .build()
    .show()
```

### 7. Remote Config helpers

```swift
let flag = RemoteConfigManager.shared.getValue(forKey: "isDebug")
// "1" / "0" hoặc chuỗi khác bạn đặt trên Firebase
```

JSON config (`ADS_SPLASH`, `ADS_HOME`, `INTER_HOME`, …) do các helper như `adsSplashView`, `adsBannerNativeView`, `loadAndShowInter`, `nativeView` đọc nội bộ. App chỉ cần đặt đúng key/JSON trên Firebase.

`initRemoteConfig` set defaults, fetch/activate, và gọi lại `onComplete` khi có update realtime.

### 8. Kiểm tra mạng trước khi show full-screen

```swift
guard NetworkMonitor.checkConnection() else {
    // hiện alert / mở Wi-Fi settings
    return
}
```

## Release a new version

Run these steps on a Mac with Xcode, CocoaPods, and a GitHub token that can push to `TienNguyen267/AdmobLibraryBinary`.

1. Bump `s.version` in `AdmobLibrary.podspec` (for example `1.0.7`).
2. Build the binary:

```bash
Scripts/build-xcframework.sh
```

3. Publish the binary tree to the public repo (no Swift source is copied):

```bash
Scripts/publish-binary.sh
```

4. Publish the podspec to CocoaPods so `pod 'AdmobLibrary', 'x.y.z'` works for everyone:

```bash
pod trunk push AdmobLibrary.podspec --allow-warnings
```

`Scripts/publish-binary.sh` only updates GitHub. CocoaPods still needs the `pod trunk push` step.

Optional install from the public git tag without waiting for the CocoaPods CDN:

```ruby
pod 'AdmobLibrary',
  :git => 'https://github.com/TienNguyen267/AdmobLibraryBinary.git',
  :tag => '1.0.7'
```

## Layout

| Path | Role |
| --- | --- |
| `Sources/AdmobLibrary/` | Private Swift source and resources |
| `AdmobLibrary.xcframework` | Built binary used by the distribution podspec |
| `AdmobLibrary.podspec` | Podspec pointed at the public binary repo |
| `Scripts/build-xcframework.sh` | Compile device + simulator archives into an xcframework |
| `Scripts/package-binary.sh` | Stage xcframework + resources only |
| `Scripts/publish-binary.sh` | Push the staged binary to `AdmobLibraryBinary` |

## License

MIT
