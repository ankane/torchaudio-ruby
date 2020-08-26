require_relative "test_helper"

class TransformsTest < Minitest::Test
  def test_spectogram
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Transforms::Spectrogram.new.call(waveform)
    assert_equal [1, 201, 255], transformed.size
    expected = [0.00051381276, 6.306071e-05, 0.0009923399, 0.00330968, 0.00030008898]
    assert_elements_in_delta expected, transformed[0][0][0..4].to_a
  end

  def test_melspectrogram
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Transforms::MelSpectrogram.new.call(waveform)
    assert_equal [1, 128, 255], transformed.size
    expected = [0, 0, 0, 0, 0]
    assert_elements_in_delta expected, transformed[0][0][0..4].to_a
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

  def test_compute_deltas
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Functional.compute_deltas(waveform)
    assert_equal [1, 50800], transformed.shape
    expected = [3.0517579e-06, 0.0, -3.0517579e-06, -6.1035157e-06, 0.0]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end

  def test_gain
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Functional.gain(waveform)
    assert_equal [1, 50800], transformed.shape
    expected = [3.4241286e-05, 6.848257e-05, 3.4241286e-05, 3.4241286e-05, 3.4241286e-05]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end

  def test_dither
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Functional.dither(waveform)
    assert_equal [1, 50800], transformed.shape
    expected = [3.0517578e-05, 6.1035156e-05, 3.0517578e-05, 3.0517578e-05, 3.0517578e-05]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end

  def test_lowpass_biquad
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Functional.lowpass_biquad(waveform, sample_rate, 3000)
    assert_equal [1, 50800], transformed.shape
    expected = [1.7364715e-05, 5.308807e-05, 4.8351816e-05, 2.3546876e-05, 3.114574e-05]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end

  def test_highpass_biquad
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Functional.highpass_biquad(waveform, sample_rate, 3000)
    assert_equal [1, 50800], transformed.shape
    expected = [2.979314e-06, -2.808783e-06, -4.30352e-06, 7.97258e-06, -6.082024e-06]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end
end
