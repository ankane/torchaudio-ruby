module TorchAudio
  module Transforms
    class MelSpectrogram < Torch::NN::Module
      def initialize(
        sample_rate: 16000, n_fft: 400, win_length: nil, hop_length: nil, f_min: 0.0,
        f_max: nil, pad: 0, n_mels: 128, window_fn: Torch.method(:hann_window),
        power: 2.0, normalized: false, wkwargs: nil
      )

        super()
        @sample_rate = sample_rate
        @n_fft = n_fft
        @win_length = win_length || n_fft
        @hop_length = hop_length || @win_length.div(2)
        @pad = pad
        @power = power
        @normalized = normalized
        @n_mels = n_mels  # number of mel frequency bins
        @f_max = f_max
        @f_min = f_min
        @spectrogram =
          Spectrogram.new(
            n_fft: @n_fft, win_length: @win_length, hop_length: @hop_length, pad: @pad,
            window_fn: window_fn, power: @power, normalized: @normalized, wkwargs: wkwargs
          )
        @mel_scale = MelScale.new(n_mels: @n_mels, sample_rate: @sample_rate, f_min: @f_min, f_max: @f_max, n_stft: @n_fft.div(2) + 1)
      end

      def forward(waveform)
        specgram = @spectrogram.call(waveform)
        @mel_scale.call(specgram)
      end
    end
  end
end
