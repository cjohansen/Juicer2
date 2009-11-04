# -*- coding: utf-8 -*-

require "juicer/io_proxy"
require "fileutils"

module Juicer
  #
  # Provides file concatenation for linked files. Requires the including class
  # to provide a <tt>#dependencies</tt> method that returns an array of resource
  # instances to include when concatenating all files.
  #
  # = Overview
  #
  # Given an class <tt>Resource</tt> (and instance <tt>resource</tt>) that
  # includes the module, these are the methods provided.
  #
  # Export the resource to a file. Will include dependency statements for any
  # dependencies
  #   file = File.open("myfile.txt", "w")
  #   resource.export(file)
  #   file.close
  #
  # If you'd rather include the contents of the dependencies inline you can
  # specify the <tt>:inline_dependencies = true</tt> option. In this case, the
  # dependency statements in the original source are removed.
  #   resource.export(file, :inline_dependencies => true)
  #
  # There are a few alternative ways to export contents:
  #
  # Write to open file handler
  #   File.open("myfile.txt", "w")
  #   resource.export(file)
  #   file.close
  #
  # Export to filename, analogous to above example
  #   resource.export("myfile.txt")
  #
  # Export in <tt>File.open</tt> block
  #   File.open("myfile.txt", "w") { |f| resource.export(f) }
  #
  # Read contents from resource
  #   File.open("myfile.txt", "w") { |f| f.write(resource.read) }
  #
  # <tt>concat</tt> is an alias to <tt>read(:inline_dependencies => true, :recursive => true)</tt>
  #   File.open("myfile.txt", "w") { |f| f.write(resource.concat) }
  #
  # Of course, any IO stream is acceptable
  #   resource.export(StringIO.new)
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  module Concat

    #
    # Reads the contents of the resource. By default only the content of the
    # resource is read out. The <tt>:inline_dependencies</tt> option can be
    # provided to concatenate all dependencies and produce the full listing. In
    # this case any dependency statements are removed from the resulting string, to
    # avoid loading/depending on dependencies twice.
    #
    def read(options = {})
      contents = ""

      if options[:inline_dependencies]
        dependencies(options).each { |dep| contents << dep.read }
      end

      contents << io.open { |stream| stream.rewind && stream.read }
    end

    #
    # Export the contents to an output. The output is wrapped in a
    # <tt>Juicer::IOProxy</tt> object, meaning you can provide it any one of the
    # inputs <tt>Juicer::IOProxy.new</tt> accepts. The options hash is passed to
    # #read, refer to its documentation for possible options to provide. If a
    # string is passed to #export, it is used as a file name (i.e., if you want
    # to write to a string, pass a StringIO instance).
    #
    def export(stream_like, options = {})
      if stream_like.is_a?(String)
        FileUtils.touch(stream_like)
      end

      Juicer::IOProxy.open(stream_like, "w+") { |ios| ios.write(read(options)) }
    rescue ArgumentError => err
      raise ArgumentError.new("Invalid stream argument, #{stream_like}: #{err.message}")
    end

    #
    # Concatenates the resource with all dependencies and returns a new instance
    # with the full listing as its contents. Equivalent to calling
    # <tt>Resource.new(read(:inline_dependencies => true, :recursive => true))</tt>
    # In contrast to <tt>dependencies</tt>, <tt>concat</tt> defaults to
    # <tt>:recursive => true</tt>, i.e., include all nested dependencies, not
    # just direct ones.
    #
    def concat(options = {})
      self.class.new(read(options.merge(:inline_dependencies => true, :recursive => true)))
    end
  end
end
