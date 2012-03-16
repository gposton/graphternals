module Utils

  def execute(cmd)
    puts "Executing: #{cmd}" if VERBOSE
    output = `#{cmd}`
    raise "Error executing, '#{cmd}'\nOutput:\n#{output}" if $?.to_i != 0
    output
  end

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
  svn.code_lines.each_value do |repository|
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

end
