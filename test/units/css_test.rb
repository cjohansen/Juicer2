require "test_helper"
require "juicer/css"
require "stringio"

class CssTest < Test::Unit::TestCase
  context "creating css resources" do
    should "wrap a new resource" do
      css = Juicer::Css.new

      assert_equal "", css.read
    end

    should "wrap new resource with options" do
      options = { :opt => 2 }
      css = Juicer::Css.new(options)

      assert_equal "", css.read
      assert_equal options, css.instance_eval { @options }
    end

    should "wrap existing resource" do
      resource = "file.css"
      Juicer::IO.expects(:new).with(resource)
      css = Juicer::Css.new(resource)

      assert_equal 0, css.dependencies.length
    end

    should "create empty resource with dependencies" do
      resources = ["file.css", "body {}", StringIO.new]
      css = Juicer::Css.new(resources)

      assert_equal 3, css.dependencies.length
    end
  end
end
