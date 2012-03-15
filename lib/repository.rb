class Repository
  require 'lib/path'

  attr_accessor :uri, :paths

  def initialize(uri)
    self.uri = URI(uri)
    self.paths = {}
  end

  def add_path(path)
    path.parent_repository = self
    self.paths[path.to_s] ||= path
  end

  def to_s
    self.uri.to_s
  end

end
