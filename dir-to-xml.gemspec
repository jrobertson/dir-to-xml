Gem::Specification.new do |s|
  s.name = 'dir-to-xml'
  s.version = '0.3.1'
  s.summary = 'dir-to-xml saves a directory listing in a Dynarex XML format'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('dynarex')
end
