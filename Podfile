platform :ios, '18.0'

target 'Fluxor' do
  use_frameworks!

  pod 'SwiftyUserDefaults', :git => 'https://github.com/SunZhiC/SwiftyUserDefaults.git', :branch => 'master'
  pod 'SkeletonView', :git => 'https://github.com/SunZhiC/SkeletonView.git', :branch => 'main'

  pod 'ParticleNetworkBase', '2.0.9'
  pod 'ParticleAuthCore', '2.0.8'
  pod 'ParticleMPCCore', '2.0.8'
  pod 'AuthCoreAdapter', '2.0.8'
  pod 'Thresh', '2.0.8'
  pod 'ParticleConnectKit', '2.0.8'
  pod 'ConnectEVMAdapter', '~> 2.0'
  pod 'ParticleWalletAPI', '2.0.9'
  pod 'ParticleWalletGUI', '2.0.9'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end