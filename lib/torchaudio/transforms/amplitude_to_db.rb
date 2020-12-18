module TorchAudio
  module Transforms
    class AmplitudeToDB < Torch::NN::Module
      def initialize(stype: :power, top_db: nil)
        super()
        
        @stype = stype
        
        raise ArgumentError, 'top_db must be a positive numerical' if top_db and top_db.negative?
        
        @top_db = top_db
        @multiplier = stype == :power ? 10.0 : 20.0
        @amin = 1e-10
        @ref_value = 1.0
        @db_multiplier = Math.log10([@amin, @ref_value].max)
      end

      def forward(amplitude_spectrogram)
        F.amplitude_to_DB(
          amplitude_spectrogram, 
          @multiplier, @amin, @db_multiplier, @top_db
        )
      end
    end
  end
end
