require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"

task default: :test
Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

Rake::ExtensionTask.new("torchaudio") do |ext|
  ext.name = "ext"
  ext.lib_dir = "lib/torchaudio"
end

task :remove_ext do
  Dir["lib/torchaudio/ext.bundle"].each do |path|
    File.unlink(path) if File.exist?(path)
  end
end

Rake::Task["build"].enhance [:remove_ext]
