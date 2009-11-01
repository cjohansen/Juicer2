begin
  require 'test/unit'
  require 'shoulda'
  require 'mocha'
  require 'open-uri'
  require 'fakefs'
  require 'fileutils'
  require 'stringio'
  require 'juicer'
rescue LoadError => err
  puts "To run the Juicer test suite you need Test::Unit, shoulda, mocha, fakefs and open-uri"
  puts err
  exit
end

if RUBY_VERSION < '1.9'
  begin
    require 'redgreen'
  rescue LoadError
  end
end
