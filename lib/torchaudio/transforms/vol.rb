module TorchAudio
  module Transforms
    class Vol < Torch::NN::Module
      def initialize(gain, gain_type: "amplitude")
        super()
        @gain = gain
        @gain_type = gain_type

        if ["amplitude", "power"].include?(gain_type) && gain < 0
          raise ArgumentError, "If gain_type = amplitude or power, gain must be positive."
        end
      end

      def forward(waveform)
        if @gain_type == "amplitude"
          waveform = waveform * @gain
        end

        if @gain_type == "db"
          waveform = F.gain(waveform, @gain)
        end

        if @gain_type == "power"
          waveform = F.gain(waveform, 10 * Math.log10(@gain))
        end

        Torch.clamp(waveform, -1, 1)
      end
    end
  end
end
