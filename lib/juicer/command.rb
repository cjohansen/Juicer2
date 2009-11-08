# -*- coding: utf-8 -*-

require "juicer"

module Juicer
  #
  # 
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  module Command    
    def self.load(cmd)
      Juicer.load_lib("command/#{cmd}")
    end

    def self.list
      Juicer.list_libs("command")
    end
  end
end
