require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"

class Minitest::Test
  def root
    @root ||= ENV["CI"] ? "#{ENV["HOME"]}/data" : Dir.tmpdir
  end

  def assert_elements_in_delta(expected, actual)
    assert_equal expected.size, actual.size
    expected.zip(actual) do |exp, act|
      assert_in_delta exp, act, 0.0001
    end
  end

  def audio_path
    @test_path ||= begin
      TorchAudio::Datasets::YESNO.new(root, download: true)
      "#{root}/waves_yesno/0_0_0_0_1_1_1_1.wav"
    end
  end
end
