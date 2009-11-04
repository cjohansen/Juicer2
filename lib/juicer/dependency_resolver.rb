# -*- coding: utf-8 -*-

require "juicer/io_proxy"
require "fileutils"

module Juicer
  #
  # Provides dependency resolution for linked files. To include the module in a
  # class, the class needs to provide an io accessor which should return an
  # object with an <tt>open</tt> method that yields an IO stream.
  #
  # = Overview
  #
  # Given an class <tt>Resource</tt> (and instance <tt>resource</tt>) that
  # includes the module, these are the methods provided.
  #
  # Depend on another resource.
  #   resource.depend(Resource.new("myfile"))
  #
  # You can depend on the file directly, Juicer will wrap it in an instance of
  # the including class (e.g. <tt>Resource</tt> in this example) for you
  #   resource.depend("myfile.txt")
  #
  # <tt><<</tt> is an alias for depend
  #   resource << "myfile.txt"
  #
  # List all dependencies
  #   resource.dependencies #=> [#<Resource:"myfile.txt">]
  #
  # List all resources. This includes self in the list:
  #   resource.resources #=> [#<Juicer::Resource:[unsaved]>, #<Juicer::Resource:"myfile.txt">]
  #
  # Wrap an existing CSS resource in a <tt>Juicer::CSS</tt> instance
  #   css = Juicer::CSS.new("myfile.css")
  #   css.dependencies # Lists all @import'ed files (recursively) as Juicer::CSS objects
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  module DependencyResolver

    #
    # Lists all dependencies, either added in through the depend method, or
    # through dependency statements in the source content. The method accepts an
    # options hash which can specify the <tt>:recursive</tt> option. If
    # <tt>true</tt>, all nested dependencies will be load. The default value is
    # <tt>false</tt>, producing a list of files directly depended on by the
    # resource. Dependencies are returned as an array of instances of the class
    # including the module. Files are resolved through <tt>Juicer::IOProxy</tt>,
    # meaning they can exist anywhere on <tt>Juicer.load_path</tt>, not
    # necessarily in the current directory.
    #
    def dependencies(options = {})
      options = { :recursive => false }.merge(options)
      @_deps = []
      @_ios = []
      content_dependencies(io, options[:recursive]).concat(@dependencies || [])
    end

    #
    # Lists all instances that make up this resource, including this instance.
    # The options hash is passed to #dependencies, refer to its documentation
    # for possible options.
    #
    def resources(options = {})
      dependencies(options) + [self]
    end

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
      read(options.merge(:inline_dependencies => true, :recursive => true))
    end

    #
    # Add a dependency. Accepts instances of the including class,
    # <tt>Juicer::IOProxy</tt> instances, or any other input accepted by
    # <tt>Juicer::IOProxy.new</tt>, i.e., file names, string content or io
    # streams. If the including class implements an <tt>open</tt> class method,
    # it is used to resolve the resource to add. Otherwise, <tt>#new</tt> is
    # called directly.
    #
    def depend(resource)
      klass = self.class
      @dependencies ||= []
      @dependencies.push(klass.respond_to?(:open) ? klass.open(resource) : klass.new(resource))
    end

    alias << depend

    #
    # Two instances are equal if they share the same <tt>Juicer::IOProxy</tt>
    # object as well as all dependencies
    #
    def ==(other)
      return false if io != other.io
      dependencies == other.dependencies
    end

    private
    def content_dependencies(source, recursive)
      source.open do |stream|
        stream.rewind
        line_num = 0

        catch(:done) do
          while !stream.eof?
            line = stream.readline

            begin
              result = scan_for_dependencies(line)

              if result
                io = Juicer::IOProxy.load(result)
                content_dependencies(io, recursive) if !@_ios.include?(io) && recursive

                if !@_ios.include?(io)
                  @_ios.push(io)
                  @_deps.push(self.class.new(io))
                end
              end
            rescue RegexpError => err
              log.error "Encountered an error when extracting dependencies from #{source}:#{line_num}:\n#{line.strip}\n\n" +
                "This might indicate a syntax error or possibly a bug in Juicer. Please investigate."
            end

            line_num += 1
          end
        end
      end

      @_deps
    end
  end
end
