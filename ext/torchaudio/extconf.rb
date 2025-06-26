require "mkmf-rice"

$CXXFLAGS += " -std=c++17 $(optflags)"

ext = File.expand_path(".", __dir__)
csrc = File.expand_path("csrc", __dir__)

$srcs = Dir["{#{ext},#{csrc}}/*.cpp"]
$INCFLAGS << " -I#{File.expand_path("..", __dir__)}"
$VPATH << csrc

#
# keep rest synced with Torch
#

# change to 0 for Linux pre-cxx11 ABI version
$CXXFLAGS += " -D_GLIBCXX_USE_CXX11_ABI=1"

apple_clang = RbConfig::CONFIG["CC_VERSION_MESSAGE"] =~ /apple clang/i

if apple_clang
  # silence torch warnings
  $CXXFLAGS += " -Wno-deprecated-declarations"
else
  # silence rice warnings
  $CXXFLAGS += " -Wno-noexcept-type"

  # silence torch warnings
  $CXXFLAGS += " -Wno-duplicated-cond -Wno-suggest-attribute=noreturn"
end

paths = [
  "/usr/local",
  "/opt/homebrew",
  "/home/linuxbrew/.linuxbrew"
]

inc, lib = dir_config("torch")
inc ||= paths.map { |v| "#{v}/include" }.find { |v| Dir.exist?("#{v}/torch") }
lib ||= paths.map { |v| "#{v}/lib" }.find { |v| Dir["#{v}/*torch_cpu*"].any? }

unless inc && lib
  abort "LibTorch not found"
end

cuda_inc, cuda_lib = dir_config("cuda")
cuda_inc ||= "/usr/local/cuda/include"
cuda_lib ||= "/usr/local/cuda/lib64"

$LDFLAGS += " -L#{lib}" if Dir.exist?(lib)
abort "LibTorch not found" unless have_library("torch")

have_library("mkldnn")
have_library("nnpack")

with_cuda = false
if Dir["#{lib}/*torch_cuda*"].any?
  $LDFLAGS += " -L#{cuda_lib}" if Dir.exist?(cuda_lib)
  with_cuda = have_library("cuda") && have_library("cudnn")
end

$INCFLAGS += " -I#{inc}"
$INCFLAGS += " -I#{inc}/torch/csrc/api/include"

$LDFLAGS += " -Wl,-rpath,#{lib}"
$LDFLAGS += ":#{cuda_lib}/stubs:#{cuda_lib}" if with_cuda

# https://github.com/pytorch/pytorch/blob/v1.5.0/torch/utils/cpp_extension.py#L1232-L1238
$LDFLAGS += " -lc10 -ltorch_cpu -ltorch"
if with_cuda
  $LDFLAGS += " -lcuda -lnvrtc -lnvToolsExt -lcudart -lc10_cuda -ltorch_cuda -lcufft -lcurand -lcublas -lcudnn"
  # TODO figure out why this is needed
  $LDFLAGS += " -Wl,--no-as-needed,#{lib}/libtorch.so"
end

sox_inc, sox_lib = dir_config("sox")
sox_inc ||= paths.map { |v| "#{v}/include" }.find { |v| File.exist?("#{v}/sox.h") }
sox_lib ||= paths.map { |v| "#{v}/lib" }.find { |v| Dir["#{v}/*libsox*"].any? }

$INCFLAGS += " -I#{sox_inc}" if sox_inc
$LDFLAGS += " -L#{sox_lib}" if sox_lib
abort "SoX not found" unless have_library("sox")

# create makefile
create_makefile("torchaudio/ext")
