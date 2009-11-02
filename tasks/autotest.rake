namespace :test do
  namespace :units do
    desc "run related unit tests everytime sources or unit test files change"
    task :auto do
      `watchr tasks/test_units.watchr`
    end
  end
end
