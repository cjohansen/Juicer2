# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/css"

class CSSTest < Test::Unit::TestCase
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
  end
end
