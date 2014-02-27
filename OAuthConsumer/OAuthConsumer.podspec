Pod::Spec.new do |s|
  s.name         = "OAuthConsumer"
  s.version      = "1.0"
  s.summary      = "Testing OAuthConsumer"
  s.homepage     = "http://www.thereisnohomepage.com"
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = '{**,Crypto,Categories}/*.{h,m,c}'
  s.author       = { "Syed" => "syedsanahassan@gmail.com" }
end
