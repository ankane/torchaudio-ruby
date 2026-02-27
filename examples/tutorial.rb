# ported from PyTorch Tutorials
# https://pytorch.org/tutorials/beginner/audio_preprocessing_tutorial.html
# see LICENSE-tutorial.txt

# audio file available at
# https://pytorch-tutorial-assets.s3.amazonaws.com/steam-train-whistle-daniel_simon.wav

require "torch"
require "torchaudio"
require "matplotlib/pyplot"

plt = Matplotlib::Pyplot

filename = "steam-train-whistle-daniel_simon.wav"
waveform, sample_rate = TorchAudio.load(filename)

puts "Shape of waveform: #{waveform.size}"
puts "Sample rate of waveform: #{sample_rate}"

plt.figure
plt.plot(waveform.t.to_a)
plt.savefig("waveform.png")

# ---

specgram = TorchAudio::Transforms::Spectrogram.new.call(waveform)

puts "Shape of spectrogram: #{specgram.size}"

plt.figure
plt.imshow(specgram.log2[0, 0..-1, 0..-1].to_a, cmap: "gray")
plt.savefig("spectrogram.png")

# ---

specgram = TorchAudio::Transforms::MelSpectrogram.new.call(waveform)

puts "Shape of spectrogram: #{specgram.size}"

plt.figure
plt.imshow(specgram.log2[0, 0..-1, 0..-1].to_a, cmap: "gray")
plt.savefig("mel_spectrogram.png")

# ---

puts "Min of waveform: #{waveform.min.item}"
puts "Max of waveform: #{waveform.max.item}"
puts "Mean of waveform: #{waveform.mean.item}"

# ---

transformed = TorchAudio::Transforms::MuLawEncoding.new.call(waveform)

puts "Shape of transformed waveform: #{transformed.size}"

plt.figure
plt.plot(transformed[0, 0..-1].to_a)
plt.savefig("mu_law_encoding.png")

# ---

reconstructed = TorchAudio::Transforms::MuLawDecoding.new.call(transformed)

puts "Shape of recovered waveform: #{reconstructed.size}"

plt.figure
plt.plot(reconstructed[0, 0..-1].to_a)
plt.savefig("mu_law_decoding.png")

# ---

err = ((waveform - reconstructed).abs / waveform.abs).median

puts "Median relative difference between original and MuLaw reconstructed signals: #{(err.item * 100).round(2)}%"

# ---

mu_law_encoding_waveform = TorchAudio::Functional.mu_law_encoding(waveform, 256)

puts "Shape of transformed waveform: #{mu_law_encoding_waveform.size}"

plt.figure
plt.plot(mu_law_encoding_waveform[0, 0..-1].to_a)
plt.savefig("mu_law_encoding_functional.png")

# ---

computed = TorchAudio::Functional.compute_deltas(specgram.contiguous, win_length: 3)
puts "Shape of computed deltas: #{computed.shape}"

plt.figure
plt.imshow(computed.log2[0, 0..-1, 0..-1].detach.to_a, cmap: "gray")
plt.savefig("compute_deltas.png")

# ---

gain_waveform = TorchAudio::Functional.gain(waveform, gain_db: 5.0)
puts "Min of gain_waveform: #{gain_waveform.min.item}"
puts "Max of gain_waveform: #{gain_waveform.max.item}"
puts "Mean of gain_waveform: #{gain_waveform.mean.item}"

dither_waveform = TorchAudio::Functional.dither(waveform)
puts "Min of dither_waveform: #{dither_waveform.min.item}"
puts "Max of dither_waveform: #{dither_waveform.max.item}"
puts "Mean of dither_waveform: #{dither_waveform.mean.item}"

# ---

lowpass_waveform = TorchAudio::Functional.lowpass_biquad(waveform, sample_rate, 3000)

puts "Min of lowpass_waveform: #{lowpass_waveform.min.item}"
puts "Max of lowpass_waveform: #{lowpass_waveform.max.item}"
puts "Mean of lowpass_waveform: #{lowpass_waveform.mean.item}"

plt.figure
plt.plot(lowpass_waveform.t.to_a)
plt.savefig("lowpass_biquad.png")

# ---

highpass_waveform = TorchAudio::Functional.highpass_biquad(waveform, sample_rate, 2000)

puts "Min of highpass_waveform: #{highpass_waveform.min.item}"
puts "Max of highpass_waveform: #{highpass_waveform.max.item}"
puts "Mean of highpass_waveform: #{highpass_waveform.mean.item}"

plt.figure
plt.plot(highpass_waveform.t.to_a)
plt.savefig("highpass_biquad.png")
