require_relative "test_helper"

class TorchAudioTest < Minitest::Test
  def test_load_save
    waveform, sample_rate = TorchAudio.load(audio_path)

    save_path = "#{Dir.mktmpdir}/save.wav"
    TorchAudio.save(save_path, waveform, sample_rate)
    assert File.exist?(save_path)
  end

  def test_load_missing
    error = assert_raises(RuntimeError) do
      TorchAudio.load("missing.wav")
    end
    assert_match "Could not open input file: missing.wav", error.message
  end

  def test_save_sample_rate
    save_path = "#{Dir.mktmpdir}/save.wav"
    TorchAudio.save(save_path, Torch.zeros([1, 16000]), 16000)
    _, sample_rate = TorchAudio.load(save_path)
    assert_equal 16000, sample_rate
  end
end
