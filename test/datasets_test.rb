require_relative "test_helper"

class DatasetsTest < Minitest::Test
  def test_yesno
    yesno_data = TorchAudio::Datasets::YESNO.new(root, download: true)
    n = 47
    waveform, sample_rate, labels = yesno_data[n]
    expected = [-0.00024414062, -0.00030517578, -9.1552734e-05, -0.00039672852, -0.00018310547]
    assert_elements_in_delta expected, waveform[0][0..4].to_a
    assert_equal [1, 49120], waveform.shape
    assert_equal 8000, sample_rate
    assert_equal [1, 1, 0, 1, 1, 0, 0, 1], labels
  end
end
