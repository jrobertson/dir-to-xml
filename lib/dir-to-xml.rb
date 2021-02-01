#!/usr/bin/env ruby

# file: dir-to-xml.rb

require 'dxlite'


class DirToXML

  attr_reader :dx, :activity
  
  def initialize(x= '.', recursive: false, index: 'dir.xml', debug: false)
    
    super()
    
    @debug = debug
    
    @dx = nil
    @activity = {new: [], modified: []}
    
    if x.is_a? DxLite then
      
      @dx = x      
      @a = @dx.to_a    
      @object = @a      
      
      return self
    end
    
    path = x
    
    @path, @index, @recursive = path, index, recursive
    
    raise "Directory not found." unless File.exists? path
    filepath = File.join(path, index)
    
    
    if File.exists? filepath then
    
      @dx = DxLite.new(File.join(@path, @index), debug: @debug)
      
    else
      
      @dx = DxLite.new('directory[title, file_path, last_modified, ' + \
              'description]/file(name, type, ext, ctime, mtime, atime, ' + \
              'description, owner, group, permissions)')

      puts 'before title' if @debug
      @dx.title = 'Index of ' + File.expand_path(@path)
      @dx.file_path = File.expand_path(@path)
      @dx.last_modified = ''
    
    end        
    
    puts 'before Dir.glob' if @debug
    
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
    
    # has the directory been modified since last time?
    #
    if @dx and @dx.respond_to? :last_modified and \
        @dx.last_modified.length > 0 then
      
      puts 'nothing to do' if @debug
      
      file = a2.max_by {|x| x[:mtime]}
      puts 'file: ' + file.inspect if @debug
      return if Time.parse(@dx.last_modified) >= (file[:mtime])
      
    end    
    

    
    if @dx and @dx.respond_to? :last_modified  then
      
      if @dx.last_modified.length > 0 then
      
        t = Time.parse(@dx.last_modified)
        
        # find the most recently modified cur_files
        recent = a2.select {|x| x[:mtime] > t }.map {|x| x[:name]} \
            - %w(dir.xml dir.json)
        
        # is it a new file or recently modified?
        new_files = recent - @dx.to_a.map {|x| x[:name]}
        modified = recent - new_files
        
      else
        
        new_files = a2.select {|x| x[:type] == 'file'}.map {|x| x[:name]}
        modified = []
        
      end
      
      @activity = {modified: modified, new: new_files}
      
    end
      

    command = File.exists?(File.join(path, index)) ? :refresh : :dxify

    self.method(command).call a2
    puts '@dx: ' + @dx.inspect if @debug
    puts '@dx.last_modified: ' + @dx.last_modified.inspect if @debug
    
    
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
  
  def filter_by(pattern=/.*/, type: nil, ext: nil)
    
    @object = @a.select do |x| 
            
      pattern_match = x[:name] =~ pattern
      
      type_match = type ? x[:type] == type.to_s : true
      ext_match = ext ? x[:ext] == ext.to_s : true

      pattern_match and type_match and ext_match

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
  
  def select_by_ext(ext, &blk)
    
    @object = ext != '*' ? @a.select{|x| x[:ext][/#{ext}$/]} : @a
    return if @object.empty?
    
    dx = DxLite.new
    dx.import @object
    dtx = DirToXML.new(dx)
    block_given? ? dtx.dx.all.map(&:name).each(&blk) : dtx
  end
  
  def sort_by(sym)
    
    puts 'inside sort_by' if @debug
    procs = [[:mtime, lambda{|obj| obj.sort_by{|x| x[:mtime]}}]]
    proc1 = procs.assoc(sym).last
    
    puts '@object: ' + @object.inspect if @debug
    @object = @a = @dx.to_a if @object.nil?
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
  
  alias to_dx to_dynarex
  
  private
      
  def dxify(a)
    
    @dx.last_modified = Time.now.to_s  if @dx.respond_to :last_modified
    @dx.import a
    @dx.save File.join(@path, @index)

  end

  def refresh(cur_files)

    puts 'inside refresh' if @debug    

    prev_files = @dx.to_a
    
    #puts 'prev_files: ' + prev_files.inspect
    #puts 'cur_files: ' + cur_files.inspect
            
    cur_files.each do |x|

      file = prev_files.find {|item| item[:name] == x[:name] }
      #puts 'found : ' + file.inspect if @debug
      x[:description] = file[:description] if file and file[:description]
    end

    dxify(cur_files)
    
  end
  
end
