module TorchAudio
  module Transforms
    class Fade < Torch::NN::Module
      def initialize(fade_in_len: 0, fade_out_len: 0, fade_shape: "linear")
        super()
        @fade_in_len = fade_in_len
        @fade_out_len = fade_out_len
        @fade_shape = fade_shape
      end

      def forward(waveform)
        waveform_length = waveform.size[-1]
        device = waveform.device
        fade_in(waveform_length).to(device) * fade_out(waveform_length).to(device) * waveform
      end

      private

      def fade_in(waveform_length)
        fade = Torch.linspace(0, 1, @fade_in_len)
        ones = Torch.ones(waveform_length - @fade_in_len)

        if @fade_shape == "linear"
          fade = fade
        end

        if @fade_shape == "exponential"
          fade = Torch.pow(2, (fade - 1)) * fade
        end

        if @fade_shape == "logarithmic"
          fade = Torch.log10(0.1 + fade) + 1
        end

        if @fade_shape == "quarter_sine"
          fade = Torch.sin(fade * Math::PI / 2)
        end

        if @fade_shape == "half_sine"
          fade = Torch.sin(fade * Math::PI - Math::PI / 2) / 2 + 0.5
        end

        Torch.cat([fade, ones]).clamp!(0, 1)
      end

      def fade_out(waveform_length)
        fade = Torch.linspace(0, 1, @fade_out_len)
        ones = Torch.ones(waveform_length - @fade_out_len)

        if @fade_shape == "linear"
          fade = - fade + 1
        end

        if @fade_shape == "exponential"
          fade = Torch.pow(2, - fade) * (1 - fade)
        end

        if @fade_shape == "logarithmic"
          fade = Torch.log10(1.1 - fade) + 1
        end

        if @fade_shape == "quarter_sine"
          fade = Torch.sin(fade * Math::PI / 2 + Math::PI / 2)
        end

        if @fade_shape == "half_sine"
          fade = Torch.sin(fade * Math::PI + Math::PI / 2) / 2 + 0.5
        end

        Torch.cat([ones, fade]).clamp!(0, 1)
      end
    end
  end
end
