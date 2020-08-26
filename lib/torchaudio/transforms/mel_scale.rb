module TorchAudio
  module Transforms
    class MelScale < Torch::NN::Module
      def initialize(n_mels: 128, sample_rate: 16000, f_min: 0.0, f_max: nil, n_stft: nil)
        super()
        @n_mels = n_mels
        @sample_rate = sample_rate
        @f_max = f_max || sample_rate.div(2).to_f
        @f_min = f_min

        raise ArgumentError, "Require f_min: %f < f_max: %f" % [f_min, @f_max] unless f_min <= @f_max

        fb = n_stft.nil? ? Torch.empty(0) : F.create_fb_matrix(n_stft, @f_min, @f_max, @n_mels, @sample_rate)
        register_buffer("fb", fb)
      end

      def forward(specgram)
        shape = specgram.size
        specgram = specgram.reshape(-1, shape[-2], shape[-1])

        if @fb.numel == 0
          tmp_fb = F.create_fb_matrix(specgram.size(1), @f_min, @f_max, @n_mels, @sample_rate)
          # Attributes cannot be reassigned outside __init__ so workaround
          @fb.resize!(tmp_fb.size)
          @fb.copy!(tmp_fb)
        end

        # (channel, frequency, time).transpose(...) dot (frequency, n_mels)
        # -> (channel, time, n_mels).transpose(...)
        mel_specgram = Torch.matmul(specgram.transpose(1, 2), @fb).transpose(1, 2)

        # unpack batch
        mel_specgram = mel_specgram.reshape(shape[0...-2] + mel_specgram.shape[-2..-1])

        mel_specgram
      end
    end
  end
end
