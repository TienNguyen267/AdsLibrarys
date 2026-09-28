Pod::Spec.new do |s|
  s.name             = 'AdmobLibrary'
  s.version          = '1.0.0'
  s.summary          = 'Reusable AdMob views and managers for SwiftUI apps.'
  s.description      = 'Banner, native, interstitial, rewarded, and app-open ads, with Firebase Remote Config and mediation adapters.'
  s.homepage         = 'https://github.com/TienNguyen267/AdsLibrarys'
  s.license          = { :type => 'MIT' }
  s.author           = { 'VietTienNguyen' => 'viettiennguyen2607@gmail.com' }
  s.source           = { :git => 'https://github.com/TienNguyen267/AdsLibrarys.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_versions = ['6.0']
  s.static_framework = true

  s.source_files = 'Sources/AdmobLibrary/**/*.swift'
  s.resource_bundles = {
    'AdmobLibraryResources' => [
      'Sources/AdmobLibrary/Resources/**/*.{xib,xcassets,json}'
    ]
  }

  s.dependency 'TenjinSDK'
  s.dependency 'SolarEngineSDKiOSInter', '~> 1.3.1.0'
  s.dependency 'Google-Mobile-Ads-SDK', '~> 13.0'
  s.dependency 'GoogleMobileAdsMediationFacebook'
  s.dependency 'GoogleMobileAdsMediationMintegral'
  s.dependency 'GoogleMobileAdsMediationIronSource'
  s.dependency 'GoogleMobileAdsMediationAppLovin'
  s.dependency 'GoogleMobileAdsMediationPangle'
  s.dependency 'GoogleMobileAdsMediationVungle'
  s.dependency 'GoogleMobileAdsMediationUnity'
  s.dependency 'FirebaseRemoteConfig'
  s.dependency 'lottie-ios'

  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '6.0',
    'SWIFT_DEFAULT_ACTOR_ISOLATION' => 'MainActor',
    'SWIFT_APPROACHABLE_CONCURRENCY' => 'YES',
    'SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY' => 'YES',
    'IPHONEOS_DEPLOYMENT_TARGET' => '15.0'
  }
end
