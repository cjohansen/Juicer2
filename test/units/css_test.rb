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

      should "not load circular dependencies" do
        File.open(@files[2], "w") { |f| f.puts "@import url('#{@files[0]}');\n@import url('#{@files[1]}');" }
        File.open(@files[1], "w") { |f| f.puts "@import url('#{@files[2]}');" }

        css = Juicer::CSS.new(<<-CSS)
          @import  url(#{@files[2]}) tv;
          @import url("#{@files[1]}")
        CSS

        actual = css.dependencies(:recursive => true).collect { |dep| dep.path }

        assert_equal @files, actual
      end
    end

    context "from CSS with comments" do
      setup do
        @css = Juicer::CSS.new(<<-CSS)
          /**
           * Bla bla
           */
          /*@import  url(#{@files[2]}) tv;*/
          @import url("#{@files[1]}");
          /* @import  url(#{@files[0]}); */
          /* These imports are not going in
          @import  url(#{@files[0]});
          @import  url(#{@files[2]});
          *//* Neither is this: @import url(#{@files[2]});*/
        CSS
      end

      should "load dependencies not commented out" do
        assert_equal [@files[1]], @css.dependencies.collect { |d| d.path }
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

    context "through resources" do
      should "include self in returned set" do
        css = Juicer::CSS.new

        assert_equal [css], css.resources
      end

      should "include self after all dependencies" do
        css = Juicer::CSS.new(<<-CSS)
          @import url(#{@files[0]});
          @import url(#{@files[1]});
        CSS

        css << @files[2]
        expected = @files.collect { |f| Juicer::CSS.new(f) } + [css]

        assert_equal expected, css.resources
      end
    end
  end

  context "concatenating files" do
    setup do
      @files = %w[myfile.css some/other/file.css third.css]

      @files.each do |file|
        FileUtils.mkdir_p(File.dirname(file))
        File.open(file, "w") { |f| f.puts file }
      end
    end

    teardown do
      @files.each { |file| FileUtils.rm_rf(file) }
    end

    should "concatenate file without dependencies" do
      css = Juicer::CSS.new(@files[0])

      assert_equal "#{@files[0]}\n", css.read(:inline_dependencies => true)
    end

    should "concatenate file with dependencies" do
      css = Juicer::CSS.new(@files[0])
      css << @files[1]

      assert_equal "#{@files[1]}\n#{@files[0]}\n", css.read(:inline_dependencies => true)
    end

    should "concatenate only direct dependencies" do
      css = Juicer::CSS.new(@files[0])
      contents = "@import '#{@files[2]}';"
      File.open(@files[1], "w") { |f| f.print(contents) }
      css << @files[1]

      assert_equal "#{contents}#{@files[0]}\n", css.read(:inline_dependencies => true)
    end

    should "concatenate nested dependencies" do
      css = Juicer::CSS.new(@files[0])
      contents = "@import '#{@files[2]}';"
      File.open(@files[1], "w") { |f| f.print(contents) }
      css << @files[1]

      assert_equal "#{contents}#{@files[0]}\n", css.read(:inline_dependencies => true, :recursive => true)
    end

    should "concatenate nested dependencies with concat" do
      css = Juicer::CSS.new
      contents = "some merged content"
      css.expects(:read).with(:inline_dependencies => true, :recursive => true).returns(contents)
      result = css.concat

      assert_equal contents, result.read
    end

    should "concatenate deeply nested dependencies" do
      contents2 = "@import '#{@files[1]}';"
      File.open(@files[2], "w") { |f| f.print(contents2) }
      contents1 = "@import '#{@files[0]}';"
      File.open(@files[1], "w") { |f| f.print(contents1) }
      css = Juicer::CSS.new(@files[2])

      assert_equal "#{@files[0]}\n#{contents1}#{contents2}", css.concat.read
    end
  end
end
