module TorchAudio
  module Functional
    class << self
      def spectrogram(waveform, pad, window, n_fft, hop_length, win_length, power, normalized)
        if pad > 0
          # TODO add "with torch.no_grad():" back when JIT supports it
          waveform = Torch::NN::Functional.pad(waveform, [pad, pad], "constant")
        end

        # pack batch
        shape = waveform.size
        waveform = waveform.reshape(-1, shape[-1])

        # default values are consistent with librosa.core.spectrum._spectrogram
        spec_f = Torch.stft(
          waveform, n_fft, hop_length: hop_length, win_length: win_length, window: window, center: true, pad_mode: "reflect", normalized: false, onesided: true
        )

        # unpack batch
        spec_f = spec_f.reshape(shape[0..-2] + spec_f.shape[-3..-1])

        if normalized
          spec_f.div!(window.pow(2.0).sum.sqrt)
        end
        if power
          spec_f = complex_norm(spec_f, power: power)
        end

        spec_f
      end

      def mu_law_encoding(x, quantization_channels)
        mu = quantization_channels - 1.0
        if !x.floating_point?
          x = x.to(dtype: :float)
        end
        mu = Torch.tensor(mu, dtype: x.dtype)
        x_mu = Torch.sign(x) * Torch.log1p(mu * Torch.abs(x)) / Torch.log1p(mu)
        x_mu = ((x_mu + 1) / 2 * mu + 0.5).to(dtype: :int64)
        x_mu
      end

      def mu_law_decoding(x_mu, quantization_channels)
        mu = quantization_channels - 1.0
        if !x_mu.floating_point?
          x_mu = x_mu.to(dtype: :float)
        end
        mu = Torch.tensor(mu, dtype: x_mu.dtype)
        x = ((x_mu) / mu) * 2 - 1.0
        x = Torch.sign(x) * (Torch.exp(Torch.abs(x) * Torch.log1p(mu)) - 1.0) / mu
        x
      end

      def complex_norm(complex_tensor, power: 1.0)
        complex_tensor.pow(2.0).sum(-1).pow(0.5 * power)
      end

      def create_fb_matrix(n_freqs, f_min, f_max, n_mels, sample_rate, norm: nil)
        if norm && norm != "slaney"
          raise ArgumentError, "norm must be one of None or 'slaney'"
        end

        # freq bins
        # Equivalent filterbank construction by Librosa
        all_freqs = Torch.linspace(0, sample_rate.div(2), n_freqs)

        # calculate mel freq bins
        # hertz to mel(f) is 2595. * math.log10(1. + (f / 700.))
        m_min = 2595.0 * Math.log10(1.0 + (f_min / 700.0))
        m_max = 2595.0 * Math.log10(1.0 + (f_max / 700.0))
        m_pts = Torch.linspace(m_min, m_max, n_mels + 2)
        # mel to hertz(mel) is 700. * (10**(mel / 2595.) - 1.)
        f_pts = (Torch.pow(10, m_pts / 2595.0) - 1.0) * 700.0
        # calculate the difference between each mel point and each stft freq point in hertz
        f_diff = f_pts[1..-1] - f_pts[0...-1]  # (n_mels + 1)
        slopes = f_pts.unsqueeze(0) - all_freqs.unsqueeze(1)  # (n_freqs, n_mels + 2)
        # create overlapping triangles
        zero = Torch.zeros(1)
        down_slopes = (slopes[0..-1, 0...-2] * -1.0) / f_diff[0...-1]  # (n_freqs, n_mels)
        up_slopes = slopes[0..-1, 2..-1] / f_diff[1..-1]  # (n_freqs, n_mels)
        fb = Torch.max(zero, Torch.min(down_slopes, up_slopes))

        if norm && norm == "slaney"
          # Slaney-style mel is scaled to be approx constant energy per channel
          enorm = 2.0 / (f_pts[2...(n_mels + 2)] - f_pts[:n_mels])
          fb *= enorm.unsqueeze(0)
        end

        fb
      end
    end
  end

  F = Functional
end
