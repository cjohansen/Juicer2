# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/javascript"

class JavaScriptTest < Test::Unit::TestCase
  context "resolving dependencies" do
    setup do
      @files = %w[myfile.js some/other/file.js third.js]

      @files.each do |file|
        FileUtils.mkdir_p(File.dirname(file))
        FileUtils.touch(file)
      end
    end

    teardown do
      @files.each { |file| FileUtils.rm_rf(file) }
    end

    context "from JavaScript with comments" do
      setup do

      end

      should "load dependencies commented out" do
        javascript = Juicer::JavaScript.new(<<-JS)
          /**
           * Bla bla
           * @depend #{@files[2]}
           */
          /**
           * // @depend #{@files[0]} */

           // @depend  #{@files[1]}
        JS

        assert_equal [@files[2], @files[0], @files[1]], javascript.dependencies.collect { |d| d.path }
      end

      should "stop processing once coding starts" do
        javascript = Juicer::JavaScript.new(<<-JS)
          /**
           * Bla bla
           * @depend #{@files[2]}
           */
          /**
           * // @depend #{@files[0]} */
          var a = 3;
           // @depend  #{@files[1]}
        JS

        assert_equal [@files[2], @files[0]], javascript.dependencies.collect { |d| d.path }
      end
    end
  end
end
