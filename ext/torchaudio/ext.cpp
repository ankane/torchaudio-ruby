#include <string>

#include <torchaudio/csrc/sox.h>

#include <rice/rice.hpp>
#include <rice/stl.hpp>

extern "C"
void Init_ext() {
  auto rb_mTorchAudio = Rice::define_module("TorchAudio");

  auto rb_mExt = Rice::define_module_under(rb_mTorchAudio, "Ext")
    .define_singleton_function(
      "read_audio_file",
      [](const std::string& file_name, at::Tensor output, bool ch_first, int64_t nframes, int64_t offset, sox_signalinfo_t* si, sox_encodinginfo_t* ei, const char* ft) {
        return torch::audio::read_audio_file(file_name, output, ch_first, nframes, offset, si, ei, ft);
      })
    .define_singleton_function(
      "write_audio_file",
      [](const std::string& file_name, const at::Tensor& tensor, sox_signalinfo_t* si, sox_encodinginfo_t* ei, const char* file_type) {
        return torch::audio::write_audio_file(file_name, tensor, si, ei, file_type);
      });

  auto rb_cSignalInfo = Rice::define_class_under<sox_signalinfo_t>(rb_mExt, "SignalInfo")
    .define_constructor(Rice::Constructor<sox_signalinfo_t>())
    .define_method("rate", [](sox_signalinfo_t& self) { return self.rate; })
    .define_method("channels", [](sox_signalinfo_t& self) { return self.channels; })
    .define_method("precision", [](sox_signalinfo_t& self) { return self.precision; })
    .define_method("length", [](sox_signalinfo_t& self) { return self.length; })
    .define_method("rate=", [](sox_signalinfo_t& self, sox_rate_t rate) { self.rate = rate; })
    .define_method("channels=", [](sox_signalinfo_t& self, unsigned channels) { self.channels = channels; })
    .define_method("precision=", [](sox_signalinfo_t& self, unsigned precision) { self.precision = precision; })
    .define_method("length=", [](sox_signalinfo_t& self, sox_uint64_t length) { self.length = length; });
}
