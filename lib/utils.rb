module Utils

  def execute(cmd)
    puts "Executing: #{cmd}" if VERBOSE
    output = `#{cmd}`
    raise "Error executing, '#{cmd}'\nOutput:\n#{output}" if $?.to_i != 0
    output
  end
end
