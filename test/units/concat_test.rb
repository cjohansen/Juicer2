# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/css"

class ConcatTest < Test::Unit::TestCase
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
