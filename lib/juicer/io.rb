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
  class IO
    #
    # Creates a new Juicer::IO. Accepts strings, IO streams and file names.
    # If no argument is provided, the IO will wrap a StringIO
    #
    def initialize(stream_like = nil, mode = "r+")
      @mode = mode || "r+"
      @file = nil

      if stream_like.nil?
        @stream = StringIO.new("", mode)
      elsif stream_like.is_a?(String) && File.exists?(stream_like)
        @file = stream_like
        @stream = nil
      elsif stream_like.respond_to?(:read)
        @stream = stream_like
      else
        @stream = StringIO.new(stream_like, @mode)
      end
    end

    def method_missing(name, *args, &block)
      return @stream.send(name, *args, &block) if @stream

      stream = nil

      if @file
        begin
          stream = File.open(@file, @mode)
          stream.send(name, *args, &block)
        rescue Exception => err
          raise err
        ensure
          stream.close
        end
      else
        super
      end
    end

    def inspect
      "Juicer::IO<#{@file || @stream}>"
    end

    def self.open(stream_like, mode = nil)
      ios = self.new(stream_like, mode)
      results = nil

      begin
        results = yield ios if block_given?
      ensure
        ios.close unless ios.closed?
      end

      results
    end

    #
    # Loads a Juicer::IO object. If the provided input is a string it's treated
    # as a file name, and #load looks for the file on disk. The file may appear
    # anywhere on disk, and you can specify the paths where Juicer should look
    # through the load path argument. The load path should be an array of places
    # to look. If no load path is provided, <tt>Juicer.load_path</tt>, the
    # default load path for Juicer, is used. If you want to search your own
    # directories first, then Juicer's, you need to set this up yourself:
    #
    #   load_path = ["my/lib", "/usr/local/share/juicer"] + Juicer.load_path
    #   css = Juicer::Css.new(Juicer::IO.load("shiny.css", load_path))
    #
    # #load returns the first match it finds.
    #
    # [<tt>ios</tt>] An IO stream, a string or a file name
    # [<tt>load_path</tt>] Array of paths to look for files if <tt>ios</tt> is
    #                      "file name-like"
    #
    def self.load(ios, load_path = Juicer.load_path)
      if ios.is_a?(String) && !load_path.nil?
        path = load_path.find { |path| File.exists?(File.join(path, ios)) }
        ios = File.join(path, ios) unless path.nil?
      end

      Juicer::IO.new(ios)
    end
  end
end
