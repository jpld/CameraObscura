
require 'rake'

QC_EDITOR_PATH = '/Developer/Applications/Quartz Composer.app'

desc 'launch qc editor with composition'
task :run, [:composition_path] do |t, args|
  %x{ open -a '#{QC_EDITOR_PATH}' '#{args.composition_path}' }
end
