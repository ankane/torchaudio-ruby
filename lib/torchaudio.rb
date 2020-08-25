# dependencies
require "torch"

# ext
require "torchaudio/ext"

# stdlib
require "csv"
require "digest"
require "fileutils"
require "rubygems/package"
require "set"

# modules
require "torchaudio/datasets/utils"
require "torchaudio/datasets/yesno"
require "torchaudio/version"

module TorchAudio
  class Error < StandardError; end

  class << self
    def load(
      filepath, out: nil, normalization: true, channels_first: true, num_frames: 0,
      offset: 0, signalinfo: nil, encodinginfo: nil, filetype: nil
    )

      filepath = filepath.to_s

      # check if valid file
      unless File.exist?(filepath)
        raise ArgumentError, "#{filepath} not found or is a directory"
      end

      # initialize output tensor
      if !out.nil?
        check_input(out)
      else
        out = Torch::FloatTensor.new
      end

      if num_frames < -1
        raise ArgumentError, "Expected value for num_samples -1 (entire file) or >=0"
      end
      if offset < 0
        raise ArgumentError, "Expected positive offset value"
      end

      # same logic as C++
      # could also make read_audio_file work with nil
      filetype ||= File.extname(filepath)[1..-1]

      sample_rate =
        Ext.read_audio_file(
          filepath,
          out,
          channels_first,
          num_frames,
          offset,
          signalinfo,
          encodinginfo,
          filetype
        )

      # normalize if needed
      normalize_audio(out, normalization)

      [out, sample_rate]
    end

    def load_wav(filepath, **kwargs)
      kwargs[:normalization] = 1 << 16
      load(filepath, **kwargs)
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
