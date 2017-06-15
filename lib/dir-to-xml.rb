#!/usr/bin/env ruby

# file: dir-to-xml.rb

require 'dynarex'


class DirToXML

  attr_reader :dx
  
  def initialize(x= '.', recursive: false, index: 'dir.xml')

    super()
    
    if x.is_a? Dynarex then
      
      @dx = x      
      @a = @dx.to_a    
      @object = @a      
      
      return self
    end
    
    path = x
    
    @path, @index, @recursive = path, index, recursive
    
    raise "Directory not found." unless File.exists? path

    a = Dir.glob(File.join(path, "*")).map{|x| File.basename(x) }.sort

    a.delete index

    a2 = a.inject([]) do |r, filename|

      x = File.join(path, filename)
      
      begin
      r << {
        name: filename,
        type: File::ftype(x),
        ext: File.extname(x),
        ctime: File::ctime(x),
        mtime: File::mtime(x),
        atime: File::atime(x)
      }
      rescue
        r
      end

    end    

    command = File.exists?(File.join(path, index)) ? :refresh : :dxify

    @dx  = self.method(command).call a2
    
    @a = @dx.to_a    
    
    if recursive then

      self.filter_by(type: :directory).to_a.each do |x|

        path2 = File.join(path, x[:name])
        DirToXML.new(path2, recursive: true)
      end
    end
    
    @object = @a

  end
  
  def filter(&blk)
    @dx.filter &blk
  end
  
  def filter_by(pattern=/.*/, type: nil)
    
    @object = @a.select do |x| 
            
      pattern_match = x[:name] =~ pattern
      type_match = type ? x[:type] == type.to_s : true

    end
    
    self
  end
    
  def find_by_filename(s)
    @dx.all.find {|item| item.name == s}
  end
  
  alias find_by_file find_by_filename
  
  def last_modified(ext=nil)

    if ext and ext != '*' then
      @object = @a.select{|x| x[:ext][/#{ext}/] or x[:type] == 'directory'}
    end
    
    a = sort_by :mtime

    lm =  a[-1]
    
    if @recursive and lm[:type] == 'directory' then
      return [lm, DirToXML.new(File.join(@path,  lm[:name])).last_modified]
    else
      lm
    end
  end
  
  def save()
    @dx.save File.join(@path, @index)
  end
  
  def select_by_ext(ext)
    
    @object = ext != '*' ? @a.select{|x| x[:ext][/#{ext}/]} : @a
    dx = Dynarex.new json_out: false
    dx.import @object
    DirToXML.new(dx)
  end
  
  def sort_by(sym)
    procs = [[:mtime, lambda{|obj| obj.sort_by{|x| x[:mtime]}}]]
    proc1 = procs.assoc(sym).last
    proc1.call(@object)
  end
  
  def sort_by_last_modified()
    sort_by :mtime
  end
  
  alias sort_by_lastmodified sort_by_last_modified
  
  def to_a
    @object || @a
  end
  
  def to_h()
    self.to_a.inject({}){|r,x| r.merge(x[:name] => x)}
  end
  
  def to_xml(options=nil)
    @dx.to_xml options
  end
  
  def to_dynarex
    @dx.clone
  end
  
  private
      
  def dxify(a)
    
    dx = Dynarex.new('directory[title, file_path, description]/file(name, ' + \
            'type, ext, ctime, mtime, atime, description, owner, ' + \
                                        'group, permissions)', json_out: false)

    dx.title = 'Index of ' + File.expand_path(@path)
    dx.file_path = File.expand_path(@path)

    dx.import a

    dx.save File.join(@path, @index)

    return dx

  end

  def refresh(cur_files)

    dx = Dynarex.new(File.join(@path, @index), json_out: false)

    prev_files = dx.to_a
            
    cur_files.each do |x|

      file = prev_files.find {|item| item[:name] == x[:name] }

      x[:description] = file[:description] if file and file[:description]
    end

    dxify(cur_files)
    
  end
  
end
