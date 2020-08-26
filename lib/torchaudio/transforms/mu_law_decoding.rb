module TorchAudio
  module Transforms
    class MuLawDecoding < Torch::NN::Module
      def initialize(quantization_channels: 256)
        super()
        @quantization_channels = quantization_channels
      end

      def forward(x_mu)
        F.mu_law_decoding(x_mu, @quantization_channels)
      end
    end
  end
end
