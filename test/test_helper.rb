# -*- coding: utf-8 -*-

begin
  require 'test/unit'
  require 'shoulda'
  require 'mocha'
  require 'open-uri'
  require 'fakefs'
rescue LoadError => err
  puts "To run the Juicer test suite you need Test::Unit, shoulda, mocha, fakefs and open-uri"
  puts err
  exit
end

# These two methods don't work on 1.8.7 for some reason
#
# TODO: Fix FakeFS proper and get these outta here
class FakeFS::File
  if !File.respond_to?(:mtime)
    def self.mtime(*args)
      Time.now
    end
  end
end

require "common_test_helper"
