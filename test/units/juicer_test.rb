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

  private
  def create_lib(lib)
    FileUtils.mkdir_p(File.join(Juicer.pkg_dir, "#{lib}/lib"))
  end
end
