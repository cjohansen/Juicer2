# -*- coding: utf-8 -*-

require "test_helper"

class JuicerTest < Test::Unit::TestCase
  context "juicer environment" do
    setup do
      @env = ENV["JUICER_ENV"]
      ENV.delete("JUICER_ENV")
    end
    
    teardown { ENV["JUICER_ENV"] = @env }

    should "be default" do
      assert_equal "default", Juicer.env
    end

    should "override environment" do
      Juicer.env = "dev"

      assert_equal "dev", Juicer.env
    end

    context "configured in user environment" do
      should "use environment variable JUICER_ENV" do
        env = "my-app"
        ENV["JUICER_ENV"] = env
        assert_equal env, Juicer.env
      end
    end
  end

  context "load path" do
    should "use Juicer home and env" do
      lib = "observable-1.0.0"
      create_lib(lib)

      assert_equal [Dir.pwd, File.join(Juicer.home, "packages", Juicer.env, lib, "lib")], Juicer.load_path
    end

    should "use custom Juicer home and env" do
      home = "/usr/local/lib/juicer"
      env = "myapp"
      Juicer.home = home
      Juicer.env = env
      lib = "observable-1.0.0"
      create_lib(lib)

      assert_equal [Dir.pwd, File.join(home, "packages", env, lib, "lib")], Juicer.load_path
    end
  end

  context "loading libs" do
    setup { @root = File.expand_path(File.join(File.dirname(__FILE__), "../../lib/juicer")) }

    teardown do
      begin
        FileUtils.rm_rf("asset") if File.exists?("asset")
      rescue StandardError => err
      end
    end

    should "compute full lib path" do
      expected = File.join(@root, "some/deeply/nested/path.rb")
      assert_equal expected, Juicer.lib_path(%w{some deeply nested path})
    end

    should "compute short lib path" do
      expected = File.join(@root, "css.rb")
      assert_equal expected, Juicer.lib_path(["css"])
    end

    context "listing libraries" do
      should "return all basenames in a directory" do
        Dir.mkdir("asset")
        File.open(File.join(@root, "asset/path.rb"), "w") { |f| f.puts "" }
        File.open(File.join(@root, "asset/path_resolver.rb"), "w") { |f| f.puts "" }

        assert_equal ["path", "path_resolver"], Juicer.list_libs("asset")
      end
    end

    context "loading library" do
      should "return nil if file does not exist" do
        assert_nil Juicer.load_lib("some/crazy")
      end

      should "require library" do
        require "juicer/javascript"
        lib = "java_script"
        FakeFS::File.expects("exists?").with("#{@root}/#{lib}.rb").returns(true)
        Kernel.expects("require").with("#{@root}/#{lib}.rb")

        assert_equal Juicer::JavaScript, Juicer.load_lib(lib)
      end

      should "raise exception if library file exists, and module does not" do
        lib = "mylib"
        FakeFS::File.expects("exists?").with("#{@root}/#{lib}.rb").returns(true)
        Kernel.expects("require").with("#{@root}/#{lib}.rb")

        assert_raise RuntimeError do
          Juicer.load_lib(lib)
        end
      end
    end
  end
  
  private
  def create_lib(lib)
    FileUtils.mkdir_p(File.join(Juicer.pkg_dir, "#{lib}/lib"))
  end
end
