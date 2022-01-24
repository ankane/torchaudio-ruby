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
        def download_url_to_file(url, dst, hash_value, hash_type, redirects = 0)
          raise "Too many redirects" if redirects > 10

          uri = URI(url)
          tmp = nil
          location = nil

          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
            request = Net::HTTP::Get.new(uri)

            http.request(request) do |response|
              case response
              when Net::HTTPRedirection
                location = response["location"]
              when Net::HTTPSuccess
                tmp = "#{Dir.tmpdir}/#{Time.now.to_f}" # TODO better name
                File.open(tmp, "wb") do |f|
                  response.read_body do |chunk|
                    f.write(chunk)
                  end
                end
              else
                raise Error, "Bad response"
              end
            end
          end

          if location
            download_url_to_file(location, dst, hash_value, hash_type, redirects + 1)
          else
            # check hash
            # TODO use hash_type
            if Digest::MD5.file(tmp).hexdigest != hash_value
              raise "The hash of #{dst} does not match. Delete the file manually and retry."
            end

            FileUtils.mv(tmp, dst)
            dst
          end
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
