# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/io_proxy"

class IOProxyTest < Test::Unit::TestCase
  context "creating a juicer io" do
    should "create empty string io" do
      StringIO.expects(:new).with("", "r+")
      io = Juicer::IOProxy.new
    end

    should "create file wrapper" do
      File.expects(:exists?).returns(true)
      io = Juicer::IOProxy.new("styles.css")

      assert_nil io.instance_eval { @stream }
    end

    should "create file wrapper for file in user home" do
      file = "~/somefile.css"
      path = File.expand_path(file)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(file)
      io = Juicer::IOProxy.new(file)

      assert_equal file, io.path
    end

    should "create io wrapper" do
      io = StringIO.new
      StringIO.expects(:new).never
      io = Juicer::IOProxy.new(io)

      assert_not_nil io.instance_eval { @stream }
    end

    should "wrap string in IO object" do
      str = "body {}"
      StringIO.expects(:new).with(str, "r+")
      io = Juicer::IOProxy.new(str)
    end

    should "fail for unsupported input" do
      assert_raise ArgumentError do
        Juicer::IOProxy.new({})
      end
    end

    should "not fail on input with newlines" do
      assert_nothing_raised do
        Juicer::IOProxy.new(<<-TEXT)
        Some text
        Goes in here
        TEXT
      end
    end
  end
  
  context "opening io" do
    should "create new IO object" do
      io_like = "html {}"
      io = Juicer::IOProxy.new(io_like)
      Juicer::IOProxy.expects(:new).with(io_like, nil).returns(io)

      Juicer::IOProxy.open(io_like)
    end

    should "yield new IOProxy object" do
      contents = "html {}"
      actual = nil

      Juicer::IOProxy.open(contents) { |ios| actual = ios.read }

      assert_not_nil actual
      assert_equal actual, contents
    end

    should "return block return value" do
      contents = "html {}"

      assert_equal contents, Juicer::IOProxy.open(contents) { |ios| contents }
    end

    should "run on instance" do
      contents = "some string inside here"
      ios = Juicer::IOProxy.new(contents)

      assert_equal contents, ios.open { |stream| stream.read }
    end

    should "not close streams not created inside #open" do
      stream = StringIO.new
      Juicer::IOProxy.open(stream)

      assert !stream.closed?
    end
  end

  context "loading IOProxy resources" do
    should "find file from load path" do
      filename = "humanity/myfile.css"
      file = File.join(Juicer.pkg_dir, "myapp/lib", filename)
      contents = "body, html, * {}"
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, "w") { |f| f.puts contents }

      io = Juicer::IOProxy.load(filename)

      assert_equal "#{contents}\n", io.open { |stream| stream.read }
    end

    should "re-raise error for bad input" do
      assert_raises ArgumentError do
        Juicer::IOProxy.load([])
      end
    end

    should "return object directly if it is an IOProxy" do
      proxy = Juicer::IOProxy.new

      assert_equal proxy, Juicer::IOProxy.load(proxy)
    end

    should "not fail on input with newlines" do
      assert_nothing_raised do
        Juicer::IOProxy.load(<<-TEXT)
        Some text
        Goes in here
        TEXT
      end
    end
  end

  context "proxy instances" do
    should "define equality for streams" do
      stream = StringIO.new
      io = Juicer::IOProxy.new(stream)
      io2 = Juicer::IOProxy.new(stream)

      assert_equal io, io2
    end

    should "define equality for files" do
      filename = "some_file.txt"
      FileUtils.touch(filename)
      io = Juicer::IOProxy.new(filename)
      io2 = Juicer::IOProxy.new(filename)
      File.delete(filename)

      assert_equal io, io2
    end

    should "not define unequal files as equal" do
      filename = "some_file.txt"
      FileUtils.touch(filename)
      io = Juicer::IOProxy.new(filename)
      File.delete(filename)
      filename = "some_other_file.txt"
      FileUtils.touch(filename)
      io2 = Juicer::IOProxy.new(filename)
      File.delete(filename)

      assert_not_equal io, io2
    end

    should "not fail when checking equality with unsupported types" do
      assert_nothing_raised do
        assert Juicer::IOProxy.new != []
      end
    end
  end
end
