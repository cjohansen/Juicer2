require "test_helper"

class JuicerTest < Test::Unit::TestCase
  context "environment" do
    should "be default" do
      assert_equal "default", Juicer.env
    end

    should "override environment" do
      Juicer.env = "dev"

      assert_equal "dev", Juicer.env
    end
  end

  context "load path" do
    should "use Juicer home and env" do
      lib = "observable-1.0.0"
      create_lib(lib)

      assert_equal [File.join(Juicer.home, "packages", Juicer.env, lib, "lib")], Juicer.load_path
    end

    should "use custom Juicer home and env" do
      home = "/usr/local/lib/juicer"
      env = "myapp"
      Juicer.home = home
      Juicer.env = env
      lib = "observable-1.0.0"
      create_lib(lib)

      assert_equal [File.join(home, "packages", env, lib, "lib")], Juicer.load_path
    end
  end

  private
  def create_lib(lib)
    FileUtils.mkdir_p(File.join(Juicer.pkg_dir, "#{lib}/lib"))
  end
end
