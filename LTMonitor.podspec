#
# Be sure to run `pod lib lint LTMonitor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LTMonitor'
  s.version          = '0.1.0'
  s.summary          = 'A short description of LTMonitor.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/wolf_childer@163.com/LTMonitor'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lvjianxiong' => 'wolf_childer@163.com' }
  s.source           = { :git => 'https://github.com/wolf_childer@163.com/LTMonitor.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'LTMonitor/Classes/**/*'
  
  # s.resource_bundles = {
  #   'LTMonitor' => ['LTMonitor/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  # add private framework s.vendored_frameworks = "xxx/CrashReporter.framework", "xxx/CrashReporter.framework"
  s.vendored_frameworks = "LTMonitor/Frameworks/CrashReporter.framework"
  # s.resource_bundles = {
  #   'RCMonitor' => ['RCMonitor/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
#   s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'MLeaksFinder'
end
