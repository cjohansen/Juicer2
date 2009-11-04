# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/css"

class IOProxyWrapperTest < Test::Unit::TestCase
  context "creating css resources" do
    should "wrap a new resource" do
      css = Juicer::CSS.new

      assert_equal "", css.read
    end

    should "wrap new resource with options" do
      options = { :opt => 2 }
      css = Juicer::CSS.new(options)

      assert_equal "", css.read
      assert_equal options, css.instance_eval { @options }
    end

    should "wrap existing resource" do
      resource = "file.css"
      instance = Juicer::IOProxy.new(resource)
      Juicer::IOProxy.expects(:new).with(resource).returns(instance)
      css = Juicer::CSS.new(resource)

      assert_equal 0, css.dependencies.length
    end

    should "create empty resource with dependencies" do
      resources = ["file.css", "body {}", StringIO.new]
      css = Juicer::CSS.new(resources)

      assert_equal 3, css.dependencies.length
    end

    should "raise error for bad input" do
      assert_raise ArgumentError do
        Juicer::CSS.new(Juicer)
      end
    end
  end

  context "reading CSS contents" do
    setup do
      @css_contents = "body { background: red; }"
      @file = "some.css"
    end

    teardown { File.delete(@file) if File.exists?(@file) }

    should "return full string CSS listing" do
      css = Juicer::CSS.new(@css_contents)

      assert_equal @css_contents, css.read
    end

    should "return full file CSS listing" do
      File.open(@file, "w") { |f| f.print(@css_contents) }
      css = Juicer::CSS.new(@file)

      assert_equal @css_contents, css.read
    end

    should "return full io CSS listing" do
      css = Juicer::CSS.new(StringIO.new(@css_contents))

      assert_equal @css_contents, css.read
    end
  end

  context "exporting CSS content" do
    setup do
      @css_contents = "body { background: red; }"
      @css = Juicer::CSS.new(@css_contents)
      @file = "some.css"
    end

    teardown { File.delete(@file) if File.exists?(@file) }

    should "write CSS to file" do
      @css.export(@file)

      assert_equal @css_contents, File.read(@file)
    end

    should "write CSS to stream" do
      ios = StringIO.new
      @css.export(ios)
      ios.rewind

      assert_equal @css_contents, ios.read
    end

    should "re-raise exception on bad input" do
      assert_raise ArgumentError do
        @css.export([])
      end
    end
  end

  context "getting file name from css resource" do
    setup do
      @filename = "design/css/mystyle.css"
      FileUtils.mkdir_p(File.dirname(@filename))
      FileUtils.touch(@filename)
    end

    teardown { FileUtils.rm_rf("design") }
    
    should "return provided file name" do
      css = Juicer::CSS.new(@filename)

      assert_equal File.expand_path(@filename), css.file
    end
  end

  context "opening a CSS resource" do
    should "return CSS instances directly" do
      css = Juicer::CSS.new

      assert_equal css, Juicer::CSS.open(css)
    end

    should "return new CSS instance" do
      io = StringIO.new("Some contents in this string")
      css = Juicer::CSS.open(io)

      assert_equal io.rewind && io.read, css.read
    end

    should "re-raise error on bad input" do
      assert_raise ArgumentError do
        Juicer::CSS.open(Juicer)
      end
    end
  end
end
