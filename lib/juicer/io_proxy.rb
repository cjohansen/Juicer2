# -*- coding: utf-8 -*-

require "juicer"
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
    attr_reader :stream, :path, :dir

    #
    # Creates a new Juicer::IOProxy. Accepts strings, IO streams and file names.
    # If no argument is provided, the IOProxy will wrap a StringIO
    #
    def initialize(stream_like = nil, mode = "r+", dir = nil)
      @mode = mode || "r+"
      @path = nil
      @dir = nil

      if stream_like.nil?
        @stream = StringIO.new("", @mode)
      elsif is_file?(stream_like, dir)
        @path = stream_like
        @dir = dir
        @stream = nil
      elsif stream_like.respond_to?(:read)
        @stream = stream_like
      elsif stream_like.is_a?(String)
        @stream = StringIO.new(stream_like, @mode)
      else
        raise ArgumentError.new("IOProxy should wrap a string, io object or file, got #{stream_like.class}")
      end
    end

    #
    # Yields an io object
    #
    def open
      if !@path.nil?
        @stream = File.open(file, @mode)
      end

      results = nil

      begin
        results = yield @stream if block_given?
      ensure
        if !@path.nil?
          @stream.close
          @stream = nil
        end
      end

      results
    end

    def self.open(stream_like, mode = nil, &block)
      ios = self.new(stream_like, mode)
      ios.open(&block)
    end

    def file
      return nil if @path.nil?
      File.expand_path(@dir.nil? ? @path : File.join(@dir, @path))
    end

    def inspect
      "Juicer::IOProxy<#{@path || @stream}>"
    end

    def to_s
      inspect
    end

    def ==(other)
      return file == other.file if !file.nil? && other.respond_to?(:file)
      other.respond_to?(:stream) && !stream.nil? && stream == other.stream
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
      path = nil

      if ios.is_a?(String) && ios !~ /\n/
        path = load_path.find { |path| File.exists?(File.join(path, ios)) }
        return Juicer::IOProxy.new(ios, nil, path) unless path.nil?
      end

      Juicer::IOProxy.new(ios)
    rescue ArgumentError => err
      raise err
    end

    private
    def is_file?(stream_like, dir = nil)
      path = dir.nil? ? stream_like : File.join(dir, stream_like)
      stream_like.is_a?(String) && stream_like !~ /\n/ && File.exists?(File.expand_path(path))
    end
  end
end
