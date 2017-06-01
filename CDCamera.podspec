#
# Be sure to run `pod lib lint CDCamera.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CDCamera'
  s.version          = '0.3.2'
  s.summary          = 'A customized camera controller using AVFoundation'
  s.resources        = 'CDCamera/Assets/*'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A customized camera controller using AVFoundation with a cool button animation as Snapchat has.
                       DESC

  s.homepage         = 'https://github.com/carlos21/CDCamera'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'carlos21' => 'darkzeratul64@gmail.com' }
  s.source           = { :git => 'https://github.com/carlos21/CDCamera.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'CDCamera/Classes/**/*'
  
  # s.resource_bundles = {
  #    'CDCamera' => ['CDCamera/Assets/*.storyboard']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
