#!/usr/bin/env ruby

%w{lib/svn lib/repository lib/path rgl/dot}.each{|x| require x}
include RGL::DOT

VERBOSE = true

def usage
  puts ''
  puts 'Usage: graphternal.rb (svn_repo)*'
  puts ''
  puts ''
end

#def print_path(depth, path)
  #padding = Array.new(depth*2, ' ').join('')
  #puts "#{padding}#{path.uri.to_s}"
  #path.externals.each do |external|
    #print_path(depth+1, external)
  #end
#end

def graph_externals(graph, path)
  path.externals.each do |external|
    graph << Node.new('name' => node_name(path))
    graph << Node.new('name' => node_name(external))
    graph << DirectedEdge.new('from' => node_name(path), 'to' => node_name(external))
    graph = graph_externals(graph, external)
  end
  graph
end

def graph_code_lines(svn)
  graph = Digraph.new
  svn.code_lines.merge(svn.externals).each_value do |repository|
    color = "#%06x" % (rand * 0xffffff)
    repository.paths.each_value do |path|
      if repository.paths.size > 1
        repo_graph = Subgraph.new
        repo_graph << Node.new('name' => repository.to_s, 'color' => color)
        repo_graph << Node.new('name' => node_name(path), 'color' => color)
        repo_graph << DirectedEdge.new('from' => repository.to_s, 'to' => node_name(path), 'color' => color, 'arrowsize' => 0)
        graph << repo_graph
      else
        graph << Node.new('name' => node_name(path))
      end
    end
  end
  svn.code_lines.merge(svn.externals).each_value do |repository|
    repository.paths.each_value do |path|
      graph = graph_externals(graph, path)
    end
  end
  graph
end

def node_name(path)
  if path.parent_repository.paths.size > 1
    return path.to_s
  else
    return path.uri.to_s
  end
end

usage if ARGV.empty?

svn = Svn.new

# verify that each repo is valid
ARGV.each do |repo|
  code_line = svn.add_code_line repo
  svn.add_externals(code_line)
end

#svn.code_lines.each_value do |code_line|
  #code_line.paths.each_value do |path|
    #print_path(0, path)
  #end
#end

#graph_code_lines(svn).write_to_graphic_file
aFile = File.new("graph.dot", "w")
aFile.write(graph_code_lines(svn).to_s)
aFile.close
%x{dot -Tpng graph.dot -o graph.png}
