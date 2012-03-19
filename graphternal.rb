#!/usr/bin/env ruby

%w{optparse lib/utils lib/svn lib/repository lib/path rgl/dot}.each{|x| require x}
include RGL::DOT
include Utils

options = {}
options['file'] = 'graph.png'
options['verbose'] = false

opts = OptionParser.new do |opts|
  opts.banner = 'Usage: graphternal.rb (svn_repo)* [options['']'

  opts.on('-f', '--file [PATH]', 'Output file', ' (will use graph.png if not supplied)') do |path|
    options['file'] = path
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options['verbose'] = v
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end

opts.parse!

puts opts if ARGV.empty?

VERBOSE = options['verbose']

svn = Svn.new

# verify that each repo is valid
ARGV.each do |repo|
  code_line = svn.add_code_line repo
  svn.add_externals(code_line)
end

#graph_code_lines(svn).write_to_graphic_file
dot_file = File.new("graph.dot", "w")
dot_file.write(graph_code_lines(svn).to_s)
dot_file.close
extention = File.basename(options['file']).split('.')[1]
%x{dot -T#{extention} graph.dot -o #{options['file']}}
%x{rm graph.dot}
