# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/cli"

class CliTest < Test::Unit::TestCase
  context "creating new cli objects" do
    should "set logger level to info when verbose option is set" do
      cli = Juicer::Cli.new(%w{-v})

      assert_equal Juicer.log, cli.log
      assert_equal Logger::INFO, cli.log.level
    end

    should "set logger level to debug when debug option is set" do
      cli = Juicer::Cli.new(%w{-d})

      assert_equal Juicer.log, cli.log
      assert_equal Logger::DEBUG, cli.log.level
    end

    should "set logger level to error when silent option is set" do
      cli = Juicer::Cli.new(%w{-s})

      assert_equal Juicer.log, cli.log
      assert_equal Logger::ERROR, cli.log.level
    end
    
    should "set logger level default warn level" do
      cli = Juicer::Cli.new([])

      assert_equal Juicer.log, cli.log
      assert_equal Logger::WARN, cli.log.level
    end
  end
end
