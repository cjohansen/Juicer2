# -*- coding: utf-8 -*-

begin
  require 'test/unit'
  require 'shoulda'
  require 'open-uri'
rescue LoadError => err
  puts "To run the Juicer integration test suite you need Test::Unit, shoulda, and open-uri"
  puts err
  exit
end

require "common_test_helper"
