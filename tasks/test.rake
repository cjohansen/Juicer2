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
