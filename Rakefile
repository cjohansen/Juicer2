require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "juicer"
    gem.summary = "CSS and JavaScript dependency management, concatenation, minification and utility belt"
    gem.description = <<-EOF
      Juicer is a command line tool for building frontend projects for high
      performance. Juicer is a utility belt providing dependency management,
      file concatenation, minification and supporting tools such as URL management
      for CSS (cache busters, sharding domains) and embedding graphics with
      data-uri's.
      EOF
    gem.email = "christian@cjohansen.no"
    gem.homepage = "http://cjohansen.no/juicer"
    gem.authors = ["Christian Johansen"]
    gem.rubyforge_project = "juicer"
    gem.add_development_dependency "shoulda"
    gem.add_development_dependency "mocha"
    gem.add_development_dependency "fakefs"
    gem.add_development_dependency "jeweler"
    #gem.add_dependency "cmdparse"
    #gem.add_dependency "nokogiri"
    #gem.add_dependency "rubyzip"
    #gem.add_dependency "febeling-rubyzip"
    gem.executables = ["juicer"]
    gem.post_install_message = <<-MSG
Juicer does not ship with third party libraries. You probably want to install
Yui Compressor and JsLint now:

juicer install yui_compressor
juicer install jslint

Happy juicing!
    MSG
    gem.files = FileList["[A-Z]*", "{bin,generators,lib,test}/**/*"]
  end

  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
rescue LoadError => err
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
  puts err.message
end

begin
  require 'rake/testtask'
  
  Rake::TestTask.new("test:units") do |test|
    test.libs << 'test'
    test.pattern = 'test/units/**/*_test.rb'
    test.verbose = true
  end

  Rake::TestTask.new("test:integration") do |test|
    test.libs << 'test'
    test.pattern = 'test/integration/**/*_test.rb'
    test.verbose = true
  end

  task :test => ["test:units", "test:integration"]
  task :default => "test:units"
rescue LoadError => err
end

begin
  require 'rake/rdoctask'

  Rake::RDocTask.new do |rdoc|
    if File.exist?('VERSION')
      version = File.read('VERSION')
    else
      version = ""
    end

    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "jstdutil #{version}"
    rdoc.rdoc_files.include('README*')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
rescue LoadError => err
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end
