Gem::Specification.new do |s|
  s.name = 'dir-to-xml'
  s.version = '1.2.1'
  s.summary = 'Dir-to-xml saves a directory listing in the Dynarex XML format'
  s.authors = ['James Robertson']
  s.files = Dir['lib/dir-to-xml.rb']
  #s.add_runtime_dependency('c32', '~> 0.3', '>=0.3.0')
  s.add_runtime_dependency('dxlite', '~> 0.6', '>=0.6.0')
  s.signing_key = '../privatekeys/dir-to-xml.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/dir-to-xml'
  s.required_ruby_version = '>= 3.0.2'
end
