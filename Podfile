platform :ios, '15.0'

use_frameworks! :linkage => :static

target 'AdmobLibrary' do
  pod 'AdmobLibrary'
  
  pod 'FirebaseCore'
  pod 'FirebaseAnalytics'
  pod 'FirebaseRemoteConfig'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseMessaging', :modular_headers => true

  # ✅ Fix “does not define modules” when building static / Swift pods
  pod 'GoogleUtilities', :modular_headers => true
  pod 'GoogleDataTransport', :modular_headers => true
  pod 'nanopb', :modular_headers => true
  pod 'FirebaseABTesting', :modular_headers => true
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
