module TorchAudio
  module Datasets
    module Utils
      class << self
        def download_url(url, download_folder, filename: nil, hash_value: nil, hash_type: "sha256")
          filename ||= File.basename(url)
          filepath = File.join(download_folder, filename)

          if File.exist?(filepath)
            raise "#{filepath} already exists. Delete the file manually and retry."
          end

          puts "Downloading #{url}..."
          download_url_to_file(url, filepath, hash_value, hash_type)
        end

        # follows redirects
        def download_url_to_file(url, dst, hash_value, hash_type)
          URI.parse(url).open(max_redirects: 10) do |download|
            # TODO use hash_type
            digest =
              if download.respond_to?(:path)
                download.flush
                Digest::MD5.file(download.path).hexdigest
              else
                Digest::MD5.hexdigest(download.string)
              end

            # check hash
            if digest != hash_value
              raise "The hash of #{dst} does not match. Delete the file manually and retry."
            end

            IO.copy_stream(download, dst)
          end

          dst
        end

        # extract_tar_gz doesn't list files, so just return to_path
        def extract_archive(from_path, to_path: nil, overwrite: nil)
          to_path ||= File.dirname(from_path)

          if from_path.end_with?(".tar.gz") || from_path.end_with?(".tgz")
            File.open(from_path, "rb") do |io|
              Gem::Package.new("").extract_tar_gz(io, to_path)
            end
            return to_path
          end

          raise "We currently only support tar.gz and tgz archives."
        end

        def walk_files(root, suffix, prefix: false, remove_suffix: false)
          return enum_for(:walk_files, root, suffix, prefix: prefix, remove_suffix: remove_suffix) unless block_given?

          Dir.glob("**/*", base: root).sort.each do |f|
            if f.end_with?(suffix)
              if remove_suffix
                f = f[0..(-suffix.length - 1)]
              end

              if prefix
                raise "Not implemented yet"
                # f = File.join(dirpath, f)
              end

              yield f
            end
          end
        end
      end
    end
  end
end
