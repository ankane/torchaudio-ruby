module TorchAudio
  module Transforms
    class ComputeDeltas < Torch::NN::Module
      def initialize(win_length: 5, mode: "replicate")
        super()
        @win_length = win_length
        @mode = mode
      end

      def forward(specgram)
        F.compute_deltas(specgram, win_length: @win_length, mode: @mode)
      end
    end
  end
end
