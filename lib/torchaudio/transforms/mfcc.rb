module TorchAudio
  module Transforms
    class MFCC < Torch::NN::Module
      SUPPORTED_DCT_TYPES = [2]

      def initialize(sample_rate: 16000, n_mfcc: 40, dct_type: 2, norm: :ortho, log_mels: false, melkwargs: {})
        super()

        raise ArgumentError, "DCT type not supported: #{dct_type}" unless SUPPORTED_DCT_TYPES.include?(dct_type)

        @sample_rate = sample_rate
        @n_mfcc = n_mfcc
        @dct_type = dct_type
        @norm = norm
        @top_db = 80.0
        @amplitude_to_db = TorchAudio::Transforms::AmplitudeToDB.new(stype: :power, top_db: @top_db)

        @melspectrogram = TorchAudio::Transforms::MelSpectrogram.new(sample_rate: @sample_rate, **melkwargs)

        raise ArgumentError, "Cannot select more MFCC coefficients than # mel bins" if @n_mfcc > @melspectrogram.n_mels

        dct_mat = F.create_dct(@n_mfcc, @melspectrogram.n_mels, norm: @norm)
        register_buffer('dct_mat', dct_mat)

        @log_mels = log_mels
      end

      def forward(waveform)
        mel_specgram = @melspectrogram.(waveform)
        if @log_mels
          mel_specgram = Torch.log(mel_specgram + 1e-6)
        else
          mel_specgram = @amplitude_to_db.(mel_specgram)
        end

        Torch
          .matmul(mel_specgram.transpose(-2, -1), @dct_mat)
          .transpose(-2, -1)
      end
    end
  end
end
