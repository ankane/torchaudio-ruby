# TorchAudio Ruby

:fire: An audio library for Torch.rb

[![Build Status](https://github.com/ankane/torchaudio-ruby/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/torchaudio-ruby/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "torchaudio"
```

## Getting Started

This library follows the [Python API](https://pytorch.org/audio/). Many methods and options are missing at the moment. PRs welcome!

## Basics

Load a file (requires [torchcodec](https://github.com/ankane/torchcodec-ruby))

```ruby
waveform, sample_rate = TorchAudio.load("file.wav")
```

Save a file (requires [torchcodec](https://github.com/ankane/torchcodec-ruby))

```ruby
TorchAudio.save("new.wave", waveform, sample_rate)
```

## Transforms

```ruby
TorchAudio::Transforms::Spectrogram.new.call(waveform)
```

Supported transforms are:

- AmplitudeToDB
- ComputeDeltas
- Fade
- MelScale
- MelSpectrogram
- MFCC
- MuLawDecoding
- MuLawEncoding
- Spectrogram
- Vol

## Functional

```ruby
TorchAudio::Functional.lowpass_biquad(waveform, sample_rate, cutoff_freq)
```

Supported functions are:

- amplitude_to_DB
- compute_deltas
- create_dct
- create_fb_matrix
- DB_to_amplitude
- dither
- gain
- highpass_biquad
- lowpass_biquad
- mu_law_decoding
- mu_law_encoding
- spectrogram

## Datasets

Load a dataset

```ruby
TorchAudio::Datasets::YESNO.new(".", download: true)
```

Supported datasets are:

- [YESNO](https://www.openslr.org/1/)

## Disclaimer

This library downloads and prepares public datasets. We don’t host any datasets. Be sure to adhere to the license for each dataset.

If you’re a dataset owner and wish to update any details or remove it from this project, let us know.

## History

View the [changelog](https://github.com/ankane/torchaudio-ruby/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/torchaudio-ruby/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/torchaudio-ruby/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/torchaudio-ruby.git
cd torchaudio-ruby
bundle install
bundle exec rake compile
bundle exec rake test
```
