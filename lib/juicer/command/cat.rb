# -*- coding: utf-8 -*-

require "juicer/cli"
require "juicer/io_proxy"
require "fileutils"

module Juicer
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  module Command
    class Cat
      include Juicer::Loggable
      attr_reader :output, :type
      DESC = "Resolve dependencies and concatenate files"

      def initialize(args = nil)
        args = args.split(" ") if args.is_a?(String)

        opts = Trollop::options(args || []) do
          banner DESC
          opt :output, "File to write concatenated contents to", :default => nil, :type => :string
          opt :type, "css or javascript. Not necessary to specify when using files", :default => nil, :type => :string
        end

        @output = opts[:output] || $stdout
        @type = opts[:type]
      end

      def execute(args = nil)
        input = Juicer::Cli::InputArgs.new(args)
        type = @type || input.type == "js" ? ["javascript", "JavaScript"] : ["css", "CSS"]
        asset = Juicer.load_lib(*type).new(input.to_a)
        asset.export(@output, :inline_dependencies => true)
      end
    end
  end
end
