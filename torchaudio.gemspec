require_relative "lib/torchaudio/version"

Gem::Specification.new do |spec|
  spec.name          = "torchaudio"
  spec.version       = TorchAudio::VERSION
  spec.summary       = "Data manipulation and transformation for audio signal processing"
  spec.homepage      = "https://github.com/ankane/torchaudio"
  spec.license       = "BSD-2-Clause"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{ext,lib}/**/*"]
  spec.require_path  = "lib"
  spec.extensions    = ["ext/torchaudio/extconf.rb"]

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "torch-rb", ">= 0.3.4"
  spec.add_dependency "rice", ">= 2.2"
end
