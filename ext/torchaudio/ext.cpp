#include <torchaudio/csrc/sox.h>

#include <rice/Module.hpp>

using namespace Rice;

template<>
inline
sox_signalinfo_t* from_ruby<sox_signalinfo_t*>(Object x)
{
  if (x.is_nil()) {
    return nullptr;
  }
  throw std::runtime_error("Unsupported signalinfo");
}

template<>
inline
sox_encodinginfo_t* from_ruby<sox_encodinginfo_t*>(Object x)
{
  if (x.is_nil()) {
    return nullptr;
  }
  throw std::runtime_error("Unsupported encodinginfo");
}

extern "C"
void Init_ext()
{
  Module rb_mTorchAudio = define_module("TorchAudio");
  Module rb_mNN = define_module_under(rb_mTorchAudio, "Ext")
    .define_singleton_method("read_audio_file", &torch::audio::read_audio_file);
}
