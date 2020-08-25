require_relative "test_helper"

class TorchAudioTest < Minitest::Test
  def test_load_save
    load_path = "#{root}/waves_yesno/0_0_0_0_1_1_1_1.wav"
    waveform, sample_rate = TorchAudio.load(load_path)

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
end
