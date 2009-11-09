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
      return nil if cmd.nil?

      klass = Juicer.class_name_for(cmd)
      return Juicer::Command.const_get(klass) if Juicer::Command.const_defined?(klass)

      Juicer.load_lib("command/#{cmd}")
    end

    def self.list
      Juicer.list_libs("command")
    end
  end
end
