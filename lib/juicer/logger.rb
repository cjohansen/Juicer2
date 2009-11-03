# -*- coding: utf-8 -*-

require "logger"

module Juicer
  def self.log
    @@log ||= Logger.new($stdout)
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
