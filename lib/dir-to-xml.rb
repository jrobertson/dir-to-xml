#!/usr/bin/ruby

# file: dir-to-xml.rb

require 'rexml/document'

class DirToXML
  #include PrettyXML
  include REXML

  attr_reader :status

  def initialize(path= '.')
    Dir.chdir  path

    a = Dir.glob("*").sort
    command = a.include?('dir.xml') ? 'run' : 'new_run'      
    @doc, @status = self.send command, a
  end
  
  def to_xml
    @doc.to_s
  end      
  
  private
      
  def new_element(name, text=nil)
    new_node = Element.new(name)
    new_node.text = text if text
    new_node
  end

  def new_file(name, type, ext, ctime, mtime, atime)
    node = Element.new('file')
    node.add_element new_element('name', name)
    node.add_element new_element('type', type)
    node.add_element new_element('ext', ext)
    node.add_element new_element('created', ctime)
    node.add_element new_element('last_modified', mtime)
    node.add_element new_element('last_accessed', atime)
    node.add_element new_element('description')
    node.add_element new_element('owner')
    node.add_element new_element('group')
    node.add_element new_element('permissions')
    node
  end

  def add_files(doc, a)
    dir_files = a.map do |x| 
      [x, File.extname(x), File::ftype(x), File::ctime(x), File::mtime(x), File::atime(x)]
    end

    dir_files.each do |name, ext, type, ctime, mtime, atime|       
      doc.root.elements['records'].add_element new_file(name, type, ext, ctime, mtime, atime)
    end
  end

  def new_run(a)

    summary = "<summary><title>Index of %s</title><file_path>%s</file_path></summary>" % [File.basename(Dir.pwd), File.dirname(Dir.pwd)[/\/home\/james\/heroku\/(.*)/,1]]
    #summary = "<summary/>"
    buffer = "<?xml version='1.0' encoding='UTF-8'?><directory>%s<records/></directory>" % summary
    doc = Document.new(buffer)
    add_files(doc, a)

    doc.root.elements['records'].add_element new_file(name='dir.xml', type=nil, ext='.xml', *[Time.now] * 3)

    #File.open('dir.xml','w'){|f| f.write pretty_xml(doc)}
    File.open('dir.xml','w'){|f| doc.write f}
    [doc, "created"]
  end

  def run(a)

    doc = Document.new(File.open('dir.xml','r').read)   
    #puts 'before a)dir'
    a_dir = XPath.match(doc.root, 'records/file/name/text()').map {|x| x.to_s}.sort

    return [doc, "nothing new"] if a == a_dir

    # files to add
    files_to_insert = a - a_dir
    add_files(doc, files_to_insert)

    # files to delete
    files_to_delete = a_dir - a
    files_to_delete.each do |filename|
      node = doc.root.elements["records/file[name='#{filename}']"]
      node.parent.delete node
    end

    #File.open('dir.xml','w'){|f| f.write pretty_xml(doc)}
    File.open('dir.xml','w'){|f| doc.write f}
    [doc, "updated"]
  end
end


