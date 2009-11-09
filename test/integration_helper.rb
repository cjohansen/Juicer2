# -*- coding: utf-8 -*-

begin
  require 'test/unit'
  require 'shoulda'
  require 'open-uri'
rescue LoadError => err
  puts "To run the Juicer integration test suite you need Test::Unit, shoulda, and open-uri"
  puts err
  exit
end

if RUBY_VERSION < "1.9"
  begin
    require "redgreen"
  rescue LoadError => err
    puts "Install the redgreen gem if you want colored output from tests"
  end
end

require 'fileutils'
require 'stringio'
require 'juicer'
require 'juicer/logger'

Juicer.log = Logger.new(StringIO.new)

module Juicer
  module Test
    def self.home
      @@home ||= "__integration_test"
    end

    def self.setup_testfs
      Dir.mkdir(self.home)
    end

    def self.teardown_testfs
      FileUtils.rm_rf(self.home)
    end

    def self.file_list(*files)
      files.flatten.collect { |file| self.file(file) }
    end

    def self.file(file)
      File.join(self.home, file)
    end

    def self.write(filename, contents)
      FileUtils.mkdir_p(File.dirname(filename)) unless File.exists?(File.dirname(filename))
      File.open(filename, "w") { |f| f.puts(contents) }
      contents
    end

    module Helpers
      def fake_stdin(contents)
        stdin = $stdin
        $stdin = StringIO.new
        $stdin.write(contents) && $stdin.rewind
        yield
        $stdin = stdin
      end

      def capture_stdout
        stdout = $stdout
        $stdout = StringIO.new
        yield
        results = $stdout.rewind && $stdout.read
        $stdout = stdout
        results
      end
    end
  end
end

include Juicer::Test::Helpers
