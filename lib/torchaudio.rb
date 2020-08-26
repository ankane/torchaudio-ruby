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
require "torchaudio/functional"
require "torchaudio/transforms/mel_scale"
require "torchaudio/transforms/mel_spectrogram"
require "torchaudio/transforms/spectrogram"
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

    def save(filepath, src, sample_rate, precision: 16, channels_first: true)
      si = Ext::SignalInfo.new
      ch_idx = channels_first ? 0 : 1
      si.rate = sample_rate
      si.channels = src.dim == 1 ? 1 : src.size(ch_idx)
      si.length = src.numel
      si.precision = precision
      save_encinfo(filepath, src, channels_first: channels_first, signalinfo: si)
    end

    def save_encinfo(filepath, src, channels_first: true, signalinfo: nil, encodinginfo: nil, filetype: nil)
      ch_idx, len_idx = channels_first ? [0, 1] : [1, 0]

      # check if save directory exists
      abs_dirpath = File.dirname(File.expand_path(filepath))
      unless Dir.exist?(abs_dirpath)
        raise "Directory does not exist: #{abs_dirpath}"
      end
      # check that src is a CPU tensor
      check_input(src)
      # Check/Fix shape of source data
      if src.dim == 1
        # 1d tensors as assumed to be mono signals
        src.unsqueeze!(ch_idx)
      elsif src.dim > 2 || src.size(ch_idx) > 16
        # assumes num_channels < 16
        raise ArgumentError, "Expected format where C < 16, but found #{src.size}"
      end
      # sox stores the sample rate as a float, though practically sample rates are almost always integers
      # convert integers to floats
      if signalinfo
        if signalinfo.rate && !signalinfo.rate.is_a?(Float)
          if signalinfo.rate.to_f == signalinfo.rate
            signalinfo.rate = signalinfo.rate.to_f
          else
            raise ArgumentError, "Sample rate should be a float or int"
          end
        end
        # check if the bit precision (i.e. bits per sample) is an integer
        if signalinfo.precision && ! signalinfo.precision.is_a?(Integer)
          if signalinfo.precision.to_i == signalinfo.precision
            signalinfo.precision = signalinfo.precision.to_i
          else
            raise ArgumentError, "Bit precision should be an integer"
          end
        end
      end
      # programs such as librosa normalize the signal, unnormalize if detected
      if src.min >= -1.0 && src.max <= 1.0
        src = src * (1 << 31)
        src = src.long
      end
      # set filetype and allow for files with no extensions
      extension = File.extname(filepath)
      filetype = extension.length > 0 ? extension[1..-1] : filetype
      # transpose from C x L -> L x C
      if channels_first
        src = src.transpose(1, 0)
      end
      # save data to file
      src = src.contiguous
      Ext.write_audio_file(filepath, src, signalinfo, encodinginfo, filetype)
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
