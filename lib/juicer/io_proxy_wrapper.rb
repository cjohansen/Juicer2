# -*- coding: utf-8 -*-

require "juicer/io_proxy"

module Juicer
  #
  # Stub implementation of a resource backed by a <tt>Juicer::IOProxy</tt>
  # object.
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  module IOProxyWrapper
    attr_reader :io

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    #
    # Creates a new resource. Accepts a wide variety of input options:
    # * A file name of an existing file
    # * An io object
    # * A string of content
    # * Nothing - creates a new empty resource
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
        self.import(self.class.new(args.shift, @options)) while args.length > 0
      else
        @io = Juicer::IOProxy.load(args[0], @options[:load_path])
      end
    rescue ArgumentError
      raise ArgumentError.new(<<-MSG)
      Argument(s) to #{self.class}#new needs to be one of: Juicer::IOProxy instance,
      a string, a file name or an IO object.
      MSG
    end

    #
    # Purdy string representation of a resource
    #
    def inspect
      filename = file.nil? ? "[unsaved]" : "\"#{file}\""
      "#<#{self.class}:#{filename}>"
    end

    #
    # Returns the name of the file the resource wraps, if any. If the resource
    # does not wrap a file (i.e., it's an io stream, or string), the method
    # returns <tt>nil</tt>.
    #
    def file
      io.file
    end

    #
    # Returns the relative path to the file the resource wraps, if any. If the
    # resource does not wrap a file (i.e., it's an io stream, or string), the
    # method returns <tt>nil</tt>.
    #
    def path
      io.path
    end

    module ClassMethods
      #
      # Open an instance. If input is already an instance of the including class,
      # it is returned directly. Otherwise, the input is passed directly to
      # <tt>#new</tt>. In either case, a new instance of the including class is
      # returned.
      #
      def open(stream_like)
        return stream_like if stream_like.is_a?(self)
        self.new(stream_like)
      rescue ArgumentError => err
        raise err
      end
    end
  end
end
