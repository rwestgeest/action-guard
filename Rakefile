require "bundler"
Bundler.setup
Bundler::GemHelper.install_tasks

require "rake"
require "yaml"

require "rake/rdoctask"
require "rspec/core/rake_task"
require "action_guard/version"

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
  t.verbose = false
end


namespace :rcov do
  task :cleanup do
    rm_rf 'coverage.data'
  end

  RSpec::Core::RakeTask.new :spec do |t|
    t.rcov = true
    t.rcov_opts =  %[-Ilib -Ispec --exclude "gems/*,features"]
    t.rcov_opts << %[--no-html --aggregate coverage.data]
  end

end

task :rcov => ["rcov:cleanup", "rcov:spec"]

task :default => [:spec]

task :clobber do
  rm_rf 'pkg'
  rm_rf 'tmp'
  rm_rf 'coverage'
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "actionguard #{ActionGuard::Version::STRING}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

