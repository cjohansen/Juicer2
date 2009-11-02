# http://github.com/mynyml/watchr/blob/master/specs.watchr

# --------------------------------------------------
# Convenience Methods
# --------------------------------------------------
def run(cmd)
  puts(cmd)
  system(cmd)
end
 
def run_all_tests
  # see Rakefile for the definition of the test:all task
  system("rake -s test VERBOSE=true")
end
 
# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------
watch('^test.*/.*_test\.rb') { |m| run("ruby -Ilib:test %s" % m[0]) }
watch('^lib/(.*)\.rb') { |m| run("ruby -Ilib:test test/units/%s_test.rb" % m[1]) }
watch('^lib/juicer/(.*)\.rb') { |m| run("ruby -Ilib:test test/units/%s_test.rb" % m[1]) }
watch('^test/test_helper\.rb') { run_all_tests }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }
