#include <torchaudio/csrc/sox.h>

#include <rice/Constructor.hpp>
#include <rice/Module.hpp>

using namespace Rice;

class SignalInfo {
  sox_signalinfo_t* value = nullptr;
  public:
    SignalInfo(Object o) {
      if (!o.is_nil()) {
        value = from_ruby<sox_signalinfo_t*>(o);
      }
    }
    operator sox_signalinfo_t*() {
      return value;
    }
};

template<>
inline
SignalInfo from_ruby<SignalInfo>(Object x)
{
  return SignalInfo(x);
}

class EncodingInfo {
  sox_encodinginfo_t* value = nullptr;
  public:
    EncodingInfo(Object o) {
      if (!o.is_nil()) {
        value = from_ruby<sox_encodinginfo_t*>(o);
      }
    }
    operator sox_encodinginfo_t*() {
      return value;
    }
};

template<>
inline
EncodingInfo from_ruby<EncodingInfo>(Object x)
{
  return EncodingInfo(x);
}

extern "C"
void Init_ext()
{
  Module rb_mTorchAudio = define_module("TorchAudio");

  Module rb_mExt = define_module_under(rb_mTorchAudio, "Ext")
    .define_singleton_method(
      "read_audio_file",
      *[](const std::string& file_name, at::Tensor output, bool ch_first, int64_t nframes, int64_t offset, SignalInfo si, EncodingInfo ei, const char* ft) {
        return torch::audio::read_audio_file(file_name, output, ch_first, nframes, offset, si, ei, ft);
      })
    .define_singleton_method(
      "write_audio_file",
      *[](const std::string& file_name, const at::Tensor& tensor, SignalInfo si, EncodingInfo ei, const char* file_type) {
        return torch::audio::write_audio_file(file_name, tensor, si, ei, file_type);
      });

  Class rb_cSignalInfo = define_class_under<sox_signalinfo_t>(rb_mExt, "SignalInfo")
    .define_constructor(Constructor<sox_signalinfo_t>())
    .define_method("rate", *[](sox_signalinfo_t self) { return self.rate; })
    .define_method("channels", *[](sox_signalinfo_t self) { return self.channels; })
    .define_method("precision", *[](sox_signalinfo_t self) { return self.precision; })
    .define_method("length", *[](sox_signalinfo_t self) { return self.length; })
    .define_method("rate=", *[](sox_signalinfo_t self, sox_rate_t rate) { self.rate = rate; })
    .define_method("channels=", *[](sox_signalinfo_t self, unsigned channels) { self.channels = channels; })
    .define_method("precision=", *[](sox_signalinfo_t self, unsigned precision) { self.precision = precision; })
    .define_method("length=", *[](sox_signalinfo_t self, sox_uint64_t length) { self.length = length; });
}
