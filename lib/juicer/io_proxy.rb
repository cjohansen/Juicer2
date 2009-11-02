require "stringio"

module Juicer
  #
  # Wraps strings, IO streams and files (i.e., file names as strings) and
  # provides a uniform API to interact with them.
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  class IOProxy
    attr_reader :file

    #
    # Creates a new Juicer::IOProxy. Accepts strings, IO streams and file names.
    # If no argument is provided, the IOProxy will wrap a StringIO
    #
    def initialize(stream_like = nil, mode = "r+")
      @mode = mode || "r+"
      @file = nil

      if stream_like.nil?
        @stream = StringIO.new("", @mode)
      elsif stream_like.is_a?(String) && File.exists?(stream_like)
        @file = stream_like
        @stream = nil
      elsif stream_like.respond_to?(:read)
        @stream = stream_like
      else
        @stream = StringIO.new(stream_like, @mode)
      end
    end

    def open
      if !@file.nil?
        @stream = File.open(@file, @mode)
      end

      results = nil

      begin
        results = yield @stream if block_given?
      ensure
        @stream.close
      end

      results
    end

    def self.open(stream_like, mode = nil, &block)
      ios = self.new(stream_like, mode)
      ios.open(&block)
    end

    def inspect
      "Juicer::IOProxy<#{@file || @stream}>"
    end

    #
    # Loads a Juicer::IOProxy object. If the provided input is a string it's treated
    # as a file name, and #load looks for the file on disk. The file may appear
    # anywhere on disk, and you can specify the paths where Juicer should look
    # through the load path argument. The load path should be an array of places
    # to look. If no load path is provided, <tt>Juicer.load_path</tt>, the
    # default load path for Juicer, is used. If you want to search your own
    # directories first, then Juicer's, you need to set this up yourself:
    #
    #   load_path = ["my/lib", "/usr/local/share/juicer"] + Juicer.load_path
    #   css = Juicer::Css.new(Juicer::IOProxy.load("shiny.css", load_path))
    #
    # #load returns the first match it finds.
    #
    # [<tt>ios</tt>] An IO stream, a string or a file name
    # [<tt>load_path</tt>] Array of paths to look for files if <tt>ios</tt> is
    #                      "file name-like"
    #
    def self.load(ios, load_path = nil)
      return ios if ios.is_a?(Juicer::IOProxy)
      load_path ||= Juicer.load_path

      if ios.is_a?(String) && !load_path.nil?
        path = load_path.find { |path| File.exists?(File.join(path, ios)) }
        ios = File.join(path, ios) unless path.nil?
      end

      Juicer::IOProxy.new(ios)
    end
  end
end
