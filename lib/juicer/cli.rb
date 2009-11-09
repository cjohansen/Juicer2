# -*- coding: utf-8 -*-

require "juicer"
require "juicer/logger"
require "juicer/command"
require "juicer/io_proxy"
require "trollop"

module Juicer
  #
  # Defines the Juicer command line interface. Parses command line options and
  # executes the given command.
  #
  # Usage is just like the actual command line, you can pass arguments as an
  # array or a string:
  #   Juicer::Cli.new("-v concat file1.js file2.s").execute
  #   Juicer::Cli.new(%w[-v concat file1.js file2.s]).execute
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  class Cli
    include Juicer::Loggable
    attr_reader :cmd

    #
    # Initialize the command line interface. Parses command line options and
    # preloads the command class. See the <tt>Juicer::Command</tt> class for
    # information about command loading.
    #
    # Accepts a single argument - a string or array of options, which defaults
    # to <tt>ARGV</tt>
    #
    def initialize(args = ARGV)
      args = args.split(" ") if args.is_a?(String)

      opts = Trollop::options(args) do
        banner "CSS and JavaScript dependency resolution, file concatenation and general utility belt"
        opt :verbose, "Be more informative", :default => false
        opt :debug, "Log debug information", :default => false
        opt :silent, "Only log errors", :default => false
        stop_on Juicer::Command.list
      end

      log.level = opts[:silent] && Logger::ERROR ||
                    opts[:debug] && Logger::DEBUG ||
                      opts[:verbose] && Logger::INFO ||
                        Logger::WARN

      klass = Juicer::Command.load(args.shift)
      @cmd = klass.new(args) unless klass.nil?
      @args = args
    end

    #
    # Execute the command. Catches all kinds of exceptions and handles them in
    # a human understandable way.
    #
    def execute
      if @cmd.nil?
        log.warn("No command given, nothing to do") and exit
      end

      @cmd.execute(@args)
    end

    class InputArgs
      def initialize(*args)
        @files = args.flatten.reject { |f| f.nil? }.collect do |f|
          raise ArgumentError.new("Input file #{f} does not exist") if !File.exists?(f)
          Juicer::IOProxy.new(f)
        end
      end

      def type
        @files.first && @files.first.file.split(".").pop
      end

      def to_a
        @files.length > 0 ? @files : [Juicer::IOProxy.new($stdin)]
      end
    end
  end
end
