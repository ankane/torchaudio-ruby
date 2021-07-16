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
        spec_f =
          Torch.stft(
            waveform,
            n_fft,
            hop_length: hop_length,
            win_length: win_length,
            window: window,
            center: true,
            pad_mode: "reflect",
            normalized: false,
            onesided: true
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

      def compute_deltas(specgram, win_length: 5, mode: "replicate")
        device = specgram.device
        dtype = specgram.dtype

        # pack batch
        shape = specgram.size
        specgram = specgram.reshape(1, -1, shape[-1])

        raise ArgumentError, "win_length must be >= 3" unless win_length >= 3

        n = (win_length - 1).div(2)

        # twice sum of integer squared
        denom = n * (n + 1) * (2 * n + 1) / 3

        specgram = Torch::NN::Functional.pad(specgram, [n, n], mode: mode)

        kernel = Torch.arange(-n, n + 1, 1, device: device, dtype: dtype).repeat([specgram.shape[1], 1, 1])

        output = Torch::NN::Functional.conv1d(specgram, kernel, groups: specgram.shape[1]) / denom

        # unpack batch
        output = output.reshape(shape)
      end

      def gain(waveform, gain_db: 1.0)
        return waveform if gain_db == 0

        ratio = 10 ** (gain_db / 20)

        waveform * ratio
      end

      def dither(waveform, density_function: "TPDF", noise_shaping: false)
        dithered = _apply_probability_distribution(waveform, density_function: density_function)

        if noise_shaping
          raise "Not implemented yet"
          # _add_noise_shaping(dithered, waveform)
        else
          dithered
        end
      end

      def biquad(waveform, b0, b1, b2, a0, a1, a2)
        device = waveform.device
        dtype = waveform.dtype

        output_waveform = lfilter(
            waveform,
            Torch.tensor([a0, a1, a2], dtype: dtype, device: device),
            Torch.tensor([b0, b1, b2], dtype: dtype, device: device)
        )
        output_waveform
      end

      def highpass_biquad(waveform, sample_rate, cutoff_freq, q: 0.707)
        w0 = 2 * Math::PI * cutoff_freq / sample_rate
        alpha = Math.sin(w0) / 2.0 / q

        b0 = (1 + Math.cos(w0)) / 2
        b1 = -1 - Math.cos(w0)
        b2 = b0
        a0 = 1 + alpha
        a1 = -2 * Math.cos(w0)
        a2 = 1 - alpha
        biquad(waveform, b0, b1, b2, a0, a1, a2)
      end

      def lowpass_biquad(waveform, sample_rate, cutoff_freq, q: 0.707)
        w0 = 2 * Math::PI * cutoff_freq / sample_rate
        alpha = Math.sin(w0) / 2 / q

        b0 = (1 - Math.cos(w0)) / 2
        b1 = 1 - Math.cos(w0)
        b2 = b0
        a0 = 1 + alpha
        a1 = -2 * Math.cos(w0)
        a2 = 1 - alpha
        biquad(waveform, b0, b1, b2, a0, a1, a2)
      end

      def lfilter(waveform, a_coeffs, b_coeffs, clamp: true)
        # pack batch
        shape = waveform.size
        waveform = waveform.reshape(-1, shape[-1])

        raise ArgumentError unless (a_coeffs.size(0) == b_coeffs.size(0))
        raise ArgumentError unless (waveform.size.length == 2)
        raise ArgumentError unless (waveform.device == a_coeffs.device)
        raise ArgumentError unless (b_coeffs.device == a_coeffs.device)

        device = waveform.device
        dtype = waveform.dtype
        n_channel, n_sample = waveform.size
        n_order = a_coeffs.size(0)
        n_sample_padded = n_sample + n_order - 1
        raise ArgumentError unless (n_order > 0)

        # Pad the input and create output
        padded_waveform = Torch.zeros(n_channel, n_sample_padded, dtype: dtype, device: device)
        padded_waveform[0..-1, (n_order - 1)..-1] = waveform
        padded_output_waveform = Torch.zeros(n_channel, n_sample_padded, dtype: dtype, device: device)

        # Set up the coefficients matrix
        # Flip coefficients' order
        a_coeffs_flipped = a_coeffs.flip([0])
        b_coeffs_flipped = b_coeffs.flip([0])

        # calculate windowed_input_signal in parallel
        # create indices of original with shape (n_channel, n_order, n_sample)
        window_idxs = Torch.arange(n_sample, device: device).unsqueeze(0) + Torch.arange(n_order, device: device).unsqueeze(1)
        window_idxs = window_idxs.repeat([n_channel, 1, 1])
        window_idxs += (Torch.arange(n_channel, device: device).unsqueeze(-1).unsqueeze(-1) * n_sample_padded)
        window_idxs = window_idxs.long
        # (n_order, ) matmul (n_channel, n_order, n_sample) -> (n_channel, n_sample)
        input_signal_windows = Torch.matmul(b_coeffs_flipped, Torch.take(padded_waveform, window_idxs))

        input_signal_windows.div!(a_coeffs[0])
        a_coeffs_flipped.div!(a_coeffs[0])
        input_signal_windows.t.each_with_index do |o0, i_sample|
          windowed_output_signal = padded_output_waveform[0..-1, i_sample...(i_sample + n_order)]
          o0.addmv!(windowed_output_signal, a_coeffs_flipped, alpha: -1)
          padded_output_waveform[0..-1, i_sample + n_order - 1] = o0
        end

        output = padded_output_waveform[0..-1, (n_order - 1)..-1]

        if clamp
          output = Torch.clamp(output, -1.0, 1.0)
        end

        # unpack batch
        output = output.reshape(shape[0...-1] + output.shape[-1..-1])

        output
      end

      def amplitude_to_DB(amp, multiplier, amin, db_multiplier, top_db: nil)
        db = Torch.log10(Torch.clamp(amp, min: amin)) * multiplier
        db -= multiplier * db_multiplier

        db = db.clamp(min: db.max.item - top_db) if top_db

        db
      end

      def DB_to_amplitude(db, ref, power)
        Torch.pow(Torch.pow(10.0, db * 0.1), power) * ref
      end

      def create_dct(n_mfcc, n_mels, norm: nil)
        n = Torch.arange(n_mels.to_f)
        k = Torch.arange(n_mfcc.to_f).unsqueeze!(1)
        dct = Torch.cos((n + 0.5) * k * Math::PI / n_mels.to_f)

        if norm.nil?
          dct *= 2.0
        else
          raise ArgumentError, "Invalid DCT norm value" unless norm == :ortho

          dct[0] *= 1.0 / Math.sqrt(2.0)
          dct *= Math.sqrt(2.0 / n_mels)
        end

        dct.t
      end

      private

      def _apply_probability_distribution(waveform, density_function: "TPDF")
        # pack batch
        shape = waveform.size
        waveform = waveform.reshape(-1, shape[-1])

        channel_size = waveform.size[0] - 1
        time_size = waveform.size[-1] - 1

        random_channel = channel_size > 0 ? Torch.randint(channel_size, [1]).item.to_i : 0
        random_time = time_size > 0 ? Torch.randint(time_size, [1]).item.to_i : 0

        number_of_bits = 16
        up_scaling = 2 ** (number_of_bits - 1) - 2
        signal_scaled = waveform * up_scaling
        down_scaling = 2 ** (number_of_bits - 1)

        signal_scaled_dis = waveform
        if density_function == "RPDF"
          rpdf = waveform[random_channel][random_time] - 0.5

          signal_scaled_dis = signal_scaled + rpdf
        elsif density_function == "GPDF"
          # TODO Replace by distribution code once
          # https://github.com/pytorch/pytorch/issues/29843 is resolved
          # gaussian = torch.distributions.normal.Normal(torch.mean(waveform, -1), 1).sample()

          num_rand_variables = 6

          gaussian = waveform[random_channel][random_time]
          (num_rand_variables * [time_size]).each do |ws|
            rand_chan = Torch.randint(channel_size, [1]).item.to_i
            gaussian += waveform[rand_chan][Torch.randint(ws, [1]).item.to_i]
          end

          signal_scaled_dis = signal_scaled + gaussian
        else
          # dtype needed for https://github.com/pytorch/pytorch/issues/32358
          # TODO add support for dtype and device to bartlett_window
          tpdf = Torch.bartlett_window(time_size + 1).to(signal_scaled.device, dtype: signal_scaled.dtype)
          tpdf = tpdf.repeat([channel_size + 1, 1])
          signal_scaled_dis = signal_scaled + tpdf
        end

        quantised_signal_scaled = Torch.round(signal_scaled_dis)
        quantised_signal = quantised_signal_scaled / down_scaling

        # unpack batch
        quantised_signal.reshape(shape[0...-1] + quantised_signal.shape[-1..-1])
      end
    end
  end

  F = Functional
end
