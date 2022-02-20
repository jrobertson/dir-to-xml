#!/usr/bin/env ruby

# file: dir-to-xml.rb

require 'c32'
require 'dxlite'


# How dir-to-xml should work
#
# if the dir.xml file doesn't exist then
#
#   generate the dir.xml file
#
# else
#
#   # the dir.xml file does exist
#
#   # check for one of the following:
#   #  1 or more new files
#   #  1 or more removed files
#   #  1 or more modified files
#
# note: Ideally The index needs to be stored and retrieved the fastest way possible.
#       This is why it's saved as a .json file rather .xml
#
# tested:
# * finding the latest file in the current directory
# * finding the latest file in a sub-directory (using recursive: true)


class DirToXML
  using ColouredText
  include RXFReadWriteModule

  attr_reader :new_files, :deleted_files, :dx, :latest_files, :latest_file

  def initialize(obj= '.', index: 'dir.json', recursive: false,
                 verbose: true, debug: false)

    if verbose then
      puts
      puts 'DirToXML at your service!'.highlight
      puts
      puts
    end

    @index, @recursive, @verbose, @debug = index, recursive, verbose, debug

    if File.basename(obj) == index then

      #read the index file
      @path = File.dirname(obj)
      puts 'intialize() @path: ' + @path.inspect if @debug

      @dx = read(obj)

    else
      @path = obj
      puts 'intialize() @path: ' + @path.inspect if @debug

      new_scan()
    end

  end

  def activity()
    {
      new: @new_files,
      deleted: @deleted_files,
      modified: @latest_files
    }
  end

  alias changes activity

  def directories()
    @dx.all.select {|x| x.type == 'directory'}.map(&:name)
  end

  def find_all_by_ext(s)
    @dx.find_all_by_ext(s)
  end

  def find_by_filename(s)
    @dx.find_by_filename(s)
  end

  def latest()

    if @latest_file then
      File.join(@latest_file[:path], @latest_file[:name])
    end

  end

  def new_scan()

    t = Time.now
    records = scan_dir @path
    puts 'new_scan() records: ' + records.inspect if @debug

    a = records.map {|x| x[:name]}

    if FileX.exists? File.join(@path, @index) then

      @dx = read()

      old_records = @dx.to_a
      a2 = old_records.map {|x| x[:name]}

      # delete any old files
      #
      @deleted_files = a2 - a

      if @deleted_files.any? then

        @deleted_files.each do |filename|
          record = @dx.find_by_name filename
          record.delete if record
        end

      end

      # check for newly modified files
      # compare the file date with index file last modified date
      #
      dtx_last_modified = Time.parse(@dx.last_modified)

      select_records = records.select do |file|

        file[:mtime] > dtx_last_modified or file[:type] == 'directory'

      end

      puts 'select_records: ' + select_records.inspect if @debug
      find_latest(select_records) if select_records.any?

      # Add any new files
      #
      @new_files = a - a2

      if @new_files.any? then

        @dx.last_modified = Time.now.to_s
        @dx.import @new_files.map {|filename| getfile_info(filename) }

      end

      @dx.last_modified = Time.now.to_s if @deleted_files.any?

    else

      @dx = new_index(records)
      find_latest(records)

    end

    t2 = Time.now - t
    puts ("directory scanned in %.2f seconds" % t2).info if @verbose

  end

  def read(index=@index)

    t = Time.now
    puts 'read path: ' + File.join(@path, index).inspect if @Debug

    dx = DxLite.new(File.join(@path, index), autosave: true)

    t2 = Time.now - t
    puts ("%s read in %.2f seconds" % [@index, t2]).info if @verbose

    return dx

  end

  private

  def find_latest(files)

    @latest_files = files.sort_by {|file| file[:mtime]}
    puts '@latest_files:  ' + @latest_files.inspect if @debug

    @latest_file = @latest_files[-1]
    @latest_file[:path] = @path
    puts ':@latest_file: ' + @latest_file.inspect if @debug

    dir_list = directories()

    if dir_list.any? then

      dir_latest = dir_list.map do |dir|

        puts 'dir: ' + dir.inspect if @debug
        dtx2 = DirToXML.new(File.join(@path, dir), index: @index,
                            recursive: true, verbose: false, debug: @debug)
        [dir, dtx2.latest_file]

      end.reject {|_,latest|  latest.nil? }.sort_by {|_, x| x[:mtime]}.last

      puts 'dir_latest: ' + dir_latest.inspect if @debug

      @latest_file = if dir_latest and \
                          ((dir_latest.last[:mtime] > latest_file[:mtime]) \
                                     or latest_file.nil? \
                                     or latest_file[:type] == 'directory') then

        dir_latest.last[:path] = File.expand_path(File.join(@path, dir_latest.first))
        dir_latest.last

      elsif latest_file and latest_file[:type] == 'file'

        latest_file[:path] = File.expand_path(@path)
        latest_file

      end

    else
      return
    end

  end

  def getfile_info(filename)

    x = File.join(@path, filename)
    puts 'x: ' + x.inspect if @debug

    begin
      {
        name: filename,
        type: File::ftype(x),
        ext: File.extname(x),
        mtime: File::mtime(x),
        description: ''
      }
    end
  end

  def new_index(records)

    dx = DxLite.new('directory[title, file_path,  ' +
                      'last_modified, description]/file(name, ' +
                                    'type, ext, mtime, description)')

    puts 'before title' if @debug
    dx.title = 'Index of ' + @path
    dx.file_path = @path
    dx.last_modified = Time.now
    dx.import records.reverse
    dx.save File.join(@path, @index)

    return dx

  end

  def scan_dir(path)

    a = DirX.glob(File.join(path, "*")).map {|x| File.basename(x) }
    a.delete @index
    a.map {|filename| getfile_info(filename) }

  end

end
