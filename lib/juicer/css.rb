require "juicer/io"

module Juicer
  #
  # Interface with new and existing CSS files. The API can be
  # used to import all dependencies and export the resulting CSS to a new file
  # or IO stream. This result can then be fed to a compressor for compact
  # results.
  #
  # <tt>Juicer::Css</tt> supports several custom observation points, where
  # you can insert custom modules to process CSS as it's being moved between
  # files, merged and compressed.
  #
  # = Examples
  #
  # Create a new CSS object (ie, not referring to an existing file on disk)
  #   css = Juicer::Css.new
  #
  # Same as <tt>@import url(myfile.css);</tt> from a CSS file: depend on another
  # CSS resource.
  #   css.depend Juicer::Css.new("myfile.css")
  #
  # You can depend on the file directly, Juicer will wrap it in a
  # <tt>Juicer::Css</tt> object for you
  #   css.depend "myfile.css"
  #
  # <tt>import</tt> is an alias for <tt>depend</tt>
  #   css.import "myfile.css"
  #
  # ...as is <tt>&lt;&lt;</tt>
  #   css << "myfile.css"
  #
  # List all dependencies
  #   css.dependencies #=> [#<Juicer::Css:"myfile.css">]
  #
  # List all resources. This includes self in the list:
  #   css.resources    #=> [#<Juicer::Css:[unsaved]>, #<Juicer::Css:"myfile.css">]
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
  # Wrap an existing CSS resource in a <tt>Juicer::Css</tt> instance
  #   css = Juicer::Css.new("myfile.css")
  #   css.dependencies # Lists all @import'ed files (recursively) as Juicer::Css objects
  #
  # Add an observer to the concat operation. Adds cache busters to all URLS,
  # one Css resource at a time
  #   css.observe :before_concat, Juicer::CssCacheBuster.new
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  class Css
    # attr_reader :io

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
      @dependencies = nil
      @added_dependencies = []

      if args[-1].is_a?(Hash)
        @options.merge!(args.pop)
      end

      if args.length > 1
        @io = Juicer::IO.new
        self.import(Juicer::Css.new(args.shift)) while args.length > 0
      else
        @io = Juicer::IO.new(args[0])
      end
    end

    #
    # Lists all dependencies, either added in through the dependency Api, or
    # through @import statements in the CSS content.
    #
    def dependencies
      return @dependencies unless @dependencies.nil?
      @dependencies = @added_dependencies + []
    end

    def resources
      [file] + dependencies
    end

    def read(options = {})
      @io.read
    end

    def export(stream_like, options = {})
      Juicer::IO.open(stream_like, "w") { |ios| ios.write(read(options)) }
    end

    def concat(options = {})
      read(options.merge(:inline_dependencies => true))
    end

    def depend(resource)
      @added_dependencies.push(Juicer::Css.open(resource))
    end

    alias << depend
    alias import depend

    def inspect
      filename = file.nil? ? "[unsaved]" : "\"#{file}\""
      "#<#{self.class}:#{filename}>"
    end

    def self.open(stream_like)
      return stream_like if stream_like.is_a?(Juicer::Css)
      Juicer::Css.new(stream_like)
    end
  end
end
