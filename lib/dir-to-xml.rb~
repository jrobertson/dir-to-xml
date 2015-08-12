#!/usr/bin/env ruby

# file: dir-to-xml.rb

require 'dynarex'

class DirToXML

  attr_reader :status

  def initialize(path= '.')
    super()
    old_path = Dir.pwd
    raise "Directory not found." unless File.exists? path
    Dir.chdir  path

    a = Dir.glob("*").sort

    command = a.include?('dir.xml') ? 'run' : 'new_run'      
    @doc, @status = self.send command, a

    Dir.chdir old_path #File.expand_path('~')
    @h = self.to_dynarex.to_h
    @object = @h
  end
  
  def filter(pattern=/.*/)
    @object = @h.select {|x| x[:name] =~ pattern }
    self
  end
  
  def select_by_ext(ext)
    @object = @h.select{|x| x[:ext][/#{ext}/]}
    self
  end
  
  def sort_by(sym)
    procs = [[:last_modified, lambda{|obj| obj\
                                     .sort_by{|x| x[:last_modified]}}]]
    proc1 = procs.assoc(sym).last
    proc1.call(@object)
  end
  
  def sort_by_last_modified()
    sort_by :last_modified
  end
  
  alias sort_by_lastmodified sort_by_last_modified
  
  def to_h
    @object || @h
  end
  
  def to_xml
    @doc.to_s
  end
  
  def to_dynarex
    Dynarex.new @doc.to_s
  end
  
  private
      
  def new_element(name, text=nil)
    new_node = Rexle::Element.new(name)
    new_node.text = text if text
    new_node
  end

  def new_file(name, type, ext, ctime, mtime, atime)
    node = Rexle::Element.new('file')
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
      [x, File.extname(x), File::ftype(x), File::ctime(x), \
                                            File::mtime(x), File::atime(x)]
    end

    records = doc.root.element('records')
    i = '0'

    dir_files.each do |name, ext, type, ctime, mtime, atime|       
      records.add_element new_file(name, type, ext, ctime, mtime, atime)
      i.succ!
    end
  end

  def new_run(a)

summary = "
<summary>
  <title>Index of #{File.basename(Dir.pwd)}</title>
  <file_path>#{File.dirname(Dir.pwd)}</file_path>
  <recordx_type>dynarex</recordx_type>
  <schema>directory[title,file_path]/file(name, type, ext, created, " \
   + "last_modified, last_accessed, description, owner, group, permissions)" \
   + "</schema>\n</summary>"

    buffer = "<directory>%s<records/></directory>" % summary
    doc = Rexle.new(buffer)
    add_files(doc, a)

    doc.root.element('records').add_element new_file(name='dir.xml', type=nil, ext='.xml', *[Time.now] * 3)

    File.open('dir.xml','w'){|f| f.write doc.xml pretty: false}
    [doc, "created"]
  end

  def run(a)

    doc = Rexle.new(File.open('dir.xml','r').read)   
    
    doc.root.xpath('records/file').each do |x|    
      x.element('last_modified').text = File.mtime x.text('name') if File.exists?(x.text('name'))
    end
    
    a_dir = doc.root.xpath('records/file/name/text()').sort
    
    if a == a_dir then
      File.open('dir.xml','w'){|f| doc.write f}
      return [doc, "nothing new"]
    end

    # files to add
    files_to_insert = a - a_dir
    add_files(doc, files_to_insert)
    
    # files to delete
    files_to_delete = a_dir - a

    files_to_delete.each do |filename|
      node = doc.root.element("records/file[name='#{filename}']")
      node.delete
    end

    File.write 'dir.xml', doc.xml(pretty: true)
    [doc, "updated"]
  end
end