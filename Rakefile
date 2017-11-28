require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(:bench) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/benchmark_*.rb"]
end

task :default => :test

require 'rake/extensiontask'
spec = Gem::Specification.load('r4r.gemspec')

Dir.glob("ext/r4r/*").each do |dirname|
  extname = File.basename dirname

  Rake::ExtensionTask.new do |ext|
    ext.name = extname
    ext.ext_dir = dirname
    ext.lib_dir = 'lib/r4r'
    ext.gem_spec = spec
  end

end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'ext/**/*.c']
  t.options = ['--any', '--extra', '--opts']
  t.stats_options = ['--list-undoc']
end
