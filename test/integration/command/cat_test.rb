# -*- coding: utf-8 -*-

require "integration_helper"
require "juicer/command/cat"

class CatCommandIntegrationTest < Test::Unit::TestCase
  context "catenating files" do
    setup do
      Juicer::Test.setup_testfs
      @files = Juicer::Test.file_list(["file1.js", "file2.js"])
      @output = Juicer::Test.file("out.js")
    end

    teardown do
      Juicer::Test.teardown_testfs
    end

    should "resolve dependencies and join files together" do
      contents = [Juicer::Test.write(@files[0], "/**\n * @depend #{@files[1]}\n */"),
                  Juicer::Test.write(@files[1], "/**\n * I am file 2\n */")]

      cli = Juicer::Cli.new("cat --output #{@output} #{@files[0]}")
      cli.execute

      assert_equal contents.reverse.join("\n") + "\n", File.read(@output)
    end
  end
end
