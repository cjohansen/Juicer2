namespace :version do
  desc "Update Juicer::VERSION"
  task :constant do
    root = File.join(File.dirname(__FILE__), "..")
    juicer_rb = File.join(root, "lib", "juicer.rb")
    juicer = File.read(juicer_rb)
    version = File.read(File.join(root, "VERSION")).strip

    File.open(juicer_rb, "w") do |f|
      f.puts(juicer.sub(/VERSION = "[^"]+"/, "VERSION = \"#{version}\""))
    end

    puts "Updated Juicer::VERSION to #{version}"
  end
end
