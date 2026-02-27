# dependencies
require "torch"

# stdlib
require "digest"
require "fileutils"
require "rubygems/package"
require "set"

# modules
require_relative "torchaudio/datasets/utils"
require_relative "torchaudio/datasets/yesno"
require_relative "torchaudio/functional"
require_relative "torchaudio/transforms/compute_deltas"
require_relative "torchaudio/transforms/fade"
require_relative "torchaudio/transforms/mel_scale"
require_relative "torchaudio/transforms/mel_spectrogram"
require_relative "torchaudio/transforms/mu_law_encoding"
require_relative "torchaudio/transforms/mu_law_decoding"
require_relative "torchaudio/transforms/spectrogram"
require_relative "torchaudio/transforms/amplitude_to_db"
require_relative "torchaudio/transforms/mfcc"
require_relative "torchaudio/transforms/vol"
require_relative "torchaudio/version"

module TorchAudio
  class Error < StandardError; end

  class << self
    def load(
      uri,
      frame_offset: 0,
      num_frames: -1,
      channels_first: true
    )
      begin
        require "torchcodec"
      rescue LoadError
        raise LoadError, "TorchCodec is required for load. Please install torchcodec to use this function."
      end

      begin
        decoder = TorchCodec::Decoders::AudioDecoder.new(uri)
      rescue => e
        raise RuntimeError, "Failed to create AudioDecoder for #{uri}: #{e}"
      end

      # Get sample rate from metadata
      sample_rate = decoder.metadata[:sample_rate]
      if sample_rate.nil?
        raise RuntimeError, "Unable to determine sample rate from audio metadata"
      end

      # Decode the entire file first, then subsample manually
      # This is the simplest approach since torchcodec uses time-based indexing
      begin
        audio_samples = decoder.get_all_samples
      rescue => e
        raise RuntimeError, "Failed to decode audio samples: #{e}"
      end

      data = audio_samples[:data]

      # Apply frame_offset and num_frames (which are actually sample offsets)
      if frame_offset > 0
        if frame_offset >= data.shape[1]
          # Return empty tensor if offset is beyond available data
          empty_shape = channels_first ? [data.shape[0], 0] : [0, data.shape[0]]
          return [Torch.zeros(empty_shape, dtype: Torch.float32), sample_rate]
        end
        data = data[0.., frame_offset..]
      end

      if num_frames == 0
        # Return empty tensor if num_frames is 0
        empty_shape = channels_first ? [data.shape[0], 0] : [0, data.shape[0]]
        return [Torch.zeros(empty_shape, dtype: Torch.float32), sample_rate]
      elsif num_frames > 0
        data = data[0.., 0...num_frames]
      end

      # TorchCodec returns data in [channel, time] format by default
      # Handle channels_first parameter
      if !channels_first
        data = data.transpose(0, 1)  # [channel, time] -> [time, channel]
      end

      [data, sample_rate]
    end

    def load_wav(path, channels_first: true)
      load(path, channels_first: channels_first)
    end

    def save(
      uri,
      src,
      sample_rate,
      channels_first: true,
      compression: nil
    )
      begin
        require "torchcodec"
      rescue LoadError
        raise LoadError, "TorchCodec is required for save. Please install torchcodec to use this function."
      end

      # Input validation
      if !src.is_a?(Torch::Tensor)
        raise ArgumentError, "Expected src to be a torch.Tensor, got #{src.class.name}"
      end

      if src.dtype != Torch.float32
        src = src.float
      end

      if sample_rate <= 0
        raise ArgumentError, "sample_rate must be positive, got #{sample_rate}"
      end

      # Handle tensor shape and channels_first
      if src.ndim == 1
        # Convert to 2D: [1, time] for channels_first: true
        if channels_first
          data = src.unsqueeze(0)  # [1, time]
        else
          # For channels_first: false, input is [time] -> reshape to [time, 1] -> transpose to [1, time]
          data = src.unsqueeze(1).transpose(0, 1)  # [time, 1] -> [1, time]
        end
      elsif src.ndim == 2
        if channels_first
          data = src  # Already [channel, time]
        else
          data = src.transpose(0, 1)  # [time, channel] -> [channel, time]
        end
      else
        raise ArgumentError, "Expected 1D or 2D tensor, got #{src.ndim}D tensor"
      end

      # Create AudioEncoder
      begin
        encoder = TorchCodec::Encoders::AudioEncoder.new(data, sample_rate: sample_rate)
      rescue => e
        raise RuntimeError, "Failed to create AudioEncoder: #{e}"
      end

      # Determine bit_rate from compression parameter
      bit_rate = nil
      if !compression.nil?
        if compression.is_a?(Integer) || compression.is_a?(Float)
          bit_rate = compression.to_i
        else
          warn "Unsupported compression type #{compression.class.name}."
        end
      end

      # Save to file
      begin
        encoder.to_file(uri, bit_rate: bit_rate)
      rescue => e
        raise RuntimeError, "Failed to save audio to #{uri}: #{e}"
      end
    end

    private

    def check_input(src)
      raise ArgumentError, "Expected a tensor, got #{src.class.name}" unless Torch.tensor?(src)
      raise ArgumentError, "Expected a CPU based tensor, got #{src.class.name}" if src.cuda?
    end

    def normalize_audio(signal, normalization)
      return unless normalization

      normalization = 1 << 31 if normalization == true

      if normalization.is_a?(Numeric)
        signal.div!(normalization)
      elsif normalization.respond_to?(:call)
        signal.div!(normalization.call(signal))
      end
    end
  end
end
