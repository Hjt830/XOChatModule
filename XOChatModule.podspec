#
# Be sure to run `pod lib lint XOChatModule.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XOChatModule'
  s.version          = '0.0.2'
  s.summary          = 'XXOOGO项目的聊天模块'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  XXOOGO项目采用cocoapods做组件化架构，将不同的模块使用pod私有仓库管理，只需要在主项目中使用 pod 'XOChatModule' 即可导入模块使用
                       DESC

  s.homepage         = 'http://192.168.1.119/xxoogo_livechat/xochatmodule'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kenter' => 'Hjt_830@163.com' }
  s.source           = { :git => 'http://192.168.1.119/xxoogo_livechat/xochatmodule.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'XOChatModule/Classes/**/*'
  s.public_header_files = 'XOChatModule/Classes/**/*.h'
  
  s.resource_bundles = {
      'XOChatModule' => ['XOChatModule/Assets/*']
  }
  
  # 对.a文件的配置
  s.vendored_libraries = '${PODS_ROOT}/../../XOChatModule/Classes/Lib/lame'
#  # 对.framework文件的配置
#  s.vendored_frameworks = '${PODS_ROOT}/../../XOChatModule/Classes/Lib/AMap/AMap2DMap-NO-IDFA/MAMapKit.framework', '${PODS_ROOT}/../../XOChatModule/Classes/Lib/AMap/AMapFoundation-NO-IDFA/AMapFoundationKit.framework', '${PODS_ROOT}/../../XOChatModule/Classes/Lib/AMap/AMapLocation-NO-IDFA/AMapLocationKit.framework', '${PODS_ROOT}/../../XOChatModule/Classes/Lib/AMap/AMapSearch-NO-IDFA/AMapSearchKit.framework'
#  # 对sdk中头文件的配置
#  s.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '${PODS_ROOT}/../../XOChatModule/Classes/Lib/AMap/*/*/Headers/*.{h}'}

  s.frameworks = 'UIKit', 'Foundation', 'CoreLocation'
  s.dependency 'TXIMSDK_iOS', '~> 4.4.627'
  s.dependency 'XOBaseLib', '~> 0.2.6'
  s.dependency 'TZImagePickerController', '~> 3.2.1'
  s.dependency 'CTMediator', '~> 25'
#  s.dependency 'ReactiveObjC', '~> 3.1.1'
  s.dependency 'GCDMulticastDelegate', '~> 1.0.0'
  s.dependency 'SVProgressHUD', '~> 2.2.5'
  s.dependency 'AFNetworking', '~> 3.2.1'
  s.dependency 'YBImageBrowser/NOSD', '~> 3.0.6'
  s.dependency 'YBImageBrowser/VideoNOSD', '~> 3.0.6'
  s.dependency 'FLAnimatedImage', '~> 1.0.12'
  s.dependency 'FMDB', '~> 2.7.5'

end
