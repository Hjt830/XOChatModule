#
# Be sure to run `pod lib lint XOChatModule.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XOChatModule'
  s.version          = '1.0'
  s.summary          = '即时通讯项目-聊天模块'

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

  s.source_files = 'XOChatModule/Classes/**/*.{h,m,swift,xcdatamodeld,a,framework}'
  s.public_header_files = 'XOChatModule/Classes/**/*.h'
  
  s.resource_bundles = {
      'XOChatModule' => ['XOChatModule/Assets/*']
  }
  
  s.pod_target_xcconfig = { 'VALID_ARCHS[sdk=iphonesimulator*]' => '' }
  # 对.a文件的配置
  s.vendored_libraries = 'XOChatModule/Classes/Lib/lame/libmp3lame.a'
#  # 对.framework文件的配置
#  s.vendored_frameworks = 'XOChatModule/Classes/Lib/AMap/AMap2DMap-NO-IDFA/MAMapKit.framework', 'XOChatModule/Classes/Lib/AMap/AMapFoundation-NO-IDFA/AMapFoundationKit.framework', 'XOChatModule/Classes/Lib/AMap/AMapLocation-NO-IDFA/AMapLocationKit.framework', 'XOChatModule/Classes/Lib/AMap/AMapSearch-NO-IDFA/AMapSearchKit.framework'
#  # 对sdk中头文件的配置
#  s.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => 'XOChatModule/Classes/Lib/AMap/*/*/Headers/*.{h}'}

  s.frameworks = 'UIKit', 'Foundation', 'CoreLocation'
  s.dependency 'TXIMSDK_iOS', '~> 4.6.1'
  s.dependency 'XOBaseLib', '~> 0.3.6'
  s.dependency 'TZImagePickerController', '~> 3.2.1'
  s.dependency 'GCDMulticastDelegate', '~> 1.0.0'
  s.dependency 'SVProgressHUD', '~> 2.2.5'
  s.dependency 'AFNetworking', '~> 3.2.1'
  s.dependency 'YBImageBrowser/NOSD', '~> 3.0.6'
  s.dependency 'YBImageBrowser/VideoNOSD', '~> 3.0.6'
  s.dependency 'FLAnimatedImage', '~> 1.0.12'
  s.dependency 'FMDB', '~> 2.7.5'
  s.dependency 'YYModel', '~> 1.0.4'
  s.dependency 'FSTextView', '~> 1.8'

end
