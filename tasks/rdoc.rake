begin
  begin
    require 'hanna/rdoctask'
  rescue LoadError
    require 'rake/rdoctask'
    puts "Missing the hanna gem, using default RDoc theme"
  end

  Rake::RDocTask.new do |rdoc|
    if File.exist?('VERSION')
      version = File.read('VERSION')
    else
      version = ""
    end

    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "Juicer #{version}"
    rdoc.rdoc_files.include('README*')
    rdoc.rdoc_files.include('lib/juicer.rb')
    rdoc.rdoc_files.include('lib/juicer/**/*.rb')
    # rdoc.options += ['-f', 'darkfish']
  end
rescue LoadError => err
end
