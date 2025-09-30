require_relative "test_helper"

class FunctionalTest < Minitest::Test
  def test_compute_deltas
    waveform, _ = TorchAudio.load(audio_path)
    transformed = TorchAudio::Functional.compute_deltas(waveform)
    assert_equal [1, 50800], transformed.shape
    expected = [3.0517579e-06, 0.0, -3.0517579e-06, -6.1035157e-06, 0.0]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end

  def test_gain
    waveform, _ = TorchAudio.load(audio_path)
    transformed = TorchAudio::Functional.gain(waveform)
    assert_equal [1, 50800], transformed.shape
    expected = [3.4241286e-05, 6.848257e-05, 3.4241286e-05, 3.4241286e-05, 3.4241286e-05]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end

  def test_dither
    waveform, _ = TorchAudio.load(audio_path)
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
