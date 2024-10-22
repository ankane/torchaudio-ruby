require_relative "lib/torchaudio/version"

Gem::Specification.new do |spec|
  spec.name          = "torchaudio"
  spec.version       = TorchAudio::VERSION
  spec.summary       = "Data manipulation and transformation for audio signal processing"
  spec.homepage      = "https://github.com/ankane/torchaudio-ruby"
  spec.license       = "BSD-2-Clause"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{ext,lib}/**/*"]
  spec.require_path  = "lib"
  spec.extensions    = ["ext/torchaudio/extconf.rb"]

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "torch-rb", ">= 0.13"
  spec.add_dependency "rice", ">= 4.3.3"
end
