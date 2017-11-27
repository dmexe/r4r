require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

require 'rake/extensiontask'
spec = Gem::Specification.load('r4r.gemspec')

Rake::ExtensionTask.new do |ext|
  ext.name = 'ring_bits_ext'
  ext.ext_dir = 'ext/r4r/ring_bits'
  ext.lib_dir = 'lib/r4r'
  ext.gem_spec = spec
end

require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_files.include("README.rdoc", "lib/**/*.rb", "ext/**/*.c")
  rdoc.options << "--all"
end
