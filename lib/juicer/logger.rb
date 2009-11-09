# -*- coding: utf-8 -*-

require "juicer"
require "logger"

module Juicer
  def self.log
    if !defined?(@@log) || @@log.nil?
      @@log = Logger.new($stdout)
      @@log.level = Logger::WARN
    end

    @@log
  end

  def self.log=(log)
    @@log = log
  end

  module Loggable
    def log
      Juicer.log
    end
  end
end
