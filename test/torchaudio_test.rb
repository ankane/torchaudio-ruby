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
    assert TorchAudio.load_wav(audio_path)
  end
end
