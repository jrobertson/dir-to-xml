Gem::Specification.new do |s|
  s.name = 'dir-to-xml'
  s.version = '0.6.0'
  s.summary = 'Dir-to-xml saves a directory listing in the Dynarex XML format'
  s.authors = ['James Robertson']
  s.files = Dir['lib/dir-to-xml.rb']
  s.add_runtime_dependency('dynarex', '~> 1.5', '>=1.5.33') 
  s.signing_key = '../privatekeys/dir-to-xml.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/dir-to-xml'
  s.required_ruby_version = '>= 2.1.2'
end
