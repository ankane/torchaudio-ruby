# TorchAudio

:fire: An audio library for Torch.rb

[![Build Status](https://github.com/ankane/torchaudio/workflows/build/badge.svg?branch=master)](https://github.com/ankane/torchaudio/actions)

## Installation

First, [install SoX](#sox-installation). For Homebrew, use:

```sh
brew install sox
```

Add this line to your application’s Gemfile:

```ruby
gem 'torchaudio'
```

## Getting Started

This library follows the [Python API](https://pytorch.org/audio/). Many methods and options are missing at the moment. PRs welcome!

## Tutorial

- [PyTorch tutorial](https://pytorch.org/tutorials/beginner/audio_preprocessing_tutorial.html)
- [Ruby code](examples/tutorial.rb)

Download the [audio file](https://github.com/pytorch/tutorials/raw/master/_static/img/steam-train-whistle-daniel_simon-converted-from-mp3.wav) and install the [matplotlib](https://github.com/mrkn/matplotlib.rb) gem first.

## Basics

Load a file

```ruby
waveform, sample_rate = TorchAudio.load("file.wav")
```

Save a file

```ruby
TorchAudio.save("new.wave", waveform, sample_rate)
```

## Transforms

```ruby
TorchAudio::Transforms::Spectrogram.new.call(waveform)
```

Supported transforms are:

- MelSpectrogram
- MuLawDecoding
- MuLawEncoding
- Spectrogram

## Functional

```ruby
TorchAudio::Functional.lowpass_biquad(waveform, sample_rate, cutoff_freq)
```

Supported functions are:

- compute_deltas
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

- [YESNO](http://www.openslr.org/1/)

## Disclaimer

This library downloads and prepares public datasets. We don’t host any datasets. Be sure to adhere to the license for each dataset.

If you’re a dataset owner and wish to update any details or remove it from this project, let us know.

## SoX Installation

### Mac

```sh
brew install sox
```

### Windows

todo

### Ubuntu

```sh
sudo apt install sox libsox-dev libsox-fmt-all
```

### Travis CI

Add to `.travis.yml`:

```yml
addons:
  apt:
    packages:
      - sox
      - libsox-dev
      - libsox-fmt-all
```

## History

View the [changelog](https://github.com/ankane/torchaudio/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/torchaudio/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/torchaudio/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/torchaudio.git
cd torchaudio
bundle install
bundle exec rake compile
bundle exec rake test
```
