require_relative "test_helper"

class TorchAudioTest < Minitest::Test
  def test_load_missing
    error = assert_raises(ArgumentError) do
      TorchAudio.load("missing.wav")
    end
    assert_equal "missing.wav not found or is a directory", error.message
  end
end
