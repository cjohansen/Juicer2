# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/command"

class CommandTest < Test::Unit::TestCase
  context "loading commands" do
    should "load lib via Juicer.load_lib" do
      Juicer.expects("load_lib").with("command/mycmd")
      Juicer::Command.load("mycmd")
    end

    should "list libs via Juicer.list_libs" do
      Juicer.expects("list_libs").with("command")
      Juicer::Command.list
    end
  end
end
