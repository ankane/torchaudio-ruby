module TorchAudio
  module Transforms
    class MuLawEncoding < Torch::NN::Module
      def initialize(quantization_channels: 256)
        super()
        @quantization_channels = quantization_channels
      end

      def forward(x)
        F.mu_law_encoding(x, @quantization_channels)
      end
    end
  end
end
