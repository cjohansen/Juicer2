# -*- coding: utf-8 -*-

require "juicer/io_proxy_wrapper"
require "juicer/dependency_resolver"
require "juicer/concat"
require "juicer/logger"

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
  # ...as is <tt><<</tt>
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
    include Juicer::IOProxyWrapper
    include Juicer::DependencyResolver
    include Juicer::Concat
    include Juicer::Loggable

    alias import depend

    protected
    def scan_for_dependencies(line)
      @inside_comment = false if @inside_comment.nil?
      line = line.gsub(%r[/\*.*\*/], "")

      previous = nil
      line.split("").each do |char|
        @inside_comment = true if "#{previous}#{char}" == "/*"
        @inside_comment = false if "#{previous}#{char}" == "*/"
        previous = char
      end

      if !@inside_comment
        line.sub!(%r[.*\*/], "")
        matches = /^\s*@import(?:\s+url\(|\s+)?(['"]?)([^\?'"\)\s]+)(\?[^'"\)]*)?\1\)?(?:[^?;]*);?/im.match(line)
        return matches[2] if matches
      end
      
      throw(:done) if !@inside_comment && line =~ /^\s*[\.\#a-zA-Z\:]/
    end
  end
end
