# -*- coding: utf-8 -*-

require "juicer/io_proxy_wrapper"
require "juicer/dependency_resolver"
require "juicer/concat"
require "juicer/logger"

module Juicer
  #
  # Interface with new and existing JavaScript files. The API can be
  # used to import all dependencies and export the resulting JS to a new file
  # or IO stream. This result can then be fed to a compressor for compact
  # results.
  #
  # = Examples
  #
  # Create a new JavaScript object (ie, not referring to an existing file on
  # disk)
  #   javascript = Juicer::JavaScript.new
  #
  # Same as <tt>// @depend myfile.js</tt> from a JavaScript file: depend on
  # another JavaScript resource.
  #   javascript.depend(Juicer::JavaScript.new("myfile.js"))
  #
  # You can depend on the file directly, Juicer will wrap it in a
  # <tt>Juicer::JavaScript</tt> object for you
  #   javascript.depend("myfile.js")
  #
  # <tt><<</tt> is an alias to depend
  #   javascript << "myfile.js"
  #
  # List all dependencies
  #   javascript.dependencies #=> [#<Juicer::JavaScript:"myfile.js">]
  #
  # List all resources. This includes self in the list:
  #   javascript.resources    #=> [#<Juicer::JavaScript:[unsaved]>, #<Juicer::JavaScript:"myfile.js">]
  #
  # Export the JavaScript resource to a file. Will include <tt>@depend</tt> statements
  # for any dependencies (meaning they won't be loaded, since <tt>@depend</tt>
  # is just a construct only meaningful to Juicer)
  #   file = File.open("myfile.js", "w")
  #   javascript.export(file)
  #   file.close
  #
  # If you'd rather include the contents of the dependencies inline you can
  # specify the <tt>:inline_dependencies = true</tt> option:
  #   javascript.export(file, :inline_dependencies => true)
  #
  # There are a few alternative ways to export contents:
  #
  # Write to open file handler
  #   File.open("myfile.js", "w")
  #   javascript.export(file)
  #   file.close
  #
  # Export to filename, analogous to above example
  #   javascript.export("myfile.js")
  #
  # Export in <tt>File.open</tt> block
  #   File.open("myfile.js", "w") { |f| javascript.export(f) }
  #
  # Read contents from JavaScript resource
  #   File.open("myfile.js", "w") { |f| f.write(javascript.read) }
  #
  # <tt>concat</tt> is an alias to <tt>read(:inline_dependencies => true)</tt>
  #   File.open("myfile.js", "w") { |f| f.write(javascript.concat) }
  #
  # Of course, any IO stream is acceptable
  #   javascript.export(StringIO.new)
  #
  # Wrap an existing JavaScript resource in a <tt>Juicer::JavaScript</tt> instance
  #   javascript = Juicer::JavaScript.new("myfile.js")
  #   javascript.dependencies # Lists all @import'ed files (recursively) as Juicer::JavaScript objects
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  class JavaScript
    include Juicer::IOProxyWrapper
    include Juicer::DependencyResolver
    include Juicer::Concat
    include Juicer::Loggable

    protected
    def scan_for_dependencies(line)
      @inside_comment = false if @inside_comment.nil?
      previous = nil
      comment = ""
      word = ""
      one_line_comment = false

      line.split("").each do |char|
        word = "#{previous}#{char}"
        @inside_comment = true if word == "/*"
        one_line_comment = true if word == "//"
        @inside_comment = false if word == "*/"
        comment << char if @inside_comment || one_line_comment
        throw(:done) if !@inside_comment && !one_line_comment && char !~ /[\s\/]/
        previous = char
      end

      matches = /\@depends?\s+([^\s\'\"\;]+)/im.match(comment)
      return matches[1] if matches
    end
  end
end
