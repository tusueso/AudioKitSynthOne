platform :ios, '9.0'
use_frameworks!

# This enables the cutting-edge staging builds of AudioKit, comment this line to stick to stable releases
source 'https://github.com/AudioKit/Specs.git'
source 'https://github.com/CocoaPods/Specs.git'

def common_pods
    pod 'AudioKit', '>=4.4'
    pod 'OneSignal', '>= 2.6.2', '< 3.0'
end

def base_pods
    common_pods
    pod 'Disk', '~> 0.3.2'
    pod 'Audiobus'
end

target 'AudioKitSynthOne' do
    base_pods 
    pod 'ChimpKit'
end

target 'SynthOneAUv3' do
    base_pods
end

target 'OneSignalNotificationServiceExtension' do
    common_pods
end
