# -*- coding: utf-8 -*-

# Juicer is a command line tool aimed at frontend web developers. It provides a
# utility belt for managing dependencies for CSS and JavaScript, concatenating
# and minifying files as well as a number of additional helpful tools, including
#
# * Cache busters - adding timestamps to URL's in CSS files to combat caching of updated files when using a far future expires header
# * Asset host cycling/domain sharding
# * Embedding of images in CSS files using data URI's or MHTML (IE)
# * Verifying JavaScript syntax through JsLint
# * Testing JavaScript, currently only by using JsTestDriver
# * Producing documentation of JavaScript files.
#
# Additionally, Juicer provides a powerful API to access all these features - in
# isolation or in combination - through Ruby code, meaning you can embed
# performance improving functionality directly in your web application without
# using the command line binary.
#
# The Juicer main module provides a version constant,
# <tt>Juicer::VERSION</tt> and method <tt>Juicer.version</tt> as well as the
# Juicer installation directory, <tt>Juicer.home</tt>, where extras like
# third-party binaries are located.
#
# The installation directory is normally <tt>~/.juicer</tt>, but a number of
# other guesses are made if you're on a non-Unix system. You can set the
# installation directory through <tt>Juicer.home=</tt>
#
# Author::    Christian Johansen (christian@cjohansen.no)
# Copyright:: Copyright (c) 2009 Christian Johansen
# License::   BSD
#
# Copyright (c) 2008-2009, Christian Johansen (christian@cjohansen.no)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of Christian Johansen nor the names of his contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
module Juicer
  VERSION = "0.9.99"
  @@home = nil
  @@env = nil

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

  # Returns the Juicer load path. The current working directory is always
  # prepended to this path.
  #
  def self.load_path
    Dir.glob(File.join(Juicer.pkg_dir, "**/lib")).unshift(Dir.pwd)
  end

  def self.pkg_dir
    File.join(Juicer.home, "packages", self.env)
  end

  def self.env
    [@@env, ENV['JUICER_ENV'], "default"].find { |env| !env.nil? && env != "" }
  end

  def self.env=(env)
    @@env = env
  end

  def self.load_lib(lib, klass_name = nil)
    lib = lib.split("/") if lib.is_a?(String)
    path = self.lib_path(lib)
    return nil unless File.exists?(path)

    Kernel.require(path)
    mod = Juicer
    lib.collect! { |m| Juicer.class_name_for(m) }

    (lib[0...-1] << (klass_name || lib[-1])).each do |klass|
      if !mod.const_defined?(klass)
        raise "Unable to load #{lib.join('/')}:\n#{path} exists but does not define class #{mod.to_s}::#{klass}"
      end

      mod = mod.const_get(klass)
    end

    mod
  end

  def self.list_libs(path)
    path = path.split("/") if path.is_a?(String)
    Dir.glob(self.lib_path(path + ["*"])).collect { |file| File.basename(file).sub(/\.rb$/, '') }
  end

  def self.lib_path(lib)
    File.join(File.dirname(__FILE__), "juicer/#{lib.join('/')}.rb")
  end

  def self.class_name_for(name)
    name.split("_").inject("") { |str, piece| str + piece.capitalize }
  end
end
