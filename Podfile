platform :ios, '15.0'

use_frameworks! :linkage => :static

target 'AdmobLibrary' do
  pod 'AdmobLibrary', :path => '.'

  pod 'FirebaseCore'
  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseMessaging'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      next unless target.name == 'AdmobLibrary'

      config.build_settings['SWIFT_VERSION'] = '6.0'
      config.build_settings['SWIFT_DEFAULT_ACTOR_ISOLATION'] = 'MainActor'
      config.build_settings['SWIFT_APPROACHABLE_CONCURRENCY'] = 'YES'
      config.build_settings['SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY'] = 'YES'
    end
  end
end
