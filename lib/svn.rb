class Svn

  %w{lib/repository lib/path lib/utils rexml/document}.each{|x| require x}
  include Utils
  include REXML

  attr_accessor :code_lines, :externals

  def initialize
    self.code_lines = {}
    self.externals = {}
  end

  def add_code_line(url)
    svn_info = execute "svn info --xml #{url}"
    repository = get_repository(svn_info)
    path = get_path(svn_info)
    code_lines[repository.to_s] ||= repository
    code_lines[repository.to_s].add_path(path)
    path
  end

  def add_external(url)
    svn_info = execute "svn info --xml #{url}"
    repository = get_repository(svn_info)
    path = get_path(svn_info)
    externals[repository.to_s] ||= repository
    externals[repository.to_s].add_path(path)
    path
  end

  def add_externals(path)
    externals_output = execute "svn propget --xml svn:externals #{path.uri.to_s} -R"
    doc = Document.new(externals_output)
    XPath.each(doc.root, '//properties/target/property') do |node|
      # format of svn property will look like this...
      # /log4php/tags/v2.0/src/main/php log4php /gossamer/trunk/src@16 gossamer /authentication/tags/v1.4/lib authentication
      # we only care about the even entries (which are the svn paths)
      node.text.split(/\s/).each_with_index do |svn_path, i|
        if i.even?
          uri = URI(svn_path)
          uri.scheme ||= path.uri.scheme
          uri.host ||= path.uri.host
          external = add_external(uri.to_s)
          # only look for externals if it doesn't currently have any
          # if it already has externals we can assume this was done
          # in a previous iteration
          # TODO: This was a quick improvement, theres a better way to optimize this
          # Problem is that if an external has no additional externals
          # it will continue to be checked.
          add_externals(external) if external.externals.empty?
          path.externals << external
        end
      end
    end
  end

  def get_repository(svn_info)
    doc = Document.new(svn_info)
    repository_root = XPath.first(doc.root, '//info/entry/repository/root').text
    Repository.new(repository_root)
  end

  def get_path(svn_info)
    doc = Document.new(svn_info)
    uri = XPath.first(doc.root, '//info/entry/url').text
    revision = XPath.first(doc.root, '//info/entry/@revision')
    repository_root = XPath.first(doc.root, '//info/entry/repository/root').text
    Path.new(uri, revision, repository_root)
  end

end
