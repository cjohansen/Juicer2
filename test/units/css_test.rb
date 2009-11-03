# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/css"

class CSSTest < Test::Unit::TestCase
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

  context "resolving dependencies" do
    setup do
      @files = %w[myfile.css some/other/file.css third.css]

      @files.each do |file|
        FileUtils.mkdir_p(File.dirname(file))
        FileUtils.touch(file)
      end
    end

    teardown do
      @files.each { |file| FileUtils.rm_rf(file) }
    end

    should "load added dependencies" do
      css = Juicer::CSS.new(StringIO.new, StringIO.new, StringIO.new)

      assert_equal 3, css.dependencies.length
    end

    context "from single level of CSS imports" do
      setup do
        @css = Juicer::CSS.new(<<-CSS)
          @import "#{@files[0]}"
          @import url('#{@files[1]}');
          @import  '#{@files[2]}';
        CSS

        @expected = @files.collect { |f| File.expand_path(f) }
      end
      
      should "load dependencies" do
        actual = @css.dependencies.collect { |dep| dep.file }

        assert_equal @expected, actual
      end

      should "load dependencies recursively" do
        actual = @css.dependencies(:recursive => true).collect { |dep| dep.file }

        assert_equal @expected, actual
      end
    end

    context "from nested CSS imports" do
      setup do
        File.open(@files[1], "w") { |f| f.puts "@import url('#{@files[0]}');" }

        @css = Juicer::CSS.new(<<-CSS)
          @import url("#{@files[1]}") 
          @import  url(#{@files[2]}) tv;
        CSS
      end

      should "load direct dependencies" do
        expected = [@files[1], @files[2]].collect { |f| File.expand_path(f) }
        actual = @css.dependencies.collect { |dep| dep.file }

        assert_equal expected, actual
      end

      should "load nested dependencies" do
        expected = @files.collect { |f| File.expand_path(f) }
        actual = @css.dependencies(:recursive => true).collect { |dep| dep.file }

        assert_equal expected, actual
      end
    end

    context "from bad syntax" do
      setup do
        @log = StringIO.new
        Juicer.log = Logger.new(@log)
        @css = Juicer::CSS.new(<<-CSS)
          @import url( #{@files[0]} );
          @import url(#{@files[1]});
        CSS
      end

      should "not choke" do
        assert_nothing_raised do
          assert_equal 1, @css.dependencies.length
        end
      end

      should "log error and continue" do
        @css.dependencies

        assert_match /ERROR -- : Encountered an error/, @log.rewind && @log.read
      end
    end
  end
end
