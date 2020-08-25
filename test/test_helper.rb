require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"

class Minitest::Test
  def setup
    @@once ||= TorchAudio::Datasets::YESNO.new(root, download: true)
  end

  def root
    @root ||= ENV["CI"] ? "#{ENV["HOME"]}/data" : Dir.tmpdir
  end

  def assert_elements_in_delta(expected, actual)
    assert_equal expected.size, actual.size
    expected.zip(actual) do |exp, act|
      assert_in_delta exp, act
    end
  end
end
