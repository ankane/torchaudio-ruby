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
    transformed = TorchAudio::Transforms::MelSpectrogram.new(sample_rate: sample_rate).call(waveform)
    assert_equal [1, 128, 255], transformed.size
    expected = [4.320904736232478e-06, 0.00026097119553014636, 0.00010256850509904325, 0.0009344223653897643, 0.00013253440556582063]
    assert_elements_in_delta expected, transformed[0][0][0..4].to_a
  end

  def test_amplitude_to_db
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Transforms::MelSpectrogram.new(sample_rate: sample_rate).call(waveform)
    assert_equal [1, 128, 255], transformed.size
    db = TorchAudio::Transforms::AmplitudeToDB.new(top_db: 80.0).call transformed
    expected = [-53.64425277709961, -35.834075927734375, -39.889862060546875, -30.29456901550293, -38.77671432495117]
    assert_elements_in_delta expected, db[0][0][0..4].to_a
  end

  def test_mfcc
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Transforms::MFCC.new(n_mfcc: 16, sample_rate: sample_rate).(waveform)
    assert_equal [1, 16, 255], transformed.size
    expected = [-588.85400390625, -470.5740051269531, -420.1156005859375, -393.4096374511719, -415.3000793457031]
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
    transformed = TorchAudio::Transforms::ComputeDeltas.new.call(waveform)
    assert_equal [1, 50800], transformed.shape
    expected = [3.0517579e-06, 0.0, -3.0517579e-06, -6.1035157e-06, 0.0]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end

  def test_fade
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Transforms::Fade.new.call(waveform)
    assert_equal [1, 50800], transformed.shape
    expected = [3.0517578e-05, 6.1035156e-05, 3.0517578e-05, 3.0517578e-05, 3.0517578e-05]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end

  def test_vol
    waveform, sample_rate = TorchAudio.load(audio_path)
    transformed = TorchAudio::Transforms::Vol.new(2).call(waveform)
    assert_equal [1, 50800], transformed.shape
    expected = [6.1035156e-05, 0.00012207031, 6.1035156e-05, 6.1035156e-05, 6.1035156e-05]
    assert_elements_in_delta expected, transformed[0, 0..4].to_a
  end
end
