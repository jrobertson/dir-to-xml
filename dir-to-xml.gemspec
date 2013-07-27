Gem::Specification.new do |s|
  s.name = 'dir-to-xml'
  s.version = '0.3.3'
  s.summary = 'dir-to-xml saves a directory listing in a Dynarex XML format'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('dynarex') 
  s.signing_key = '../privatekeys/dir-to-xml.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/dir-to-xml'
end
