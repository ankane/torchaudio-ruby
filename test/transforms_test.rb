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

  def test_mu_law_encoding
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Transforms::MuLawEncoding.new.call(waveform)
    assert_equal [1, 50800], transformed.size
    expected = [128, 128, 128, 128, 128]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a

    reconstructed = TorchAudio::Transforms::MuLawDecoding.new.call(transformed)
    assert_equal [1, 50800], reconstructed.size
    expected = [8.621309e-05, 8.621309e-05, 8.621309e-05, 8.621309e-05, 8.621309e-05]
    assert_elements_in_delta expected, reconstructed[0, 0..4].to_a

    err = ((waveform - reconstructed).abs / waveform.abs).median.item
    assert_in_delta err, 0.0199
  end
end
