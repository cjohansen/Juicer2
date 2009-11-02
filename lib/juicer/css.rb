require "juicer/io_proxy"

module Juicer
  #
  # Interface with new and existing CSS files. The API can be
  # used to import all dependencies and export the resulting CSS to a new file
  # or IO stream. This result can then be fed to a compressor for compact
  # results.
  #
  # <tt>Juicer::CSS</tt> supports several custom observation points, where
  # you can insert custom modules to process CSS as it's being moved between
  # files, merged and compressed.
  #
  # = Examples
  #
  # Create a new CSS object (ie, not referring to an existing file on disk)
  #   css = Juicer::CSS.new
  #
  # Same as <tt>@import url(myfile.css);</tt> from a CSS file: depend on another
  # CSS resource.
  #   css.depend Juicer::CSS.new("myfile.css")
  #
  # You can depend on the file directly, Juicer will wrap it in a
  # <tt>Juicer::CSS</tt> object for you
  #   css.depend "myfile.css"
  #
  # <tt>import</tt> is an alias for <tt>depend</tt>
  #   css.import "myfile.css"
  #
  # ...as is <tt>&lt;&lt;</tt>
  #   css << "myfile.css"
  #
  # List all dependencies
  #   css.dependencies #=> [#<Juicer::CSS:"myfile.css">]
  #
  # List all resources. This includes self in the list:
  #   css.resources    #=> [#<Juicer::CSS:[unsaved]>, #<Juicer::CSS:"myfile.css">]
  #
  # Export the CSS resource to a file. Will include <tt>@import</tt> statements
  # for any dependencies
  #   file = File.open("myfile.css", "w")
  #   css.export(file)
  #   file.close
  #
  # If you'd rather include the contents of the dependencies inline you can
  # specify the <tt>:inline_dependencies = true</tt> option:
  #   css.export(file, :inline_dependencies => true)
  #
  # There are a few alternative ways to export contents:
  #
  # Write to open file handler
  #   File.open("myfile.css", "w")
  #   css.export(file)
  #   file.close
  #
  # Export to filename, analogous to above example
  #   css.export("myfile.css")
  #
  # Export in <tt>File.open</tt> block
  #   File.open("myfile.css", "w") { |f| css.export(f) }
  #
  # Read contents from CSS resource
  #   File.open("myfile.css", "w") { |f| f.write(css.read) }
  #
  # <tt>concat</tt> is an alias to <tt>read(:inline_dependencies => true)</tt>
  #   File.open("myfile.css", "w") { |f| f.write(css.concat) }
  #
  # Of course, any IO stream is acceptable
  #   css.export(StringIO.new)
  #
  # Wrap an existing CSS resource in a <tt>Juicer::CSS</tt> instance
  #   css = Juicer::CSS.new("myfile.css")
  #   css.dependencies # Lists all @import'ed files (recursively) as Juicer::CSS objects
  #
  # Add an observer to the concat operation. Adds cache busters to all URLS,
  # one CSS resource at a time
  #   css.observe :before_concat, Juicer::CSSCacheBuster.new
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  class CSS
    #
    # Creates a new CSS resource. Accepts a wide variety of input options:
    # * A file name of an existing CSS file
    # * An io object
    # * A string of CSS content
    # * Nothing - creates a new empty CSS resource
    #
    # Additionally, you may provide an array with a mix of the above, or several
    # arguments, also mixing the above. In any case you can provide an options
    # hash as the last argument
    #
    def initialize(*args)
      args.flatten!
      @options = {}
      @dependencies = []

      if args[-1].is_a?(Hash)
        @options.merge!(args.pop)
      end

      if args.length > 1
        @io = Juicer::IOProxy.new
        self.import(Juicer::CSS.new(args.shift, @options)) while args.length > 0
      else
        @io = Juicer::IOProxy.load(args[0], @options[:load_path])
      end
    end

    #
    # Lists all dependencies, either added in through the dependency Api, or
    # through @import statements in the CSS content. The method accepts an
    # options hash which can specify the <tt>:recursive</tt> option. If
    # <tt>true</tt>, all nested dependencies will be load. The default value is
    # <tt>false</tt>, producing a list of files directly depended on by the
    # resource. Dependencies are returned as an array of <tt>Juicer::CSS</tt>
    # objects. Files are resolved through <tt>Juicer::IOProxy</tt>, meaning they
    # can exist anywhere on <tt>Juicer.load_path</tt>, not necessarily in the
    # current directory.
    #
    # If a block is given, each dependency is yielded to the block. The block
    # may exclude certain dependencies by returning false. Any non-false return
    # value from the block includes the file in the returned collection.
    #
    def dependencies(options = {})
      # @io.open do |stream|
      #   while !stream.eof?
        
      #   end
      # end

      dependencies = []
      dependencies = @dependencies
    end

    #
    # Lists all <tt>Juicer::CSS</tt> instances that make up this resource,
    # including this instance. The options hash is passed to #dependencies,
    # refer to its documentation for possible options.
    #
    def resources(options = {})
      [self] + dependencies(options)
    end

    #
    # Reads the contents of the CSS resource. By default only the content of
    # the resource is read out. The <tt>:inline_dependencies</tt> option can be
    # provided to concatenate all dependencies and produce the full listing. In
    # this case any @import statements are removed from the resulting string, to
    # avoid loading dependencies twice.
    #
    def read(options = {})
      @io.open { |stream| stream.read }
    end

    #
    # Export the CSS contents to an output. The output is wrapped in a
    # <tt>Juicer::IOProxy</tt> object, meaning you can provide it any one of the
    # inputs <tt>Juicer::IOProxy.new</tt> accepts. The options hash is passed to
    # #read, refer to its documentation for possible options to provide.
    #
    def export(stream_like, options = {})
      Juicer::IOProxy.open(stream_like, "w") { |ios| ios.write(read(options)) }
    end

    #
    # Concatenates the CSS resource with all dependencies and returns the full
    # listing. Equivalent to calling <tt>read(:inline_dependencies => true)</tt>
    #
    def concat(options = {})
      read(options.merge(:inline_dependencies => true))
    end

    #
    # Add a dependency. Accepts <tt>Juicer::CSS</tt> instances,
    # <tt>Juicer::IOProxy</tt> instances, or any other input accepted by
    # <tt>Juicer::IOProxy.new</tt>, i.e., file names, string content or io streams.
    #
    def depend(resource)
      @dependencies.push(Juicer::CSS.open(resource))
    end

    alias << depend
    alias import depend

    #
    # Purdy string representation of a CSS resource
    #
    def inspect
      filename = file.nil? ? "[unsaved]" : "\"#{file}\""
      "#<#{self.class}:#{filename}>"
    end

    #
    # Returns the name of the file the CSS resource wraps, if any. If the
    # resource does not wrap a file (i.e., it's an io stream, or CSS string),
    # the method returns <tt>nil</tt>.
    #
    def file
      @io.file
    end

    #
    # Open a <tt>Juicer::CSS</tt> instance. If input is already a
    # <tt>Juicer::CSS</tt> instance, it is returned directly. Otherwise, the
    # input is passed directly to <tt>Juicer::CSS.new</tt>. In either case, a
    # <tt>Juicer::CSS</tt> instance is returned.
    #
    def self.open(stream_like)
      return stream_like if stream_like.is_a?(Juicer::CSS)
      Juicer::CSS.new(stream_like)
    end
  end
end
