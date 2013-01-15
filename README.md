#Introducing the Dir-to-XML gem

    require 'dir-to-xml'

    a = DirToXML.new.sort_by :last_modified

    a[-5..-1].each{|x| puts "%s %-9s %s" % %w(last_modified type name).map{|y| x[y.to_sym]}}

output:

    2013-01-04 15:11:26 +0000 directory downloads
    2013-01-15 21:10:40 +0000 directory Downloads
    2013-01-15 21:30:19 +0000 directory m
    2013-01-15 21:34:00 +0000 file      config.txt
    2013-01-15 22:49:11 +0000           dir.xml

The above example selects the last 5 files sorted by last modified date. Of course it also generates an XML file in Dynarex format automatically in the current directory.

The other methods are :to_xml, :to_dynarex, :sort_by, and :select_by_ext

gem dir-to-xml dirtoxml
