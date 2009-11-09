# -*- coding: utf-8 -*-

require "integration_helper"
require "juicer/command/cat"

class CatCommandIntegrationTest < Test::Unit::TestCase
  context "catenating files" do
    setup do
      Juicer::Test.setup_testfs
    end

    teardown do
      Juicer::Test.teardown_testfs
    end

    should "resolve js dependencies and join files together" do
      files = Juicer::Test.file_list("file1.js", "file2.js")
      output = Juicer::Test.file("out.js")

      contents = [Juicer::Test.write(files[0], "/**\n * @depend #{files[1]}\n */"),
                  Juicer::Test.write(files[1], "/**\n * I am file 2\n */")]

      cli = Juicer::Cli.new("cat --output #{output} #{files[0]}")
      cli.execute

      assert_equal contents.reverse.join("\n") + "\n", File.read(output)
    end

    should "resolve css dependencies and join files together" do
      files = Juicer::Test.file_list("file1.css", "file2.css")
      output = Juicer::Test.file("out.css")

      contents = [Juicer::Test.write(files[0], "@import url(#{files[1]});\n\nhtml { background: #000; }"),
                  Juicer::Test.write(files[1], "/**\n * I am file 2\n */")]

      cli = Juicer::Cli.new("cat --output #{output} #{files[0]}")
      cli.execute

      assert_equal contents.reverse.join("\n") + "\n", File.read(output)
    end

    should "read css from stdin, resolve dependencies and concatenate files" do
      files = Juicer::Test.file_list("file1.css", "file2.css")
      output = Juicer::Test.file("out.css")

      contents = [Juicer::Test.write(files[0], "@import url(#{files[1]});\n\nhtml { background: #000; }"),
                  Juicer::Test.write(files[1], "/**\n * I am file 2\n */")]
      stdin_css = "@import url(#{files[0]});"

      fake_stdin(stdin_css) do
        cli = Juicer::Cli.new("cat --output #{output}")
        cli.execute
      end

      assert_equal contents.reverse.join("\n") + "\n" + stdin_css, File.read(output)
    end

    should "resolve css dependencies and concat to stdout" do
      files = Juicer::Test.file_list("file1.css", "file2.css")
      output = Juicer::Test.file("out.css")

      contents = [Juicer::Test.write(files[0], "@import url(#{files[1]});\n\nhtml { background: #000; }"),
                  Juicer::Test.write(files[1], "/**\n * I am file 2\n */")]

      css = capture_stdout do
        cli = Juicer::Cli.new("cat #{files[0]}")
        cli.execute
      end

      assert_equal contents.reverse.join("\n") + "\n", css
    end
  end
end
