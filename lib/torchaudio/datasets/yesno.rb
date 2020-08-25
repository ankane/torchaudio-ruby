module TorchAudio
  module Datasets
    class YESNO < Torch::Utils::Data::Dataset
      URL = "http://www.openslr.org/resources/1/waves_yesno.tar.gz"
      FOLDER_IN_ARCHIVE = "waves_yesno"
      CHECKSUMS = {
        "http://www.openslr.org/resources/1/waves_yesno.tar.gz" => "962ff6e904d2df1126132ecec6978786"
      }

      def initialize(root, url: URL, folder_in_archive: FOLDER_IN_ARCHIVE, download: false)
        archive = File.basename(url)
        archive = File.join(root, archive)
        @path = File.join(root, folder_in_archive)

        if download
          unless Dir.exist?(@path)
            unless File.exist?(archive)
              checksum = CHECKSUMS.fetch(url)
              Utils.download_url(url, root, hash_value: checksum, hash_type: "md5")
            end
            Utils.extract_archive(archive)
          end
        end

        unless Dir.exist?(@path)
          raise "Dataset not found. Please use `download: true` to download it."
        end

        walker = Utils.walk_files(@path, ext_audio, prefix: false, remove_suffix: true)
        @walker = walker.to_a
      end

      def [](n)
        fileid = @walker[n]
        load_yesno_item(fileid, @path, ext_audio)
      end

      def length
        @walker.length
      end
      alias_method :size, :length

      private

      def load_yesno_item(fileid, path, ext_audio)
        labels = fileid.split("_").map(&:to_i)

        file_audio = File.join(path, fileid + ext_audio)
        waveform, sample_rate = TorchAudio.load(file_audio)

        [waveform, sample_rate, labels]
      end

      def ext_audio
        ".wav"
      end
    end
  end
end
