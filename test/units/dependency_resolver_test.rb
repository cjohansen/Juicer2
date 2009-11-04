# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/css"

class DependencyResolverTest < Test::Unit::TestCase
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
end
