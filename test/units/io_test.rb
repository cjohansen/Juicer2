require "test_helper"
require "juicer/io"

class IOTest < Test::Unit::TestCase
  context "creating a juicer io" do
    should "create empty string io" do
      StringIO.expects(:new).with("", "r+")
      io = Juicer::IO.new
    end

    should "create file wrapper" do
      File.expects(:exists?).returns(true)
      io = Juicer::IO.new("styles.css")

      assert_nil io.instance_eval { @stream }
    end

    should "create io wrapper" do
      io = StringIO.new
      StringIO.expects(:new).never
      io = Juicer::IO.new(io)

      assert_not_nil io.instance_eval { @stream }
    end

    should "wrap string in IO object" do
      str = "body {}"
      StringIO.expects(:new).with(str, "r+")
      io = Juicer::IO.new(str)
    end
  end

  context "sending messages to IO object" do
    should "proxy to IO stream" do
      stream = StringIO.new
      io = Juicer::IO.new(stream)

      assert_false io.closed?
    end
  end
  
  context "opening io" do
    should "create new IO object" do
      io_like = "html {}"
      io = Juicer::IO.new(io_like)
      Juicer::IO.expects(:new).with(io_like, nil).returns(io)

      Juicer::IO.open(io_like)
    end

    should "yield new IO object" do
      contents = "html {}"
      actual = nil

      Juicer::IO.open(contents) { |ios| actual = ios.read }

      assert_not_nil actual
      assert_equal actual, contents
    end

    should "return block return value" do
      contents = "html {}"

      assert_equal contents, Juicer::IO.open(contents) { |ios| contents }
    end
  end

  context "loading IO resources" do
    should "find file from load path" do
      filename = "humanity/myfile.css"
      file = File.join(Juicer.pkg_dir, "myapp/lib", filename)
      contents = "body, html, * {}"
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, "w") { |f| f.puts contents }

      io = Juicer::IO.load(filename)

      assert_equal "#{contents}\n", io.read
    end
  end
end
