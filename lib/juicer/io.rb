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
          stream = @file.open(@mode)
          return stream.send(name, args, &block)
        rescue Exception => err
          raise err
        ensure
          stream.close unless stream.closed?
        end
      end

      super
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
  end
end
