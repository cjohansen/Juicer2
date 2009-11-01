require "test_helper"
require "juicer/io"

class IOTest < Test::Unit::TestCase
  context "creating a juicer io" do
    should "create empty string io" do
      io = Juicer::IO.new
    end
  end
end
