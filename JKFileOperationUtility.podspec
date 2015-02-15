Pod::Spec.new do |s|
  s.name          = 'JKFileOperationUtility'
  s.version       = '1.0'
  s.license       = 'MIT'
  s.summary       = 'iOS File operations made easy with easy to use collection of APIs for basic file operations'
  s.homepage      = 'https://github.com/jayesh15111988'
  s.author        = 'Jayesh Kawli'
  s.source        = {
            :git => 'git@github.com:jayesh15111988/JKFileOperationUtility.git',:branch => 'master'
            }
  s.source_files  = 'JKFileOperationUtility/Classes/**'
  s.requires_arc  = true
  s.ios.deployment_target = '7.0'
end
