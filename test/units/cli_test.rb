# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/cli"

class CliTest < Test::Unit::TestCase
  context "creating new cli objects" do
    should "set logger level to info when verbose option is set" do
      cli = Juicer::Cli.new(%w{-v})

      assert_equal Juicer.log, cli.log
      assert_equal Logger::INFO, cli.log.level
    end

    should "set logger level to debug when debug option is set" do
      cli = Juicer::Cli.new(%w{-d})

      assert_equal Juicer.log, cli.log
      assert_equal Logger::DEBUG, cli.log.level
    end

    should "set logger level to error when silent option is set" do
      cli = Juicer::Cli.new(%w{-s})

      assert_equal Juicer.log, cli.log
      assert_equal Logger::ERROR, cli.log.level
    end
    
    should "set logger level default warn level" do
      cli = Juicer::Cli.new([])

      assert_equal Juicer.log, cli.log
      assert_equal Logger::WARN, cli.log.level
    end
  end

  context "input arguments" do
    setup do
      @files = ["file1.js", "file2.css"]
      @files.each { |f| FileUtils.touch(f) }
    end

    teardown do
      @files.each { |f| File.delete(f) }
    end

    should "not raise exception if input is nil" do
      assert_nothing_raised do
        Juicer::Cli::InputArgs.new
      end
    end

    should "not raise exception if input is existing files" do
      assert_nothing_raised do
        Juicer::Cli::InputArgs.new(@files)
      end
    end

    should "not raise exception if input is single existing file" do
      assert_nothing_raised do
        Juicer::Cli::InputArgs.new(@files[0])
      end
    end

    should "raise exception if input is single non-existent file" do
      assert_raise ArgumentError do
        Juicer::Cli::InputArgs.new("somefile.js")
      end
    end

    should "raise exception if a single input is non-existent file" do
      assert_raise ArgumentError do
        Juicer::Cli::InputArgs.new(@files[0], @files[1], "somefile.js")
      end
    end

    should "list inputs as an array IOProxy objects" do
      input = Juicer::Cli::InputArgs.new(@files[0], @files[1])

      assert_equal @files.collect { |f| Juicer::IOProxy.new(f) }, input.to_a
    end

    should "wrap stdin in an array of a single IOProxy object without input" do
      input = Juicer::Cli::InputArgs.new

      assert_equal [$stdin], input.to_a.collect { |i| i.stream }
    end

    should "wrap stdin in an array of a single IOProxy object with nil input" do
      input = Juicer::Cli::InputArgs.new(nil)

      assert_equal [$stdin], input.to_a.collect { |i| i.stream }
    end
    
    should "use first file in list to guess type" do
      input = Juicer::Cli::InputArgs.new(@files)

      assert_equal "js", input.type
    end
  end
end
