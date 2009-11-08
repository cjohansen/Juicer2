# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/command/concat"

class ConcatCommandTest < Test::Unit::TestCase
  context "initializing concat command" do
    setup do
      @file = "out.js"
      @type = "css"
    end

    teardown do
      File.delete(@file) if File.exists?(@file)
    end

    should "accept output and type options" do
      cmd = nil

      assert_nothing_raised do
        cmd = Juicer::Command::Concat.new("--output #{@file} --type=#{@type}")
      end
    end

    should "set type to specified type" do
      cmd = Juicer::Command::Concat.new(%w[--type js])

      assert_equal "js", cmd.type
    end

    should "accept output and type short options" do
      assert_nothing_raised do
        cmd = Juicer::Command::Concat.new("-o #{@file} -t #{@type}")
      end
    end

    should "wrap stdout if no output is given" do
      cmd = Juicer::Command::Concat.new

      assert_equal $stdout, cmd.output
    end
  end

  context "concatenating files" do
    setup do
      @files = ["file1.js", "file2.js"]
      @output = "out.js"
    end

    teardown do
      (@files << @output).each { |f| File.delete(f) if File.exists?(f) }
    end

    should "resolve dependencies and join files together" do
      file1_contents = <<-JS
      /**
       * @depend #{@files[1]}
       */
      JS

      file2_contents = <<-JS
      /**
       * I am file 2
       */
      JS

      File.open(@files[0], "w") { |f| f.puts(file1_contents) }
      File.open(@files[1], "w") { |f| f.puts(file2_contents) }

      File.expects(:exists?).at_least(1).returns(true)

      cmd = Juicer::Command::Concat.new("--output #{@output}")
      cmd.execute("file1.js")

      assert_equal file2_contents + file1_contents, File.read(@output)
    end
  end
end
