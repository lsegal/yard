class File
  def self.relative_path(from, to)
    from = File.expand_path(from).split('/')
    to = File.expand_path(to).split('/')
    from.length.times do 
      break if from[0] != to[0] 
      from.shift; to.shift
    end
    fname = from.pop
    join *(from.map { '..' } + to)
  end
end