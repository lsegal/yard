class File
  RELATIVE_PARENTDIR = '..'
  
  # Turns a path +to+ into a relative path from starting
  # point +from+. The argument +from+ is assumed to be
  # a filename. To treat it as a directory, make sure it
  # ends in {File::SEPARATOR} ('/' on UNIX filesystems).
  # 
  # @param [String] from the starting filename 
  #   (or directory with +from_isdir+ set to +true+).
  # 
  # @param [String] to the final path that should be made relative.
  # 
  # @return [String] the relative path from +from+ to +to+.
  # 
  def self.relative_path(from, to)
    from = expand_path(from).split(SEPARATOR)
    to = expand_path(to).split(SEPARATOR)
    from.length.times do 
      break if from[0] != to[0] 
      from.shift; to.shift
    end
    fname = from.pop
    join *(from.map { RELATIVE_PARENTDIR } + to)
  end
end