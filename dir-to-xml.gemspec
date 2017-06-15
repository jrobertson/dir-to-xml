Gem::Specification.new do |s|
  s.name = 'dir-to-xml'
  s.version = '0.9.2'
  s.summary = 'Dir-to-xml saves a directory listing in the Dynarex XML format'
  s.authors = ['James Robertson']
  s.files = Dir['lib/dir-to-xml.rb']
  s.add_runtime_dependency('dynarex', '~> 1.7', '>=1.7.22') 
  s.signing_key = '../privatekeys/dir-to-xml.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/dir-to-xml'
  s.required_ruby_version = '>= 2.1.2'
end
