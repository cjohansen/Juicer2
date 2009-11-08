# -*- coding: utf-8 -*-

require "juicer/cli"
require "juicer/io_proxy"

module Juicer
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  module Command
    class Concat
      include Juicer::Loggable

      def initialize(args = nil)
        opts = Trollop::options(args) do
          banner "Resolve dependencies and concatenate files"
          opt :output, "File to write concatenated contents to", :default => nil, :type => :string
          opt :type, "css or javascript. Not necessary to specify when using files", :default => "css"
        end

        @output = Juicer::IOProxy.new(opts[:output] || $stdout, "w")
        @type = opts[:type]
        @files = args
      end

      def execute
        input = Juicer::Cli.file_input(args)
        asset = Juicer.load_lib(input.type).new(input.to_a)
        asset.export(@output, :inline_dependencies => true)
      end
    end
  end
end
