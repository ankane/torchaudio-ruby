require_relative "test_helper"

class TransformsTest < Minitest::Test
  def test_spectogram
    waveform, sample_rate = TorchAudio.load(audio_path)
    spectrogram = TorchAudio::Transforms::Spectrogram.new.call(waveform)
    assert_equal [1, 201, 255], spectrogram.size
    expected = [0.00051381276, 6.306071e-05, 0.0009923399, 0.00330968, 0.00030008898]
    assert_elements_in_delta expected, spectrogram[0][0][0..4].to_a
  end

  def test_melspectrogram
    waveform, sample_rate = TorchAudio.load(audio_path)
    spectrogram = TorchAudio::Transforms::MelSpectrogram.new.call(waveform)
    assert_equal [1, 128, 255], spectrogram.size
    expected = [0, 0, 0, 0, 0]
    assert_elements_in_delta expected, spectrogram[0][0][0..4].to_a
  end
end
