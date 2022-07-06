module TorchAudio
  module Transforms
    class Spectrogram < Torch::NN::Module
      def initialize(
        n_fft: 400, win_length: nil, hop_length: nil, pad: 0,
        window_fn: Torch.method(:hann_window), power: 2.0, normalized: false, wkwargs: nil,
        center: true, pad_mode: "reflect", onesided: true
      )

        super()
        @n_fft = n_fft
        # number of FFT bins. the returned STFT result will have n_fft // 2 + 1
        # number of frequecies due to onesided=True in torch.stft
        @win_length = win_length || n_fft
        @hop_length = hop_length || @win_length.div(2) # floor division
        window = wkwargs.nil? ? window_fn.call(@win_length) : window_fn.call(@win_length, **wkwargs)
        register_buffer("window", window)
        @pad = pad
        @power = power
        @normalized = normalized
        @center = center
        @pad_mode = pad_mode
        @onesided = onesided
      end

      def forward(waveform)
        F.spectrogram(
          waveform, @pad, @window, @n_fft, @hop_length, @win_length, @power, @normalized,
          center: @center, pad_mode: @pad_mode, onesided: @onesided
        )
      end
    end
  end
end
