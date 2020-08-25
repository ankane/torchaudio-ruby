require_relative "test_helper"

class TorchAudioTest < Minitest::Test
  def test_load_save
    waveform, sample_rate = TorchAudio.load(audio_path)

    save_path = "#{Dir.mktmpdir}/save.wav"
    TorchAudio.save(save_path, waveform, sample_rate)
    assert File.exist?(save_path)
  end

  def test_load_missing
    error = assert_raises(ArgumentError) do
      TorchAudio.load("missing.wav")
    end
    assert_equal "missing.wav not found or is a directory", error.message
  end

  def test_load_wav
    out, sample_rate = TorchAudio.load_wav(audio_path)
    assert_equal [1, 50800], out.shape
    assert_equal [1, 2, 1, 1, 1], out[0][0..4].to_a
    assert_equal 8000, sample_rate
  end
end
