#!/usr/bin/env ruby

# file: dir-to-xml.rb

require 'dynarex'


class DirToXML


  def initialize(path= '.', recursive: false)
    super()
        
    old_path = Dir.pwd
    raise "Directory not found." unless File.exists? path
    Dir.chdir  path

    a = Dir.glob("*").sort
    a.delete 'dir.xml'
    
    a2 = a.inject([]) do |r, x|

      r << {
        name: x,
        type: File::ftype(x),
        ext: File.extname(x),
        created: File::ctime(x),
        last_modified: File::mtime(x),
        last_accessed: File::atime(x)
      }

    end    

    command = File.exists?('dir.xml') ? :refresh : :dxify
    
    @dx  = self.method(command).call a2

    Dir.chdir old_path 

    @h = @dx.to_h
    @object = @h
    
    @path = path
    @recursive = recursive

  end
  
  def filter(pattern=/.*/)
    @object = @h.select {|x| x[:name] =~ pattern }
    self
  end
  
  def last_modified(ext=nil)
    
    if ext and ext != '*' then
      @object = @h.select{|x| x[:ext][/#{ext}/] or x[:type] == 'directory'}
    end
    
    a = sort_by :last_modified
    a2 = a.reject {|x| x[:name] == 'dir.xml'}    
    
    lm =  a2[-1]
    
    if @recursive and lm[:type] == 'directory' then
      return [lm, DirToXML.new(File.join(@path,  lm[:name])).last_modified]
    else
      lm
    end
  end
  
  def select_by_ext(ext)
    
    @object = ext != '*' ? @h.select{|x| x[:ext][/#{ext}/]} : @h
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
  
  def to_xml(options=nil)
    @dx.to_xml options
  end
  
  def to_dynarex
    @dx.clone
  end
  
  private
      
  def dxify(a)
    
    dx = Dynarex.new 'directory[title,file_path]/file(name, ' + \
            'type, ext, created, last_modified, last_accessed,' + \
                            ' description, owner, group, permissions)'

    dx.title = 'Index of ' + File.basename(Dir.pwd)
    dx.file_path = Dir.pwd

    dx.import a
    dx.save 'dir.xml'
    
    return dx

  end

  def refresh(cur_files)

    dx = Dynarex.new 'dir.xml'

    prev_files = dx.to_a
            
    cur_files.each do |x|
      file = prev_files.find {|item| item[:name] == x[:name] }
      x[:description] = file[:description] if file and file[:description]
    end

    dxify(cur_files)
    
  end
  
end