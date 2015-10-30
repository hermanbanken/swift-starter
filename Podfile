# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
# use_frameworks!

pod 'R.swift', '~> 0.10.0'
pod 'PureLayout', '~> 1.1'
pod 'NSURL+QueryDictionary', '~> 1.0'
pod 'NSDate-Extensions-iOS7', '~> 1.0'
pod 'pop', '~> 1.0'
pod 'JGProgressHUD', '~> 1.2'
pod 'RSBarcodes', '~> 0.1'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
    end
  end
end