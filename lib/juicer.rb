# Juicer main module. Provides a version constant,
# +Juicer::VERSION+/+Juicer.version+ as well as the Juicer installation
# directory, +Juicer.home+, where extras like third-party binaries are located.
#
# Author::    Christian Johansen (christian@cjohansen.no)
# Copyright:: Copyright (c) 2009 Christian Johansen
# License::   BSD
#
module Juicer
  VERSION = "0.9.99"
  @@home = nil

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Returns the Juicer installation directory
  #
  def self.home
    return @@home if @@home
    return ENV['JUICER_HOME'] if ENV['JUICER_HOME']
    return File.join(ENV['HOME'], ".juicer") if ENV['HOME']
    return File.join(ENV['APPDATA'], "juicer") if ENV['APPDATA']
    return File.join(ENV['HOMEDRIVE'], ENV['HOMEPATH'], "juicer") if ENV['HOMEDRIVE'] && ENV['HOMEPATH']
    return File.join(ENV['USERPROFILE'], "juicer") if ENV['USERPROFILE']
    return File.join(ENV['Personal'], "juicer") if ENV['Personal']
  end

  # Set home directory
  #
  def self.home=(home)
    @@home = home
  end
end
